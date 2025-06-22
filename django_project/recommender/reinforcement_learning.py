import numpy as np
import random
from collections import deque
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense
from tensorflow.keras.optimizers import Adam
import os
import json
# --- NEW IMPORTS ---
from firebase_admin import firestore
import numpy as np


# --- RL Agent Configuration ---
STATE_SIZE = 35 # This should match the number of features from your content_based model
ACTION_SIZE = 4  # like, dislike, click, skip

class DQNAgent:
    def __init__(self, state_size, action_size, user_id):
        self.state_size = state_size
        self.action_size = action_size
        self.memory = deque(maxlen=2000)
        self.gamma = 0.95    # discount rate
        self.epsilon = 1.0  # exploration rate
        self.epsilon_min = 0.01
        self.epsilon_decay = 0.995
        self.learning_rate = 0.001
        self.user_id = user_id
        self.model = self._build_model()
        # --- NEW: Load model from Firestore on initialization ---
        self.load_model_from_firestore()

    def _build_model(self):
        """
        Builds a new DQN model.
        """
        model = Sequential()
        model.add(Dense(64, input_dim=self.state_size, activation='relu'))
        model.add(Dense(32, activation='relu'))
        model.add(Dense(self.action_size, activation='linear'))
        model.compile(loss='mse', optimizer=Adam(learning_rate=self.learning_rate))
        return model

    def remember(self, state, action, reward, next_state, done):
        self.memory.append((state, action, reward, next_state, done))

    def act(self, state):
        if np.random.rand() <= self.epsilon:
            return random.randrange(self.action_size)
        act_values = self.model.predict(state, verbose=0)
        return np.argmax(act_values[0])

    def replay(self, batch_size=32):
        if len(self.memory) < batch_size:
            return # Not enough memory to replay

        minibatch = random.sample(self.memory, batch_size)
        for state, action, reward, next_state, done in minibatch:
            target = reward
            if not done:
                target = (reward + self.gamma * np.amax(self.model.predict(next_state, verbose=0)[0]))
            
            target_f = self.model.predict(state, verbose=0)
            target_f[0][action] = target
            self.model.fit(state, target_f, epochs=1, verbose=0)

        if self.epsilon > self.epsilon_min:
            self.epsilon *= self.epsilon_decay

    def get_q_values(self, state):
        """
        Predicts the Q-values for a given state using the neural network.
        This is used during the re-ranking process to score restaurants.
        """
        # The model expects a batch of states, so we reshape the single state
        # vector into a batch of one.
        state = np.reshape(state, [1, self.state_size])
        
        # Predict the Q-values and return the first (and only) result.
        # verbose=0 prevents Keras from printing prediction progress to the console.
        q_values = self.model.predict(state, verbose=0)
        return q_values[0]

    def load_model_from_firestore(self):
        """Loads model weights from a Firestore document."""
        try:
            db = firestore.client()
            doc_ref = db.collection('rl_models').document(self.user_id)
            doc = doc_ref.get()

            if doc.exists:
                weights_data = doc.to_dict().get('weights')
                if weights_data:
                    # Reconstruct weights from flattened list and shape
                    reconstructed_weights = []
                    for w_data in weights_data:
                        shape = tuple(w_data['shape'])
                        values = np.array(w_data['values'], dtype=np.float32)
                        reconstructed_weights.append(values.reshape(shape))
                    
                    self.model.set_weights(reconstructed_weights)
                    print(f"  [RL] INFO: Loaded model for user {self.user_id} from Firestore.")
            else:
                print(f"  [RL] INFO: No model found for user {self.user_id} in Firestore. Building a new one.")
        except Exception as e:
            print(f"  [RL] ERROR: Failed to load model from Firestore for user {self.user_id}. Error: {e}")

    def save_model_to_firestore(self):
        """Saves model weights to a Firestore document."""
        try:
            db = firestore.client()
            doc_ref = db.collection('rl_models').document(self.user_id)
            
            # Convert weights to a Firestore-compatible format
            # (list of dicts with shape and flattened values)
            weights = self.model.get_weights()
            weights_serializable = []
            for w in weights:
                weights_serializable.append({
                    'shape': list(w.shape),
                    'values': w.flatten().tolist()
                })

            doc_ref.set({
                'weights': weights_serializable,
                'last_updated': firestore.SERVER_TIMESTAMP
            })
            print(f"  [RL FEEDBACK] Saved model to Firestore for user {self.user_id}.")
        except Exception as e:
            print(f"  [RL] ERROR: Failed to save model to Firestore for user {self.user_id}. Error: {e}")


# --- Feature Extraction (Helper Function) ---
# This function will be needed to convert restaurant data into a state vector for the RL agent.
def extract_rl_features(restaurant, all_categories):
    # This should create a feature vector of size STATE_SIZE.
    
    # --- Data Sanitization & Normalization ---
    # Sanitize and normalize rating, defaulting to 3.0 if invalid.
    try:
        rating = float(restaurant.get('rating', 3.0)) / 5.0
    except (ValueError, TypeError):
        rating = 3.0 / 5.0

    # Sanitize and normalize price_level, defaulting to 2 if invalid (e.g., "N/A").
    try:
        # Use float conversion to handle potential float strings before converting to int
        price_level = int(float(restaurant.get('price_level', 2))) / 4.0
    except (ValueError, TypeError):
        price_level = 2 / 4.0

    # Sanitize hybrid_score, defaulting to 0.0 if invalid.
    try:
        hybrid_score = float(restaurant.get('final_score', 0.0))
    except (ValueError, TypeError):
        hybrid_score = 0.0

    # One-hot encode categories
    rec_cats = set(restaurant.get('categories', []))
    cat_vector = [1 if cat in rec_cats else 0 for cat in all_categories]

    # Combine into a single feature vector
    features = [rating, price_level, hybrid_score] + cat_vector
    
    # Ensure the feature vector is the correct size, padding if necessary
    while len(features) < STATE_SIZE:
        features.append(0)

    return np.array(features[:STATE_SIZE]).reshape(1, -1)
