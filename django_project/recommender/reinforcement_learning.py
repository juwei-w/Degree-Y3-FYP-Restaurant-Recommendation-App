import numpy as np
import random
from collections import deque
from tensorflow.keras import layers, models, optimizers
import ast
import base64
import tempfile
from firebase_admin import firestore

# --- RL Agent Configuration ---
STATE_SIZE = 35 # This should match the number of features from your content_based model
ACTION_SIZE = 4  # like, dislike, click, skip

class DQNAgent:
    def __init__(self, state_size, action_size, user_id):
        self.state_size = state_size
        self.action_size = action_size
        self.user_id = user_id
        
        # This is no longer a file path, but a reference to the Firestore client.
        self.db = firestore.client()

        self.memory = deque(maxlen=2000)
        self.gamma = 0.95    # discount rate
        self.epsilon = 1.0   # exploration rate
        self.epsilon_min = 0.01
        self.epsilon_decay = 0.995
        self.learning_rate = 0.001
        self.model = self._load_or_build_model()

    def _load_or_build_model(self):
        """
        Loads the model from the user's document in Firestore.
        If not found, builds a new one.
        """
        user_ref = self.db.collection('users').document(self.user_id)
        try:
            user_doc = user_ref.get()
            if user_doc.exists and 'rl_model_data' in user_doc.to_dict():
                print(f"  [RL] INFO: Loading model for user {self.user_id} from Firestore.")
                
                # 1. Get base64 string from Firestore and decode it
                encoded_model = user_doc.to_dict()['rl_model_data']
                model_bytes = base64.b64decode(encoded_model)
                
                # 2. Write bytes to a temporary file to be loaded by Keras
                with tempfile.NamedTemporaryFile(suffix=".h5", delete=True) as temp_model_file:
                    temp_model_file.write(model_bytes)
                    temp_model_file.flush() # Ensure all data is written
                    model = models.load_model(temp_model_file.name)
                return model
        except Exception as e:
            print(f"  [RL] WARNING: Could not load model from Firestore for user {self.user_id}. Error: {e}")

        # If loading fails or model doesn't exist, build a new one.
        print(f"  [RL] INFO: No model found for user {self.user_id} in Firestore. Building a new one.")
        model = models.Sequential()
        model.add(layers.Dense(64, input_dim=self.state_size, activation='relu'))
        model.add(layers.Dense(32, activation='relu'))
        model.add(layers.Dense(self.action_size, activation='linear'))
        model.compile(loss='mse', optimizer=optimizers.Adam(learning_rate=self.learning_rate))
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

    def save_model(self):
        """
        Saves the current model to the user's document in Firestore
        as a Base64 encoded string.
        """
        print(f"  [RL] INFO: Saving model for user {self.user_id} to Firestore.")
        try:
            # 1. Save model to a temporary in-memory file
            with tempfile.NamedTemporaryFile(suffix=".h5", delete=True) as temp_model_file:
                self.model.save(temp_model_file.name)
                temp_model_file.seek(0)
                model_bytes = temp_model_file.read()

            # 2. Base64 encode the bytes to store as a string
            encoded_model = base64.b64encode(model_bytes).decode('utf-8')

            # 3. Save the encoded string to the user's document
            user_ref = self.db.collection('users').document(self.user_id)
            user_ref.set({'rl_model_data': encoded_model}, merge=True)
            print(f"  [RL] SUCCESS: Model for user {self.user_id} saved to Firestore.")
        except Exception as e:
            print(f"  [RL] CRITICAL: Failed to save model to Firestore for user {self.user_id}. Error: {e}")


    def get_q_values(self, state):
        """Predicts Q-values for a given state."""
        return self.model.predict(state, verbose=0)[0]

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
