from surprise import Dataset, Reader
from surprise import SVD
import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
from collections import defaultdict
from django.conf import settings
import os
import json

# =============================== # # Collaborative filtering is a method used in recommendation systems to predict the preferences of a user by collecting preferences from many users.
# === Collaborative Filtering === # # It is based on the idea that if two users agree on one issue, they are likely to agree on others as well.
# =============================== # # predicting what a particular user might like based on other users’ ratings

# Initialize Firebase Admin SDK only if it hasn't been initialized yet.
# This prevents errors during hot-reloading in Django's development server.
if not firebase_admin._apps:
    cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS)
    firebase_admin.initialize_app(cred)
else:
    # Fallback for environments where the key might be configured differently
    # For example, using environment variables on a server
    if os.environ.get('GOOGLE_APPLICATION_CREDENTIALS'):
            firebase_admin.initialize_app()
    else:
        print("WARNING: Firebase credentials not found. Collaborative filtering may not work.")


def _get_all_user_favorites():
    """
    Fetches the 'favourite_restaurants' list for all users from Firestore.
    Returns a dictionary of {user_id: {set_of_favorite_place_ids}}.
    """
    db = firestore.client()
    print(f"  [COLLAB] INFO: Connected to Firebase project: {db.project}")
    
    users_ref = db.collection('users')
    all_favorites = {}
    doc_count = 0
    
    for doc in users_ref.stream():
        doc_count += 1
        user_data = doc.to_dict()
        user_id_from_doc = user_data.get('uid', doc.id)

        if 'favourites' in user_data:
            favorites_list = user_data.get('favourites', [])
            if favorites_list:
                place_ids = {
                    fav['place_id'] for fav in favorites_list if isinstance(fav, dict) and 'place_id' in fav
                }
                if place_ids:
                    all_favorites[user_id_from_doc] = place_ids

    if doc_count == 0:
        print("  [COLLAB] CRITICAL: No documents found in the 'users' collection.")
        
    print(f"  [COLLAB] INFO: Found favorites for {len(all_favorites)} out of {doc_count} users.")
    return all_favorites

def _calculate_jaccard_similarity(set1, set2):
    """
    Calculates the Jaccard similarity between two sets.
    """
    intersection = len(set1.intersection(set2))
    union = len(set1.union(set2))
    return intersection / union if union != 0 else 0

def _save_collab_log(log_data):
    """Saves collaborative filtering data to a JSON file for debugging."""
    try:
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        log_dir = os.path.join(base_dir, 'assets', 'restaurant_data')
        os.makedirs(log_dir, exist_ok=True)
        counter = 1
        while os.path.exists(os.path.join(log_dir, f"collab_data_{counter}.json")):
            counter += 1
        file_path = os.path.join(log_dir, f"collab_data_{counter}.json")
        with open(file_path, 'w') as f:
            json.dump(log_data, f, indent=4, default=str)
    except Exception as e:
        print(f"Error saving collaborative log: {e}")

def get_collaborative_filtering_recommendations(user_profile, restaurants_data):
    """
    Generates collaborative filtering scores for a list of restaurants based on
    the favorites of similar users.
    """
    print("  [COLLAB] START: Collaborative filtering...")
    if not restaurants_data:
        return []

    # Get the target user's favorites directly from the passed profile
    target_user_id = user_profile.get('uid')
    favourites_list = user_profile.get("favourites", [])
    target_user_favorites = {
        fav['place_id'] for fav in favourites_list if isinstance(fav, dict) and 'place_id' in fav
    }
    print(f"  [COLLAB] Target User ID: {target_user_id}")
    print(f"  [COLLAB] Target User Favorites: {target_user_favorites}")

    # Initialize recommendations list to handle all edge cases safely.
    recommendations = []

    if not target_user_favorites:
        # If the user has no favorites, we cannot find similar users.
        print(f"  [COLLAB] WARNING: User '{target_user_id}' has no favorites in profile. Returning 0 scores.")
        for r in restaurants_data:
            if r.get('place_id'):
                r_copy = r.copy()
                r_copy['score'] = 0.0
                recommendations.append(r_copy)
        return recommendations

    # Get ALL user favorites from the database to find neighbors
    all_user_favorites = _get_all_user_favorites()

    # --- 1. Find Similar Users ---
    similarities = []
    for other_user_id, other_user_favorites in all_user_favorites.items():
        if target_user_id == other_user_id:
            continue
        similarity = _calculate_jaccard_similarity(target_user_favorites, other_user_favorites)
        if similarity > 0:
            similarities.append((other_user_id, similarity))
    
    similarities.sort(key=lambda x: x[1], reverse=True)
    top_neighbors = dict(similarities[:50])

    if not top_neighbors:
        print("  [COLLAB] WARNING: No similar users found. Returning 0 scores.")
        for r in restaurants_data:
            if r.get('place_id'):
                r_copy = r.copy()
                r_copy['score'] = 0.0
                recommendations.append(r_copy)
        return recommendations

    # --- 2. Aggregate Recommendations from Neighbors ---
    neighbor_likes = defaultdict(list)
    for neighbor_id, similarity_score in top_neighbors.items():
        for place_id in all_user_favorites.get(neighbor_id, set()):
            # We only care about items the target user hasn't already favorited
            if place_id not in target_user_favorites:
                neighbor_likes[place_id].append(similarity_score)

    # --- 3. Score the candidate restaurants ---
    max_possible_score = sum(top_neighbors.values())
    for r in restaurants_data:
        place_id = r.get('place_id')
        if place_id:
            r_copy = r.copy()
            raw_score = sum(neighbor_likes.get(place_id, []))
            normalized_score = raw_score / max_possible_score if max_possible_score > 0 else 0
            r_copy['score'] = normalized_score
            recommendations.append(r_copy)

    print(f"  [COLLAB] END: Returning {len(recommendations)} scored items.")
    # Save a more detailed log object for better debugging.
    _save_collab_log({
        "user_id": target_user_id,
        "user_favorites": list(target_user_favorites),
        "top_neighbors": top_neighbors,
        "recommendations_with_scores": recommendations
    })
    return recommendations



