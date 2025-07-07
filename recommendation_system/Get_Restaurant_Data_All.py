import os
import json
import googlemaps
import re
from fuzzywuzzy import process
from dotenv import load_dotenv
import sys # Required for command-line arguments and stderr

load_dotenv()  # Loads variables from .env into environment

# Google Maps API Key
# Ensure this key is active and has Places API enabled.
# api_key = "YOUR_GOOGLE_MAPS_API_KEY" # Replace with your actual key
# api_key = "AIzaSyDXhbakEqfh8Y2UWc3-FPt1eXlFJfND7J0" # Example from your file
# api_key = "AIzaSyBQw75wYvUnX7XhERvVL_hmLsucaxL9s3I" # Example from your file
GOOGLE_MAPS_API_KEY = os.getenv('GOOGLE_MAPS_API_KEY')
gmaps = googlemaps.Client(key=GOOGLE_MAPS_API_KEY)

# Define a dictionary of categories with keywords
EXCLUDED_TYPES = ['gas_station', 'lodging', 'convenience_store', 'car_repair', 'car_wash', 'parking']

CATEGORY_DICT = {
    "halal": ["halal", "muslim-friendly", "muslim", "halal-certified", "shariah-compliant"],
    "vegetarian": ["vege", "vegetarian", "vegan", "vegetarian-friendly", "vegetarian option", "meat-free"],
    "vegan": ["vegan", "plant-based", "vegan-friendly", "cruelty-free", "dairy-free"],
    "beef-free": ["beef-free", "no beef", "without beef", "beefless"],
    "chinese": ["chinese", "szechuan", "dim sum", "cantonese", "dumplings", "fried rice", "chicken rice", "charsiew", "horfun", "kopitiam", "mala"],
    "malay": ["nasi lemak", "satay", "rendang", "keropok", "nasi kerabu", "roti jala"],
    "indian": ["indian restaurant", "khorma", "masala", "naan", "briyani", "tandoori", "nasi kandar"],
    "korean": ["korean", "kimchi", "bibimbap", "bulgogi", "tteokbokki", "jajangmyeon", "samgyeopsal"],
    "japanese": ["japan", "japanese", "sushi", "wasabi", "udon", "miso", "shabu-shabu", "bento", "sukiya", "takoyaki", "onigiri"],
    "thai": ["thai", "pad thai", "green curry", "tom yum", "som tam", "satay", "red curry"],
    "western": ["western", "steak", "burger", "pasta", "pizza", "fish n' chips"],
    "eastern": ["eastern cuisine", "middle eastern", "falafel", "shawarma", "hummus", "kebab"],
    "cafe": ["café", "coffee shop", "espresso", "latte", "pastry", "bakery", "barista"],
    "bar": ["bar", "pub", "tavern", "brewery", "cocktail"],
    "buffet": ["buffet", "all-you-can-eat", "unlimited food", "buffet-style"],
    "fast-food": ["fast food", "drive-thru", "mcdonald's", "kfc", "burger king", "a&w", "taco bell", "subway", "pizza hut", "domino's", "texas chicken"],
}

def save_to_json(data, base_filename="map_output", folder_name="Google_Map_Output_json"):
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
    search_keyword_lower = search_keyword.lower()

    for category, keywords in category_dict.items():
        if search_keyword_lower in keywords: # Check if the search keyword itself is a category keyword
            extracted_categories.add(category)
        elif search_keyword_lower == category: # Check if search keyword matches a category name
             extracted_categories.add(category)


    name = details.get("name", "").lower()
    for category, keywords in category_dict.items():
        if any(keyword in name for keyword in keywords):
            extracted_categories.add(category)

    reviews_text = " ".join([review.get("text", "").lower() for review in details.get("reviews", [])])
    for category, keywords in category_dict.items():
        if any(keyword in reviews_text for keyword in keywords):
            extracted_categories.add(category)

    qna_text = ""
    for qna in details.get("faq", []):
        qna_text += qna.get("question", "").lower() + " " + qna.get("answer", "").lower() + " "
    for category, keywords in category_dict.items():
        if any(keyword in qna_text for keyword in keywords):
            extracted_categories.add(category)

    types_text = " ".join(details.get("types", [])).lower()
    for category, keywords in category_dict.items():
        if any(keyword in types_text for keyword in keywords):
            extracted_categories.add(category)

    description_text = details.get("vicinity", "").lower() + " " + details.get("description", "").lower()
    for category, keywords in category_dict.items():
        if any(keyword in description_text for keyword in keywords):
            extracted_categories.add(category)
            
    return list(extracted_categories)

def get_fuzzy_category(input_term):
    # This function seems unused in the current get_final_categories logic,
    # but kept for completeness if you intend to use it.
    # Ensure CATEGORY_DICT.keys() is not empty.
    if not CATEGORY_DICT:
        return None, 0
    best_match, score = process.extractOne(input_term, list(CATEGORY_DICT.keys()))
    if score >= 80:
        return best_match, score
    else:
        return None, score
    
def get_final_categories(details, keyword, category_dict):
    # This function was complex and potentially redundant with get_keyword_category.
    # Simplified to primarily use get_keyword_category.
    # If more sophisticated fuzzy matching is needed, it can be re-integrated.
    return get_keyword_category(details, category_dict, keyword)


def clean_text(text):
    if text:
        text = text.replace("–", "-")
        text = text.replace("—", "-")
        text = re.sub(r'[^\x20-\x7E]', '', text)
    return text

def get_nearby_recommend_restaurants(latitude, longitude, user_radius=None, keyword=""):
    location_tuple = (latitude, longitude)
    radius = user_radius if user_radius is not None else 5000 # Ensure user_radius can be 0 if intended
    
    all_places = []
    nearby_restaurants_filtered = [] # Renamed to avoid confusion
    
    try:
        response = gmaps.places_nearby(location=location_tuple, radius=radius, keyword=keyword, type='restaurant')
        all_places.extend(response.get('results', []))

        while 'next_page_token' in response:
            import time
            time.sleep(2) 
            response = gmaps.places_nearby(page_token=response['next_page_token'])
            all_places.extend(response.get('results', []))
    except Exception as e:
        print(f"Error during Google Maps API call (places_nearby): {e}", file=sys.stderr)
        # Output an empty JSON array on error to ensure Flutter receives valid JSON
        print(json.dumps([], indent=4, ensure_ascii=False))
        sys.exit(1) # Exit if API call fails critically


    print(f"Total places found before filtering: {len(all_places)} for keyword '{keyword}'", file=sys.stderr)
    
    for place in all_places:
        place_types = place.get('types', [])
        business_status = place.get('business_status', '').upper()
        
        # Debug print for each place
        # print(f"Checking place: {place.get('name')}, Types: {place_types}, Status: {business_status}", file=sys.stderr)

        if not any(excluded_type in place_types for excluded_type in EXCLUDED_TYPES) and business_status == 'OPERATIONAL':
            nearby_restaurants_filtered.append(place)
    
    print(f"Total operational restaurants after type filtering: {len(nearby_restaurants_filtered)}", file=sys.stderr)

    restaurant_data = []
    for place in nearby_restaurants_filtered:
        name = place.get('name', 'N/A')
        place_id = place.get('place_id')

        if not place_id:
            print(f"Skipping '{name}' due to missing place_id.", file=sys.stderr)
            continue
        
        try:
            details = gmaps.place(place_id=place_id, fields=[
                "name", "place_id", "rating", "vicinity", "formatted_phone_number", 
                "website", "user_ratings_total", "price_level", "business_status", 
                "types", "geometry", "opening_hours", "reviews", "photos", "url", 
                "editorial_summary", "delivery", "takeout"
            ]).get('result', {})
        except Exception as e:
            print(f"Error fetching details for place_id {place_id} ({name}): {e}", file=sys.stderr)
            continue # Skip this restaurant if details can't be fetched


        rating = details.get('rating', None)
        if rating is None: # Allow 0 ratings, but skip if no rating field at all
            print(f"Excluding '{name}' (Place ID: {place_id}) due to missing rating field.", file=sys.stderr)
            continue

        categories = get_final_categories(details, keyword, CATEGORY_DICT)
        # If keyword is a category and no other categories found, ensure keyword category is present
        if keyword.lower() in CATEGORY_DICT and not categories:
             categories.append(keyword.lower())
        elif keyword.lower() in CATEGORY_DICT and keyword.lower() not in categories:
             categories.append(keyword.lower())


        restaurant_data.append({
            'place_id': place_id,
            'name': name,
            'categories': categories,
            'address': details.get('vicinity', 'N/A'),
            'latitude': details.get('geometry', {}).get('location', {}).get('lat', 'N/A'),
            'longitude': details.get('geometry', {}).get('location', {}).get('lng', 'N/A'),
            'rating': rating, # Already checked for None
            'user_ratings_total': details.get('user_ratings_total', 'N/A'),
            'price_level': details.get('price_level', 'N/A'),
            'editorial_summary': details.get('editorial_summary', {}).get('overview', 'N/A'),
            'reviews': [{
                "author": r.get('author_name'), "rating": r.get('rating'),
                "text": r.get('text'), "relative_time": r.get('relative_time_description')
            } for r in details.get('reviews', [])[:3]],
            'photos': [p.get('photo_reference') for p in details.get('photos', [])[:3]],
            'url': details.get('url', 'N/A'),
            'phone_number': details.get('formatted_phone_number', 'N/A'),
            'website': details.get('website', 'N/A'),
            'opening_hours': [clean_text(hour) for hour in details.get('opening_hours', {}).get('weekday_text', [])],
            'opening_status': details.get('opening_hours', {}).get('open_now', 'N/A'),
            'business_status': details.get('business_status', 'N/A'),
            'types': details.get('types', []),
            'delivery': details.get('delivery', 'N/A'), # Might be boolean or dict
            'takeout': details.get('takeout', 'N/A')  # Might be boolean or dict
        })

    # Save to JSON file (optional, for debugging or logging)
    # filename = save_to_json(restaurant_data, base_filename=f"restaurants_{latitude}_{longitude}_{radius}")
    # print(f"Data for {len(restaurant_data)} restaurants saved to {filename}", file=sys.stderr)
    
    # Print the final JSON data to stdout for Flutter
    print(json.dumps(restaurant_data, indent=4, ensure_ascii=False))
    # The return below is for potential Python-internal use, not for Flutter directly
    return restaurant_data

if __name__ == "__main__":
    if len(sys.argv) >= 4:
        try:
            lat = float(sys.argv[1])
            lon = float(sys.argv[2])
            radius = int(sys.argv[3])
            # keyword = sys.argv[4] if len(sys.argv) > 4 else "" # Optional keyword
            
            current_location = (lat, lon)
            # print(f"Fetching restaurants for Lat: {lat}, Lon: {lon}, Radius: {radius}, Keyword: '{keyword}'", file=sys.stderr) # Debug to stderr
            
            # Pass the keyword if you decide to use it
            # recommended_restaurants = get_nearby_recommend_restaurants(current_location, user_radius=radius, keyword=keyword)
            recommended_restaurants = get_nearby_recommend_restaurants(current_location, user_radius=radius)


            # Instead of saving to a file (or in addition to), print JSON to stdout
            print(json.dumps(recommended_restaurants, indent=4, ensure_ascii=False))

            # If you still want to save it to a file as well:
            # filename = save_to_json(recommended_restaurants, base_filename="flutter_run_output")
            # print(f"Data also saved to {filename}", file=sys.stderr) # Debug to stderr

        except ValueError:
            print("Error: Latitude, Longitude must be numbers and Radius an integer.", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"An error occurred: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print("Usage: python Get_Restaurant_Data_All.py <latitude> <longitude> <radius_in_meters> [keyword]", file=sys.stderr)
        # Example for direct script run (optional)
        # print("Running with default example location as not enough arguments were provided.", file=sys.stderr)
        # location = (3.077948980104835, 101.58644637429283)  # Example: SS15
        # user_radius = 500
        # recommended_restaurants = get_nearby_recommend_restaurants(location, user_radius)
        # print(json.dumps(recommended_restaurants, indent=4, ensure_ascii=False))
        sys.exit(1)

