from Content_Based import CATEGORY_KEYS
from Hybrid import hybrid_recommendations

import numpy as np
import random
from collections import deque
from sklearn.preprocessing import MinMaxScaler
import tensorflow as tf
import pandas as pd
import ast
from tensorflow.keras import layers, models, optimizers
from collections import defaultdict

# --- Load & Preprocess restaurant data ---
restaurant_data = hybrid_recommendations

# Show TensorFlow logs --- (testing)
user_category_pref = defaultdict(int)
user_price_pref = []
user_rating_pref = []

def show_user_preferences(): # --- (testing)
    print("\n📈 User Preferences Summary:")
    
    if user_category_pref:
        sorted_cats = sorted(user_category_pref.items(), key=lambda x: -x[1])
        print("🔹 Categories:")
        for cat, count in sorted_cats:
            print(f"   - {cat}: {count}")

    if user_price_pref:
        avg_price = sum(user_price_pref) / len(user_price_pref)
        print(f"🔹 Avg. Price Level: {avg_price:.2f}")

    if user_rating_pref:
        avg_rating = sum(user_rating_pref) / len(user_rating_pref)
        print(f"🔹 Avg. Rating: {avg_rating:.2f}")

# --- Helper functions ---
def encode_categories(restaurant, category_list):
    cats = restaurant['categories']
    if isinstance(cats, str):
        cats = ast.literal_eval(cats)
    return np.array([1 if cat in cats else 0 for cat in category_list])

def extract_features(data, category_list):
    numeric_features = ["rating", "price_level", "score"]
    feature_matrix = []
    for item in data:
        numeric = [item[f] for f in numeric_features]
        cat_vector = encode_categories(item, category_list)
        feature_matrix.append(numeric + list(cat_vector))
    return np.array(feature_matrix)

# Helper to calculate similarity between two category sets
def get_category_similarity(cat1, cat2):
    return len(set(cat1).intersection(set(cat2))) / max(len(set(cat1).union(set(cat2))), 1)

def preference_score(categories, user_pref):
    return sum(user_pref.get(cat, 0) for cat in categories)

# --- Build feature matrix ---
features = extract_features(restaurant_data, CATEGORY_KEYS)
scaler = MinMaxScaler()
scaled_numeric = scaler.fit_transform(features[:, :3])  # Only scale numeric part
final_features = np.hstack([scaled_numeric, features[:, 3:]])  # Combine with one-hot

# --- DQN Environment ---
class DQNRecommender:
    def __init__(self, features, restaurant_data):
        self.state_size = features.shape[1]
        self.action_size = 4  # like, unlike, click, skip
        self.memory = deque(maxlen=2000)
        self.gamma = 0.95
        self.epsilon = 1.0
        self.epsilon_min = 0.01
        self.epsilon_decay = 0.995
        self.learning_rate = 0.001
        self.model = self._build_model()
        self.features = features
        self.restaurant_data = restaurant_data

    def _build_model(self):
        model = models.Sequential()
        model.add(layers.Dense(64, input_dim=self.state_size, activation='relu'))
        model.add(layers.Dense(32, activation='relu'))
        model.add(layers.Dense(self.action_size, activation='linear'))
        model.compile(loss='mse', optimizer=optimizers.Adam(learning_rate=self.learning_rate))
        return model

    def remember(self, state, action, reward, next_state):
        self.memory.append((state, action, reward, next_state))

    def act(self, state):
        if np.random.rand() <= self.epsilon:
            return random.randrange(self.action_size)
        act_values = self.model.predict(np.array([state]), verbose=0)
        return np.argmax(act_values[0])

    def replay(self, batch_size=32):
        minibatch = random.sample(self.memory, min(len(self.memory), batch_size))
        for state, action, reward, next_state in minibatch:
            target = reward + self.gamma * np.amax(self.model.predict(np.array([next_state]), verbose=0)[0])
            target_f = self.model.predict(np.array([state]), verbose=0)
            target_f[0][action] = target
            self.model.fit(np.array([state]), target_f, epochs=1, verbose=0)
        if self.epsilon > self.epsilon_min:
            self.epsilon *= self.epsilon_decay

    def display_restaurant(self, index):
        r = self.restaurant_data[index]
        categories = r['categories']
        if isinstance(categories, str):
            categories = ast.literal_eval(categories)
        print(f"\n🍽️  Recommendation: {r['name']}")
        print(f"   Categories: {', '.join(categories) if categories else 'Unknown'}")
        print(f"   Rating: {r['rating']}, Price Level: {r['price_level']}, Score: {r['score']}")

# --- Feedback Loop ---
def update_user_profile(action, categories):
    """
    Updates the user profile based on the action taken.
    - action: one of ['like', 'unlike', 'click', 'skip']
    - categories: list of categories associated with the restaurant
    """
    weight_map = {
        'like': 2,
        'unlike': -2,
        'click': 1,
        'skip': 0
    }
    weight = weight_map.get(action, 0)

    for category in categories:
        if category in user_category_pref:
            user_category_pref[category] += weight

# --- Evaluation Metrics ---
def precision_at_k(recommended, relevant, k):
    """Calculates Precision@K."""
    recommended_at_k = recommended[:k]
    relevant_at_k = set(recommended_at_k) & set(relevant)
    return len(relevant_at_k) / k

def recall_at_k(recommended, relevant, k):
    """Calculates Recall@K."""
    recommended_at_k = recommended[:k]
    relevant_at_k = set(recommended_at_k) & set(relevant)
    return len(relevant_at_k) / len(relevant) if relevant else 0

def mean_reciprocal_rank(recommended, relevant):
    """Calculates Mean Reciprocal Rank (MRR)."""
    for i, item in enumerate(recommended, start=1):
        if item in relevant:
            return 1 / i
    return 0

# --- Simulation ---
agent = DQNRecommender(final_features, restaurant_data)
num_episodes = 20

# Initialize user preference tracking
user_category_pref = {key: 0 for key in CATEGORY_KEYS}

print("Welcome to Smart Food Recommender (Category-Aware DQN Edition) 🍔🤖\n")

seen_indices = set()

for e in range(num_episodes):
    available_indices = list(set(range(len(final_features))) - seen_indices)
    if not available_indices:
        print("\n🎉 You've seen all restaurants! Ending simulation.")
        break

    # Score all available restaurants based on user preferences
    scored = []
    for i in available_indices:
        cats = ast.literal_eval(agent.restaurant_data[i]['categories'])
        score = preference_score(cats, user_category_pref)
        scored.append((score, i))

    # Sort by preference score (descending), pick highest
    scored.sort(reverse=True)
    idx = scored[0][1]  # Most preferred unseen restaurant
    seen_indices.add(idx)
    state = final_features[idx]
    agent.display_restaurant(idx)

    user_input = input("Do you like this recommendation? (like/unlike/click/skip): ").strip().lower()
    action_map = {"like": 0, "unlike": 1, "click": 2, "skip": 3}
    reward_map = {"like": 2, "unlike": -2, "click": 1, "skip": 0}

    if user_input not in action_map:
        print("Invalid input. Skipping.")
        continue

    r = agent.restaurant_data[idx]

    action = action_map[user_input]
    reward = reward_map[user_input]

    # Track category preferences if user likes it
    current_categories = ast.literal_eval(r['categories'])
    print(current_categories)
    if user_input == "like":
        for cat in current_categories:
            if cat in user_category_pref:
                user_category_pref[cat] += 2

    elif user_input == "unlike":
        for cat in current_categories:
            if cat in user_category_pref:
                user_category_pref[cat] -= 2
    elif user_input == "click":
        for cat in current_categories:
            if cat in user_category_pref:
                user_category_pref[cat] += 1
    elif user_input == "skip":
        for cat in current_categories:
            if cat in user_category_pref:
                user_category_pref[cat] -= 0

    # --- Reward shaping: encourage similar categories ---
    next_idx = random.choice(available_indices)
    next_state = final_features[next_idx]
    next_categories = ast.literal_eval(agent.restaurant_data[next_idx]['categories'])
    print(f"Next categories: {next_categories}")

    # Reward for similar categories
    sim_score = get_category_similarity(current_categories, next_categories)
    reward += sim_score

    agent.remember(state, action, reward, next_state)
    agent.replay()

    # Track rating and price level --- (testing)
    user_price_pref.append(r['price_level'])
    user_rating_pref.append(r['rating'])
    show_user_preferences()

print("\n✅ Training complete. Personalized model updated with category awareness!")
