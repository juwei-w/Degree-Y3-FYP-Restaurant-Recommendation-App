from .content_based import get_content_based_recommendations
from .collaborative import get_collaborative_filtering_recommendations
from .reinforcement_learning import DQNAgent, extract_rl_features # Import RL components
from .constants import CATEGORY_KEYS # Import from constants
import json
import os

def _save_hybrid_log(log_data):
    """Saves recommendation data to a JSON file for debugging."""
    try:
        # Define the path relative to the project's base directory
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        log_dir = os.path.join(base_dir, 'assets', 'restaurant_data')
        os.makedirs(log_dir, exist_ok=True)

        # Find the next available file number
        counter = 1
        while os.path.exists(os.path.join(log_dir, f"hybrid_data_{counter}.json")):
            counter += 1
        
        file_path = os.path.join(log_dir, f"hybrid_data_{counter}.json")
        print(f"[HYBRID LOG] Attempting to save debug log to: {file_path}") # <-- ADDED PRINT

        with open(file_path, 'w') as f:
            # Use default=str to handle non-serializable data like Timestamps
            json.dump(log_data, f, indent=4, default=str)
    except Exception as e:
        # Print error but don't crash the recommendation request
        print(f"Error saving debug log: {e}")

def _combine_and_rank_recommendations(content_recs, collab_recs, weights):
    """
    Combines scores from content-based and collaborative models using weighted averaging.

    Args:
        content_recs (list): Recommendations from the content-based model. This list is
                             treated as the master list because it has already filtered out
                             restaurants based on user restrictions.
        collab_recs (list): Recommendations from the collaborative model.
        weights (dict): A dictionary with 'content' and 'collab' keys for weighting.

    Returns:
        list: A sorted list of restaurant dictionaries with a 'final_score'.
    """
    # Create a lookup map for collaborative scores for efficiency
    collab_scores_map = {rec['place_id']: rec.get('score', 0) for rec in collab_recs if 'place_id' in rec}
    
    final_recommendations = []
    for rec in content_recs:
        place_id = rec.get('place_id')
        if not place_id:
            continue

        content_score = rec.get('score', 0)
        collab_score = collab_scores_map.get(place_id, 0)

        # Calculate the weighted hybrid score
        hybrid_score = (content_score * weights['content']) + (collab_score * weights['collab'])
        
        # Add the final score to the restaurant details and remove the intermediate score
        rec['final_score'] = hybrid_score
        if 'score' in rec:
            del rec['score']
        
        final_recommendations.append(rec)

    # Sort by the new final_score, descending
    return sorted(final_recommendations, key=lambda x: x['final_score'], reverse=True)


def get_hybrid_recommendations(user_profile, restaurants_data):
    """
    Orchestrates the hybrid recommendation process.
    
    Args:
        user_profile (dict): A dictionary containing the user's profile data (uid, preferences, etc.).
        restaurants_data (list): A list of restaurant dictionaries from the Flutter app.

    Returns:
        list: A sorted list of recommended restaurants.
    """
    user_id = user_profile.get('uid', 'unknown_user')
    print(f"\n--- [HYBRID] START: Generating hybrid recommendations for user {user_id} ---")
    # 1. Get content-based recommendations.
    print("[HYBRID] Calling Content-Based model...")
    content_recs = get_content_based_recommendations(user_profile, restaurants_data)
    print(f"[HYBRID] Content-Based model returned {len(content_recs)} recommendations.")

    # 2. Get collaborative filtering scores.
    print("[HYBRID] Calling Collaborative Filtering model...")
    collab_recs = get_collaborative_filtering_recommendations(user_profile, restaurants_data)
    print(f"[HYBRID] Collaborative Filtering model returned {len(collab_recs)} scores.")

    # 3. Combine the results.
    print("[HYBRID] Combining scores...")
    weights = {'content': 0.6, 'collab': 0.4}
    final_recommendations = _combine_and_rank_recommendations(content_recs, collab_recs, weights)
    print(f"[HYBRID] Combination complete. Total recommendations: {len(final_recommendations)}")

    # Return only the top 20 recommendations from the hybrid model
    top_hybrid_recs = final_recommendations[:len(final_recommendations)]  # Adjust this if you want a specific number, e.g., 20
    # top_hybrid_recs = final_recommendations[:20]

    # --- 4. RL Re-ranking ---
    print(f"[HYBRID] Re-ranking using RL agent for user {user_id}...")
    
    # Instantiate a specific agent for this user
    rl_agent = DQNAgent(state_size=35, action_size=4, user_id=user_id)

    reranked_recs = []
    for rec in top_hybrid_recs:
        # Create the state vector for the RL agent.
        state = extract_rl_features(rec, CATEGORY_KEYS)
        
        # Get Q-values (predicted scores for each action) from the RL model.
        q_values = rl_agent.get_q_values(state)
        
        # Use the Q-value for the 'like' action (index 0) as the RL score.
        # This score represents the agent's belief that the user will like this item.
        rl_score = q_values[0]
        
        # Add a new score that combines the hybrid score and the RL agent's score.
        # The weight (e.g., 0.3) controls how much influence the RL agent has.
        rec['final_score_with_rl'] = rec.get('final_score', 0.0) + (rl_score * 0.3)
        reranked_recs.append(rec)

    # Sort the list by the new final score that includes the RL agent's input.
    final_reranked_list = sorted(reranked_recs, key=lambda x: x['final_score_with_rl'], reverse=True)

    # Log the re-ranking process
    print(f"[HYBRID] RL re-ranking complete. Total recommendations after re-ranking: {len(final_reranked_list)}")

    # --- Save log for debugging ---
    _save_hybrid_log({
        "user_id": user_id,
        "user_profile_received": user_profile,
        "weights": weights,
        "content_recs_with_scores": content_recs,
        "collab_recs_with_scores": collab_recs,
        "final_hybrid_recommendations": final_recommendations,
        "rl_reranked_recommendations": final_reranked_list
    })

    print(f"--- [HYBRID] END: Finished generating recommendations for user {user_id} ---\n")
    
    # Return the re-ranked recommendations
    return final_reranked_list