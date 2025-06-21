from django.http import JsonResponse, HttpRequest
from django.views.decorators.http import require_GET
from .get_restaurants import get_nearby_recommend_restaurants_logic # Make sure your logic function is imported
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