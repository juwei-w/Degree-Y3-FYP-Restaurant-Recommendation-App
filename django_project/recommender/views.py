from django.http import JsonResponse, HttpRequest
from django.views.decorators.http import require_GET
from django.views.decorators.csrf import csrf_exempt
import json
from .get_restaurants import get_nearby_recommend_restaurants_logic
from .content_based import get_content_based_recommendations
from .collaborative import get_collaborative_filtering_recommendations
from .hybrid import get_hybrid_recommendations
import sys

@require_GET
def get_restaurants_api(request: HttpRequest):
    """
    API endpoint to fetch nearby restaurants based on latitude, longitude, and radius.
    Correctly parses 'lat', 'lon', and 'radius' from URL query parameters.
    """
    try:
        # Correctly parse parameters from the GET request's query string
        latitude = request.GET.get('lat')
        longitude = request.GET.get('lon')
        radius = request.GET.get('radius')

        # Validate that all required parameters are present
        if not all([latitude, longitude, radius]):
            return JsonResponse({"error": "Missing required parameters: lat, lon, radius"}, status=400)

        # Convert parameters to the correct data types
        latitude = float(latitude)
        longitude = float(longitude)
        radius = int(radius)

        # Call your existing logic function with the parsed parameters
        restaurants = get_nearby_recommend_restaurants_logic(latitude, longitude, radius)
        
        return JsonResponse(restaurants, safe=False)

    except ValueError:
        return JsonResponse({"error": "Invalid parameter format. lat/lon must be float, radius must be int."}, status=400)
    except Exception as e:
        print(f"An unexpected error occurred in get_restaurants_api: {e}", file=sys.stderr)
        return JsonResponse({"error": "An internal server error occurred."}, status=500)
    

@csrf_exempt
def get_hybrid_recommendations_api(request):
    if request.method == 'POST':
        try:
            # The user's profile and restaurant list are now in the POST body
            data = json.loads(request.body)
            restaurants = data.get('restaurants')
            user_profile = data.get('user_profile')

            if not restaurants or not user_profile:
                return JsonResponse({'error': 'restaurants and user_profile are required in the request body'}, status=400)

            # Generate personalized hybrid recommendations
            recommendations = get_hybrid_recommendations(user_profile, restaurants)
            
            return JsonResponse(recommendations, safe=False)

        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON in request body'}, status=400)
        except Exception as e:
            return JsonResponse({'error': f'An unexpected error occurred: {str(e)}'}, status=500)

    return JsonResponse({'error': 'Only POST method is allowed'}, status=405)