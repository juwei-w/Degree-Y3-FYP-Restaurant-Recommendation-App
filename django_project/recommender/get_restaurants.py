from django.shortcuts import render
import json
import googlemaps
import re
from fuzzywuzzy import process
from dotenv import load_dotenv
import sys # For stderr printing
import os

from django.http import JsonResponse, HttpRequest
from django.views.decorators.http import require_GET
from .constants import CATEGORY_DICT, EXCLUDED_TYPES # Import from constants

load_dotenv()  # take environment variables from .env.

# --- Your existing helper functions ---
# It's best to place these directly in this file or import them from another .py file
# within your 'recommender' app (e.g., recommender/utils.py)

# Google Maps API Key - IMPORTANT: Manage this securely, e.g., environment variable or Django settings
GOOGLE_MAPS_API_KEY = os.getenv('GOOGLE_MAPS_API_KEY')
gmaps = googlemaps.Client(key=GOOGLE_MAPS_API_KEY)

def save_to_json(data, base_filename="map_output", folder_name="../assets/restaurant_data"):
    if not os.path.exists(folder_name):
        os.makedirs(folder_name)
    
    n = 1
    while os.path.exists(os.path.join(folder_name, f"{base_filename}_{n}.json")):
        n += 1
    filename = os.path.join(folder_name, f"{base_filename}_{n}.json")

    with open(filename, 'w', encoding='utf-8') as file:
        json.dump(data, file, indent=4, ensure_ascii=False)
    return filename

def get_keyword_category(details, category_dict, search_keyword):
    extracted_categories = set()
    if search_keyword:
        for category, keywords in category_dict.items():
            if search_keyword.lower() in keywords:
                extracted_categories.add(category)
    name = details.get("name", "").lower()
    for category, keywords in category_dict.items():
        if any(keyword in name for keyword in keywords):
            extracted_categories.add(category)
    reviews = details.get("reviews", [])
    for review in reviews:
        text = review.get("text", "").lower()
        for category, keywords in category_dict.items():
            if any(keyword in text for keyword in keywords):
                extracted_categories.add(category)
    # ... (rest of your get_keyword_category function) ...
    types = details.get("types", [])
    for place_type in types:
        place_type_lower = place_type.lower()
        for category, keywords in category_dict.items():
            if any(keyword in place_type_lower for keyword in keywords):
                extracted_categories.add(category)
    vicinity = details.get("vicinity", "").lower()
    description = details.get("description", "").lower()
    for category, keywords in category_dict.items():
        if any(keyword in vicinity for keyword in keywords):
            extracted_categories.add(category)
        if any(keyword in description for keyword in keywords):
            extracted_categories.add(category)
    return list(extracted_categories)

def get_fuzzy_category(input_term):
    # Ensure CATEGORY_DICT is accessible here
    best_match, score = process.extractOne(input_term, list(CATEGORY_DICT.keys()))
    if score >= 80:
        return best_match, score
    else:
        return None, score

def get_final_categories(details, keyword, category_dict):
    # Ensure get_keyword_category and get_fuzzy_category are accessible
    exact_categories = get_keyword_category(details, category_dict, keyword)
    fuzzy_categories = []
    # Consolidate terms to iterate over
    terms_to_check = []
    if details.get('name'):
        terms_to_check.extend(details.get('name', '').split())
    if details.get('vicinity'):
        terms_to_check.extend(details.get('vicinity', '').split())
    for r in details.get('reviews', []):
        if r.get('text'):
            terms_to_check.extend(r.get('text', '').split())
    terms_to_check.extend(details.get('types', []))

    for term in terms_to_check:
        if isinstance(term, str) and term.strip(): # Ensure term is a non-empty string
            # Check if the term contains at least one alphanumeric character
            # This avoids sending purely symbolic "words" to fuzzy matching
            if any(char.isalnum() for char in term): # <<< MODIFICATION HERE
                matched_category, score = get_fuzzy_category(term)
                if matched_category:
                    fuzzy_categories.append((matched_category, score))
            # else:
                # Optional: print(f"Skipping term with no alphanumeric characters: '{term}'", file=sys.stderr)

    final_categories = set(exact_categories)
    for category, score in fuzzy_categories:
        if score >= 80:
            final_categories.add(category)
    return list(final_categories)

def clean_text(text):
    if text:
        text = text.replace("–", "-")
        text = text.replace("—", "-")
        text = re.sub(r'[^\x20-\x7E\n\r\t]', '', text) # Allow common whitespace
    return text

def get_nearby_recommend_restaurants_logic(latitude, longitude, radius, keyword=""):
    """
    Fetches nearby restaurants using Google Maps API and enriches the data.
    Now accepts an optional keyword for searching.
    """
    all_restaurants = []
    
    # Correctly format the location as a tuple for the Google Maps API call
    location = (latitude, longitude)

    try:
        # Prepare parameters for the API call
        api_params = {
            'location': location,
            'radius': radius,
            'type': 'restaurant'
        }
        # Only add the keyword to the search if it's provided and not empty
        if keyword:
            api_params['keyword'] = keyword

        # Initial search for restaurants using the prepared parameters
        places_result = gmaps.places_nearby(**api_params)
        
        results = places_result.get('results', [])

        # Google recommends a short delay before using next_page_token
        # It's better to handle this more robustly in a production app (e.g., with retries)
        while places_result.get('next_page_token'):
            import time
            time.sleep(2) 
            places_result = gmaps.places_nearby(page_token=places_result['next_page_token'])
            results.extend(places_result.get('results', []))
    except Exception as e:
        print(f"Error during Google Maps API call (places_nearby): {e}", file=sys.stderr)
        # Depending on the error, you might want to return an empty list or raise it
        return []


    print(f"Total places found by Google API: {len(results)} for keyword: '{keyword}'", file=sys.stderr)
    
    for place in results:
        place_types = place.get('types', [])
        business_status = place.get('business_status', '').upper()
        # Ensure EXCLUDED_TYPES is accessible
        if not any(excluded_type in place_types for excluded_type in EXCLUDED_TYPES) and business_status == 'OPERATIONAL':
            all_restaurants.append(place)
    
    restaurant_data = []
    for place in all_restaurants:
        name = place.get('name', 'N/A')
        place_id = place.get('place_id')

        if not place_id:
            print(f"Skipping '{name}' due to missing place_id.", file=sys.stderr)
            continue
        
        details_response = {}
        try:
            details_response = gmaps.place(place_id=place_id, fields=[
                "name", "place_id", "rating", "user_ratings_total", "price_level",
                "formatted_address", "vicinity", "geometry", "website", "formatted_phone_number",
                "opening_hours", "reviews", "photo", "url", "editorial_summary", # Changed to 'photo' (singular)
                "type", "delivery", "takeout", "business_status"  # Changed to 'type' (singular)
            ])
        except Exception as e:
            print(f"Error during Google Maps API call (place details for {place_id}): {e}", file=sys.stderr)
            continue # Skip this place if details can't be fetched

        details = details_response.get('result', {})
        
        if not details:
            print(f"Skipping '{name}' (Place ID: {place_id}) due to empty details response. API Response: {details_response}", file=sys.stderr)
            continue

        rating = details.get('rating', None)
        if rating is None or rating == 'N/A': # Check for None explicitly
            print(f"Excluding '{name}' (Place ID: {place_id}) due to missing or N/A rating (Rating: {rating}).", file=sys.stderr)
            continue

        # Consolidate address fetching
        address = details.get('formatted_address', place.get('vicinity', 'N/A'))
        phone_number = details.get('formatted_phone_number', 'N/A')
        website = details.get('website', 'N/A')
        user_ratings_total = details.get('user_ratings_total', 0) # Default to 0 if N/A
        price_level = details.get('price_level', 'N/A') # Or a sensible default like 0 or -1
        business_status_detail = details.get('business_status', 'OPERATIONAL') # Default to OPERATIONAL
        types_detail = details.get('types', [])

        geometry = details.get('geometry', {})
        location_detail = geometry.get('location', {})
        latitude = location_detail.get('lat', 'N/A')
        longitude = location_detail.get('lng', 'N/A')

        opening_hours_data = details.get('opening_hours', {})
        opening_status = opening_hours_data.get('open_now', False) # Default to False
        opening_hours_text = opening_hours_data.get('weekday_text', [])
        cleaned_opening_hours = [clean_text(hour) for hour in opening_hours_text]

        reviews_data = details.get('reviews', [])
        formatted_reviews = []
        for r_idx, r in enumerate(reviews_data[:3]): # Max 3 reviews
            formatted_reviews.append({
                "author": clean_text(r.get('author_name', f"Author {r_idx+1}")),
                "rating": r.get('rating', 0),
                "text": clean_text(r.get('text', "")),
                "relative_time": r.get('relative_time_description', "")
            })

        photos_data = details.get('photos', [])
        photo_references = [p.get('photo_reference') for p in photos_data[:3] if p.get('photo_reference')] # Max 3, ensure ref exists

        url = details.get('url', 'N/A')
        editorial_summary_data = details.get('editorial_summary', {})
        editorial_summary = clean_text(editorial_summary_data.get('overview', 'N/A'))

        delivery_val = details.get('delivery') # Check boolean directly
        takeout_val = details.get('takeout')

        # Ensure CATEGORY_DICT is accessible
        categories = get_final_categories(details, keyword, CATEGORY_DICT)

        restaurant_data.append({
            'place_id': place_id, 'name': clean_text(name), 'categories': categories,
            'address': clean_text(address), 'latitude': latitude, 'longitude': longitude,
            'rating': rating, 'user_ratings_total': user_ratings_total,
            'price_level': price_level, 'editorial_summary': editorial_summary,
            'reviews': formatted_reviews, 'photos': photo_references, 'url': url,
            'phone_number': phone_number, 'website': website,
            'opening_hours': cleaned_opening_hours, 'opening_status': opening_status,
            'business_status': business_status_detail, 'types': types_detail,
            'delivery': delivery_val if isinstance(delivery_val, bool) else 'N/A', # Handle boolean or N/A
            'takeout': takeout_val if isinstance(takeout_val, bool) else 'N/A'  # Handle boolean or N/A
        })
    return restaurant_data
# --- End of your helper functions ---

@require_GET # Ensures this view only accepts GET requests
def get_restaurants_api(request: HttpRequest):
    try:
        # Correctly parse 'lat' and 'lon' to match the Flutter app's request
        lat_str = request.GET.get('lat')
        lon_str = request.GET.get('lon')
        radius_str = request.GET.get('radius')
        keyword_str = request.GET.get('keyword', "") # Optional

        if not all([lat_str, lon_str, radius_str]):
            return JsonResponse({"error": "Missing required parameters: lat, lon, radius"}, status=400)

        lat = float(lat_str)
        lon = float(lon_str)
        radius = int(radius_str)
        
        print(f"Django API: Received request for Lat: {lat}, Lon: {lon}, Radius: {radius}, Keyword: '{keyword_str}'", file=sys.stderr)

        # Call your core logic function with the correct parameters
        recommended_restaurants = get_nearby_recommend_restaurants_logic(
            latitude=lat, 
            longitude=lon,
            radius=radius, 
            keyword=keyword_str
        )

        # If you still want to save it to a file as well:
        filename = save_to_json(recommended_restaurants, base_filename="django_data")
        print(f"Data also saved to {filename}", file=sys.stderr) # Debug to stderr
        
        print(f"Django API: Found {len(recommended_restaurants)} restaurants.", file=sys.stderr)
        return JsonResponse(recommended_restaurants, safe=False) # safe=False because it's a list
    

    except ValueError:
        return JsonResponse({"error": "Invalid parameter types. Latitude/Longitude must be float, Radius must be integer."}, status=400)
    except Exception as e:
        print(f"Django API Error: {e}", file=sys.stderr)
        return JsonResponse({"error": f"An internal server error occurred: {str(e)}"}, status=500)
