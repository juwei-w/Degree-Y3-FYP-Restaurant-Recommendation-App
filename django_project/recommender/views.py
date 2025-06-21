from django.http import JsonResponse, HttpRequest
from django.views.decorators.http import require_GET
from .get_restaurants import get_nearby_recommend_restaurants_logic # Make sure your logic function is imported
from .content_based import get_content_based_recommendations, content_df
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
    
@require_GET
def get_hybrid_recommendations_api(request: HttpRequest):
    """
    API endpoint to generate hybrid recommendations for a given user.
    """
    user_id = request.GET.get('user_id')
    if not user_id:
        return JsonResponse({"error": "Missing required parameter: user_id"}, status=400)

    try:
        print(f"Generating recommendations for user: {user_id}", file=sys.stderr)
        
        # 1. Get Content-Based recommendations
        content_recs = get_content_based_recommendations(user_id)
        
        # 2. Get Collaborative Filtering recommendations
        collab_recs = get_collaborative_filtering_recommendations(user_id, content_df)
        
        # 3. Get Hybrid recommendations
        hybrid_recs = get_hybrid_recommendations(content_recs, collab_recs)
        
        # Return the top 20 recommendations
        return JsonResponse(hybrid_recs[:20], safe=False)

    except Exception as e:
        print(f"An error occurred during recommendation generation: {e}", file=sys.stderr)
        return JsonResponse({"error": "An internal server error occurred."}, status=500)