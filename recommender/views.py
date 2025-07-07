from django.http import JsonResponse, HttpRequest
from django.views.decorators.http import require_GET
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST
import json
from .get_restaurants import get_nearby_recommend_restaurants_logic
from .content_based import get_content_based_recommendations
from .collaborative import get_collaborative_filtering_recommendations
from .hybrid import get_hybrid_recommendations
from .reinforcement_learning import DQNAgent, extract_rl_features
from .constants import CATEGORY_KEYS
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

@csrf_exempt
@require_POST
def record_feedback(request):
    """
    Receives feedback from the user, trains the RL model, and saves it.
    """
    try:
        data = json.loads(request.body)
        user_id = data.get('user_id')
        restaurant_data = data.get('restaurant_data') # Get the full object
        action = data.get('action')

        if not all([user_id, restaurant_data, action]):
            return JsonResponse({'status': 'error', 'message': 'Missing required fields.'}, status=400)

        print(f"\n--- [RL FEEDBACK] Received: {action} for restaurant {restaurant_data.get('name')} from user {user_id} ---")

        # Define rewards and action mapping
        action_map = {'like': 0, 'dislike': 1, 'click_details': 2, 'skip': 3}
        reward_map = {'like': 1.0, 'dislike': -1.0, 'click_details': 0.5, 'skip': -0.2}

        if action not in action_map:
            return JsonResponse({'status': 'error', 'message': 'Invalid action.'}, status=400)

        # 1. Instantiate the agent (which loads the existing model)
        agent = DQNAgent(state_size=35, action_size=4, user_id=user_id)

        # 2. Create the 'state' and 'reward' from the feedback
        state = extract_rl_features(restaurant_data, CATEGORY_KEYS)
        action_index = action_map[action]
        reward = reward_map[action]
        
        # 3. Remember the experience
        agent.remember(state, action_index, reward, state, done=True)
        print(f"  [RL FEEDBACK] Stored experience in memory.")

        # 4. Replay/train the model with a batch of experiences
        batch_size = 32
        if len(agent.memory) > batch_size:
            agent.replay(batch_size)
            print(f"  [RL FEEDBACK] Replayed experience and trained model.")

        # 5. Save the updated model back to Firestore
        agent.save_model_to_firestore()

        return JsonResponse({'status': 'success', 'message': 'Feedback recorded and model updated.'})

    except Exception as e:
        print(f"  [RL FEEDBACK] CRITICAL: An error occurred: {e}")
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)