from Content_Based import get_content_based_recommendations, print_content_based_recommendations, content_df
from Collaborative import get_collaborative_filtering_recommendations, print_collaborative_filtering_recommendations, random, user_ids
import os
import json
from Reinforcement_Learning import precision_at_k, recall_at_k, mean_reciprocal_rank

# Hybrid Approach with dictionary
def get_hybrid_recommendations(content_based_recommendations, collaborative_filtering_recommendations):
    # Combine and deduplicate using 'place_id' or 'name' as unique key
    seen = set()
    hybrid_recommendations = {}

    # Add content-based recommendations to the hybrid recommendations dictionary
    for rec in content_based_recommendations:
        unique_key = rec.get('place_id') or rec.get('name')
        if unique_key not in seen:
            seen.add(unique_key)
            hybrid_recommendations[unique_key] = {**rec, 'source': 'Content-Based'}
        else:
            # If the recommendation is already in the hybrid, update the source to "Both"
            hybrid_recommendations[unique_key]['source'] = 'Content-Based & Collaborative Filtering'

    # Add collaborative filtering recommendations to the hybrid recommendations dictionary
    for rec in collaborative_filtering_recommendations:
        # If rec is a Prediction object, use its 'iid' as the unique identifier
        unique_key = rec.get('place_id')  # The 'iid' is the item ID, which corresponds to the place_id in this case
        if unique_key not in seen:
            seen.add(unique_key)
            hybrid_recommendations[unique_key] = {**rec, 'source': 'Collaborative Filtering'}
        else:
            # If the recommendation is already in the hybrid, update the source to "Both"
            hybrid_recommendations[unique_key]['source'] = 'Content-Based & Collaborative Filtering'

    # Sort by score (descending)
    sorted_recommendations = sorted(hybrid_recommendations.values(), key=lambda x: x.get('score', 0) if isinstance(x, dict) else getattr(x, 'est', 0), reverse=True)

    return sorted_recommendations

def print_hybrid_recommendations(sorted_recommendations, top_n):
    print("\n📊 Hybrid Recommendations")
    print("-" * 50)
    for i, rec in enumerate(sorted_recommendations[:top_n], start=1):
        name = f"{rec.get('name')}"  # If name is not available in the Prediction, use item ID
        categories = rec.get('categories')  # Collaborative filtering may not have categories
        score = rec.get('score', 0)  # The estimated rating from collaborative filtering
        source = rec.get('source', 'Unknown')
        
        print(f"{i}. 🍴 {name}")
        print(f"   🔖 Categories: {categories if categories else 'N/A'}")
        print(f"   ⭐ Score: {score:.4f}")
        print(f"   🏷  Source: {source}")
        print("-" * 50)

def save_hybrid_recommendations_to_json(hybrid_recommendations, user_id):
    """
    Saves hybrid recommendations to a JSON file.

    Parameters:
    - hybrid_recommendations: list of recommendation dictionaries
    - user_id: ID of the user for which recommendations were generated
    - output_dir: directory to save the JSON file (default: 'output')
    - filename_prefix: prefix for the output file name
    """
    output_dir = "Hybrid_Output_json"
    filename_prefix = "Hybrid_Output"
    
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Create filename with user ID
    filename = f"{filename_prefix}_user_{user_id}.json"
    filepath = os.path.join(output_dir, filename)

    # Serialize the recommendations to JSON
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(hybrid_recommendations, f, ensure_ascii=False, indent=4)

    print(f"✅ Saved hybrid recommendations to {filepath}")

# --- Example Usage for Evaluation Metrics ---
def evaluate_recommendations(hybrid_recommendations, user_relevant_items, k=10):
    """
    Evaluates the hybrid recommendations using Precision@K, Recall@K, and MRR.
    - hybrid_recommendations: list of recommended items
    - user_relevant_items: list of items relevant to the user
    - k: top K items to consider
    """
    precision = precision_at_k(hybrid_recommendations, user_relevant_items, k)
    recall = recall_at_k(hybrid_recommendations, user_relevant_items, k)
    mrr = mean_reciprocal_rank(hybrid_recommendations, user_relevant_items)

    print(f"\n📊 Evaluation Metrics:")
    print(f"Precision@{k}: {precision:.2f}")
    print(f"Recall@{k}: {recall:.2f}")
    print(f"MRR: {mrr:.2f}")

# Example usage
random_user_id = random.choice(user_ids)
top_n = 10

# Get content-based recommendations (list of dicts)
content_based_recommendations = get_content_based_recommendations(random_user_id)
print_content_based_recommendations(content_based_recommendations, top_n)

# Get collaborative recommendations (list of dicts)
collaborative_filtering_recommendations = get_collaborative_filtering_recommendations(random_user_id, content_df)
print_collaborative_filtering_recommendations(collaborative_filtering_recommendations, random_user_id, top_n)

hybrid_recommendations = get_hybrid_recommendations(content_based_recommendations, collaborative_filtering_recommendations)
print_hybrid_recommendations(hybrid_recommendations, top_n)

save_hybrid_recommendations_to_json(hybrid_recommendations, random_user_id)

# Example usage
user_relevant_items = ["place_id_1", "place_id_2", "place_id_3"]  # Replace with actual relevant items
evaluate_recommendations(hybrid_recommendations, user_relevant_items)