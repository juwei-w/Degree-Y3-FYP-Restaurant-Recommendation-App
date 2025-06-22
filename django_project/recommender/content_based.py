import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from firebase_admin import firestore
import math
import json
import os
import numpy as np

def _save_content_log(log_data):
    """Saves content-based data to a JSON file for debugging."""
    try:
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        log_dir = os.path.join(base_dir, 'assets', 'restaurant_data')
        os.makedirs(log_dir, exist_ok=True)
        counter = 1
        while os.path.exists(os.path.join(log_dir, f"content_data_{counter}.json")):
            counter += 1
        file_path = os.path.join(log_dir, f"content_data_{counter}.json")
        with open(file_path, 'w') as f:
            json.dump(log_data, f, indent=4, default=str)
    except Exception as e:
        print(f"Error saving content-based log: {e}")

# This function is kept in case distance calculations are needed in the future.
def haversine_distance(lat1, lon1, lat2, lon2):
    R = 6371  # Earth radius in KM
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)

    a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlambda/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c  # Distance in kilometers

# ===== Function to Get Content-Based Recommendations ===== #
def get_content_based_recommendations(user_profile, restaurants_data):
    """
    Generates personalized recommendations based on user profile and a list of restaurants.
    
    Args:
        user_profile (dict): The user's profile data sent from the client.
        restaurants_data (list): A list of restaurant dictionaries from the Flutter app.

    Returns:
        list: A sorted list of recommended restaurant dictionaries, with scores.
    """
    print("  [CONTENT] START: Content-based filtering...")
    if not restaurants_data:
        return []

    # --- Use User Profile from arguments ---
    user_preferences = set(user_profile.get("preferences", []))
    user_restrictions = set(user_profile.get("restrictions", []))
    print(f"  [CONTENT] User Preferences: {user_preferences}")  # <-- ADDED PRINT
    print(f"  [CONTENT] User Restrictions: {user_restrictions}")  # <-- ADDED PRINT
    
    favourites_list = user_profile.get("favourites", [])
    user_favourite_restaurants = {
        fav['place_id'] for fav in favourites_list if isinstance(fav, dict) and 'place_id' in fav
    }

    # Convert incoming restaurant list to a DataFrame
    content_df = pd.DataFrame(restaurants_data)

    # Preprocess the DataFrame
    content_df['editorial_summary'] = content_df['editorial_summary'].fillna("N/A")
    content_df['rating'] = content_df['rating'].fillna(content_df['rating'].median())
    
    # Ensure categories are lists and create a text representation for TF-IDF
    content_df['categories'] = content_df['categories'].apply(lambda x: x if isinstance(x, list) else [])
    content_df['Processed_Content'] = (
        content_df['name'].fillna('N/A') + " " +
        content_df['categories'].apply(lambda cats: ' '.join(cats)) + " " +
        content_df['editorial_summary'].fillna("N/A")
    )

    # --- TF-IDF Similarity to User's Favorites ---
    tfidf_vectorizer = TfidfVectorizer(stop_words='english')
    content_matrix = tfidf_vectorizer.fit_transform(content_df['Processed_Content'])
    
    favorite_indices = content_df[content_df['place_id'].isin(user_favourite_restaurants)].index
    tfidf_scores = [0] * len(content_df)
    if not favorite_indices.empty:
        user_profile_vector = content_matrix[favorite_indices].mean(axis=0)
        # CORRECTED: Convert the numpy.matrix to a numpy.ndarray before calculating similarity
        user_profile_vector_array = np.asarray(user_profile_vector)
        tfidf_scores = cosine_similarity(user_profile_vector_array, content_matrix).flatten()

    # --- Scoring Loop ---
    all_recommendations = []
    for idx, rec in content_df.iterrows():
        rec_categories = set(rec['categories'])

        # 1. Restriction Check (Requirement Logic)
        # A restaurant MUST have ALL the categories listed in user_restrictions.
        # If it doesn't meet the requirements, its score is 0.
        if not user_restrictions.issubset(rec_categories):
            final_score = 0.0
        else:
            # 2. Preference Score
            # How many of the restaurant's categories match the user's preferences?
            preference_score = 0
            if user_preferences:
                preference_score = len(user_preferences.intersection(rec_categories)) / len(user_preferences)

            # 3. Rating Score (Normalized 0-1)
            rating_score = rec.get('rating', 0) / 5.0

            # 4. TF-IDF Score (Similarity to favorites)
            tfidf_score = tfidf_scores[idx]

            # 5. Final Weighted Score
            # Weights are now dynamic. If tfidf_score is 0, its weight is given to preference_score.
            has_tfidf_score = tfidf_score > 0
            
            w_tfidf = 0.4 if has_tfidf_score else 0.0
            w_preference = 0.4 if has_tfidf_score else 0.8 # Becomes more important if no favorites are nearby
            w_rating = 0.2

            final_score = (
                (w_tfidf * tfidf_score) +
                (w_preference * preference_score) +
                (w_rating * rating_score)
            )

        rec_data = rec.to_dict()
        rec_data['score'] = final_score
        all_recommendations.append(rec_data)

    # Save log BEFORE sorting to see the raw scores
    _save_content_log(all_recommendations) # <-- ADDED LOGGING

    # Return the scored and sorted recommendations
    print(f"  [CONTENT] END: Returning {len(all_recommendations)} scored recommendations.") # <-- ADDED PRINT
    return sorted(all_recommendations, key=lambda x: x['score'], reverse=True)


