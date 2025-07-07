from Get_Restaurant_Data_All import CATEGORY_DICT
from Collaborative import db

import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import normalize
from fuzzywuzzy import process
import math
import ast

CATEGORY_KEYS = list(CATEGORY_DICT.keys())
weights = {
    'tfidf_score': 0.3,         # Lower textual similarity weight
    'category_score': 0.2,      # Increase category overlap weight
    'rating_score': 0.15,       # Keep rating similarity
    'price_score': 0.15,         # Keep price similarity
    'distance_score': 0.2      # Keep proximity similarity
}

# ===== Load the dataset ===== #

data = pd.read_csv("./Google_Map_Output_csv/map_output_5.csv")
content_df = data[['place_id', 'name', 'categories', 'address', 'longitude', 'latitude', 'types', 
                   'rating', 'price_level', 'reviews', 'editorial_summary', 'business_status']].copy()      # Select relevant columns for content-based filtering

# ======================= # # Content-based filtering recommends items similar to those a user has liked in the past, based on item features.
# Content-Based Filtering # # It uses the features of the items to recommend other similar items, regardless of user preferences.
# ======================= # # It is based on the idea that if a user liked a certain item, they will also like similar items.

# # Preprocessing function to remove stopwords and stem the text
# def preprocess_text(text):
#     # Preprocessing: Remove stopwords, apply stemming
#     stop_words = set(stopwords.words('english'))
#     stemmer = PorterStemmer()

#     words = text.split()
#     words = [word for word in words if word.lower() not in stop_words]  # Remove stopwords
#     words = [stemmer.stem(word) for word in words]  # Apply stemming
#     return " ".join(words)

def preprocess_data():
    # Apply preprocessing to the 'Content' column
    content_df['editorial_summary'].fillna("N/A", inplace=True)
    content_df['price_level'].fillna(content_df['price_level'].median(), inplace=True)
    content_df['rating'].fillna(content_df['rating'].median(), inplace=True)
    content_df['Processed_Content'] = (
        content_df['name'].fillna('N/A') + " " +
        content_df['categories'] + " " +
        content_df['editorial_summary'].fillna("N/A") + " " +
        content_df['reviews'].fillna('N/A')
    )
    # content_df['Processed_Content'] = content_df['Processed_Content'].apply(preprocess_text)


# Function to calculate the Haversine distance between two geographical points
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
def get_content_based_recommendations(random_user_id):
    all_recommendations = []  # List to store all recommendations

    preprocess_data()  # Preprocess the data

    # ===== Initialize the TF-IDF vectorizer ===== #
    tfidf_vectorizer = TfidfVectorizer(norm='l2', stop_words='english', ngram_range=(1, 2), min_df=3)  # Use n-grams and ignore stopwords
    content_matrix = tfidf_vectorizer.fit_transform(content_df['Processed_Content'])  # TF-IDF transformation
    content_matrix = normalize(content_matrix, axis=1)  # Normalize the matrix to avoid dominance of longer texts

    # Compute cosine similarity between the content matrix and itself
    content_similarity = cosine_similarity(content_matrix)

    # Get user favourite restaurants from Firebase
    user_doc = db.collection("users").document(random_user_id).get()  # Get the user document from Firestore
    user_data = user_doc.to_dict()  # Convert the document to a dictionary
    user_favourite_restaurants = user_data.get("favourite_restaurants", [])  # Get the user's favourite restaurants

    for place_id in user_favourite_restaurants:
        # Find the index of the input place in content_df
        index = content_df[content_df['place_id'] == place_id].index[0]
        input_place = content_df.loc[index]
        input_categories = set(eval(input_place['categories']))
        input_lat = input_place['latitude']
        input_lon = input_place['longitude']
        input_rating = input_place['rating']
        input_price = input_place['price_level']

        similarity_scores = content_similarity[index]

        recommendations = []

        # Loop through all restaurants in content_df to generate recommendations
        for idx, rec in content_df.iterrows():
            if idx == index:
                continue  # Skip the input restaurant itself

            rec_categories = set(eval(rec['categories']))
            category_overlap = input_categories.intersection(rec_categories)

            # Distance calculation
            distance_km = haversine_distance(input_lat, input_lon, rec['latitude'], rec['longitude'])

            # Compare ratings and price level
            rating_diff = abs(rec['rating'] - input_rating)
            price_diff = abs(rec['price_level'] - input_price)

            # Normalize feature components
            category_score = 1 if len(category_overlap) > 0 else 0  # Binary match score

            max_rating = 5.0
            rating_score = 1 - (rating_diff / max_rating) if pd.notna(rating_diff) else 0

            max_price_diff = 3  # assume max price level diff is 3
            price_score = 1 - (price_diff / max_price_diff) if pd.notna(price_diff) else 0

            max_distance = 20  # assume anything beyond 20 km is far
            distance_score = 1 - (distance_km / max_distance) if distance_km <= max_distance else 0

            # Weighted score
            final_score = (
                weights['tfidf_score'] * similarity_scores[idx] +
                weights['category_score'] * category_score +
                weights['rating_score'] * rating_score +
                weights['price_score'] * price_score +
                weights['distance_score'] * distance_score
            )

            # Convert the full row to a dictionary
            rec_data = rec.to_dict()

            # Add the computed scores
            rec_data.update({
                'score': final_score,
                'common_categories': list(category_overlap)
            })

            recommendations.append(rec_data)


        print(f"Input Place: {input_place['name']}")
        print(f"Categories: {input_categories}")
        print("-" * 50)

        # Sort recommendations after calculating all scores and take the top N
        recommendations = sorted(recommendations, key=lambda x: x['score'], reverse=True)
        
        # Append recommendations for this place_id to the list of all recommendations
        all_recommendations.extend(recommendations)

    # Return the top N recommendations across all the input places
    return sorted(all_recommendations, key=lambda x: x['score'], reverse=True)

# ===== Function to Print Content-Based Recommendations ===== #
def print_content_based_recommendations(recommendations, top_n=10):
    print("\n📊 Content-Based Recommendations (Prioritized Features)")
    for i, rec in enumerate(sorted(recommendations, key=lambda x: x['score'], reverse=True)[:top_n], start=1):
        print(f"{i}. 🍴 {rec['name']}")
        print(f"   🔖 Categories: {rec['categories']}")
        print(f"   ✅ Common Categories: {rec['common_categories']}")
        print(f"   ⭐ Final Score: {rec['score']:.4f}")
        # print(f"     · TF-IDF: {rec['tfidf']:.4f}")
        # print(f"     · Category Match: {rec['category_score']}")
        # print(f"     · Rating Score: {rec['rating_score']} (Rating: {rec['rating']})")
        # print(f"     · Price Score: {rec['price_score']} (Price: {rec['price_level']})")
        # print(f"     · Distance Score: {rec['distance_score']} ({rec['distance_km']} km)")
        print(f"   🟢 Status: {rec['business_status']}")
        print("-" * 50)


# # ===== Example usage ===== #
# random_place_id = content_df['place_id'].sample(1).values[0]  # Randomly select a place_id
# content_based = get_content_based_recommendations(user_favourite_restaurants, 10)  # Now returns a list of dicts

# # Print recommendations
# print_content_based_recommendations(content_based)


