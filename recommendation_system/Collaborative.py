from surprise import Dataset, Reader
from surprise import SVD
import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
import numpy as np
import random

# =============================== # # Collaborative filtering is a method used in recommendation systems to predict the preferences of a user by collecting preferences from many users.
# === Collaborative Filtering === # # It is based on the idea that if two users agree on one issue, they are likely to agree on others as well.
# =============================== # # predicting what a particular user might like based on other users’ ratings

def get_collaborative_filtering_recommendations(user_id, content_df):
    # Get the list of all items in the training set
    all_item_ids = trainset.all_items()
    all_item_raw_ids = [trainset.to_raw_iid(iid) for iid in all_item_ids]

    # Get the items this user has already rated
    user_inner_id = trainset.to_inner_uid(user_id)
    rated_items_inner = set(j for (j, _) in trainset.ur[user_inner_id])
    rated_item_ids = set(trainset.to_raw_iid(iid) for iid in rated_items_inner)

    # Create anti-testset for this specific user only
    user_testset = [(user_id, iid, 0) for iid in all_item_raw_ids if iid not in rated_item_ids]

    # Predict only for this user
    predictions = algo.test(user_testset)
    predictions.sort(key=lambda x: x.est, reverse=True)  # Sort predictions by estimated rating (in descending order)
    
    # Create a set to track unique place_ids
    unique_recommendations = []

    # Add unique recommendations
    for prediction in predictions:
        if prediction.iid not in [p.iid for p in unique_recommendations]:
            unique_recommendations.append(prediction)
        # if len(unique_recommendations) >= top_n:
        #     break

    # ===== Add categories to each recommendation and return the top N unique recommendations ===== #

    recommendations_with_categories = []
    for rec in unique_recommendations:
        # Fetch the categories for the place_id and categories from content_df
        place_id = rec.iid
        
        # Normalize the score to be between 0 and 1
        min_score = 0
        max_score = 5

        score = (rec.est - min_score) / (max_score - min_score)

        matching_row = content_df[content_df['place_id'] == place_id]
        if not matching_row.empty:
            restaurant_data = matching_row.iloc[0].to_dict()
            restaurant_data['score'] = score
            recommendations_with_categories.append(restaurant_data)
        else:
            recommendations_with_categories.append({
                'place_id': place_id,
                'name': 'Unknown',
                'categories': 'Unknown',
                'score': score
            })
    
    # Return the top N recommendations
    return recommendations_with_categories

def print_collaborative_filtering_recommendations(recommendations, user_id, top_n):
    sorted_recommendations = sorted(recommendations, key=lambda x: x['score'], reverse=True)[:top_n]  # Top 5 recommendations
    print("\n📊 Collaborative Filtering Recommendations")

    # Print user details
    print("\n📊 User Details:")
    print(f"User ID: {user_id}")
    print(f"Preferences: {', '.join(user_data.get('preferences', []))}")
    print("-" * 50)

    # Print collaborative filtering recommendations
    for i, rec in enumerate(recommendations, start=1):
        name = rec.get('name', 'Unknown')
        place_id = rec.get('place_id', 'Unknown')
        categories = rec.get('categories', 'Unknown')
        score = rec.get('score', 0)
        print(f"{i}. 🍴 {name}")
        print(f"   🆔 Place ID: {place_id}")
        print(f"   🔖 Categories: {categories}")
        print(f"   ⭐ Score: {score:.2f}")
        print("-" * 50)


# # ===== Initialize Firebase Admin SDK ===== #

cred = credentials.Certificate("firebase_key.json")
firebase_admin.initialize_app(cred)
db = firestore.client() # Connect to Firestore

reader = Reader(rating_scale=(1, 5)) # Define the Reader (rating scale: 1 to 5)

# ===== Fetch ratings from Firestore ===== #

ratings_data = [] # List to store the ratings data for Surprise

users_ref = db.collection("users")
users = users_ref.stream()

for user_doc in users: # Iterate through each user document and extract ratings
    user_data = user_doc.to_dict()
    user_id = user_doc.id
    if "ratings" in user_data:
        user_ratings = user_data["ratings"]
        for place_id, rating in user_ratings.items():
            ratings_data.append((user_id, place_id, rating)) # Store as (user_id, place_id, rating)

ratings_df = pd.DataFrame(ratings_data, columns=['user_id', 'place_id', 'rating']) # Convert the list of ratings into a format compatible with Surprise

data = Dataset.load_from_df(ratings_df, reader) # Now load the dataset from the correct DataFrame (ratings_df)

# ===== Train the model ===== #

trainset = data.build_full_trainset()
algo = SVD()
algo.fit(trainset)

# ===== Test recommendations for random user ===== # (make a print function for collaborative filtering to fix the sequence problem)

users_ref = db.collection("users") # Fetch ratings from Firestore
users = users_ref.stream()
user_ids = [user.id for user in users] # Get a list of all user IDs
random_user_id = random.choice(user_ids) # Select a random user ID
# random_user_id = "33"

# collaborative_filtering_recommendations = get_collaborative_filtering_recommendations(random_user_id, 5, content_df)
# print_collaborative_filtering_recommendations(collaborative_filtering_recommendations, random_user_id)





