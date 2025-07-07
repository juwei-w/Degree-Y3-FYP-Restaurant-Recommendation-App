# Restaurant Recommendation App

## Project Overview

With the explosion of information on the internet, users often face decision fatigue and information overload—especially when it comes to choosing where and what to eat. This project addresses these challenges by providing an AI-powered, location-based restaurant recommendation system that delivers fast, personalized, and context-aware suggestions to users. The app leverages both explicit (user ratings, preferences) and implicit (behavioral patterns) data, and integrates privacy-preserving mechanisms to ensure user trust and data security.

### Motivation
- Helps users make quick, informed, and healthy dining decisions, even with dietary restrictions or in unfamiliar locations.
- Reduces stress and time spent on food choices, and encourages healthier eating habits.
- Addresses common issues in recommendation systems such as the cold-start problem, data sparsity, and privacy concerns.

### Problem Statement
Choosing what and where to eat is often overwhelming due to the abundance of options, personal preferences, dietary restrictions, and privacy concerns. Many people experience decision fatigue, unhealthy eating, or dissatisfaction with their choices. Existing systems often lack true personalization, context-awareness, or privacy guarantees.

### Project Objectives
1. **Personalized Restaurant Recommendations:**
   - Suggests restaurants tailored to user preferences, dietary needs, and location.
2. **Location-Based Suggestions:**
   - Uses Google Maps API to recommend nearby restaurants and provide directions.
3. **Reservation Functionality:**
   - Integrates WhatsApp for easy, pre-filled reservation messaging.
4. **AI-Driven Feedback Loop:**
   - Continuously improves recommendations based on user feedback (like, unlike, skip, view).

### Project Scope
- **UI/UX:** Figma-based, intuitive, and visually appealing design.
- **Backend:** Django for business logic, APIs, and secure data processing.
- **AI Recommendations:** Machine learning for dynamic, real-time, and personalized suggestions.
- **Authentication & Data:** Firebase for secure login and data storage.
- **Location Services:** Google Maps for real-time, location-based recommendations and navigation.
- **Reservations:** WhatsApp integration for direct, convenient bookings.

The app is designed for both end-users seeking dining options and administrators managing restaurant data and analytics.

### Key Modules and Features
- **User Authentication:** Secure login/registration using Firebase, with role-based access for users and admins.
- **Restaurant Search & Listing:** Retrieve, search, and display restaurant data, including favorites and detailed views.
- **Recommendation Engine:** Hybrid (content-based + collaborative filtering) with reinforcement learning for adaptive, personalized suggestions.
- **Location-Based Services:** Google Maps API for real-time suggestions and navigation.
- **Admin Analytics:** Insights into user activity, preferences, and system performance for admins.
- **Reservation Module:** WhatsApp integration for direct, pre-filled restaurant bookings.



## Setup Instructions

### 1. Python Environment (Backend)
- Requires Python 3.11
- In the project root, create a virtual environment:
  ```sh
  py -3.11 -m venv venv
  ```
- Activate the virtual environment:
  - On Windows:
    ```sh
    .\venv\Scripts\activate
    ```
  - On macOS/Linux:
    ```sh
    source venv/bin/activate
    ```
- Install backend dependencies:
  ```sh
  pip install -r requirements.txt
  ```

### 2. Firebase Setup
- Go to the [Firebase Console](https://console.firebase.google.com/) and select your project.
- Click the ⚙️ gear icon next to "Project Overview" and select **Project settings**.
- Go to the **Service accounts** tab.
- Click the **Generate new private key** button under the Firebase Admin SDK section.
- Confirm and download the JSON file.
- Rename the downloaded file to `firebase_key.json`.
- Place it in `django_project/firebase_key.json` (this file is ignored by git for security).

### 3. Environment Variables
- Create or edit the `.env` file in the project root with the following keys:
  ```env
  GOOGLE_MAPS_API_KEY=your_google_maps_api_key
  API_BASE_URL=your_backend_url (e.g. http://localhost:8000 or https://xxxx.ngrok-free.app)
  DJANGO_ALLOWED_HOSTS=(e.g. localhost,127.0.0.1,xxxx.ngrok-free.app)
  SEARCH_RADIUS=5000 (5km)
  ```
- Make sure your API_BASE_URL matches your Django server's public URL (e.g., ngrok URL).
- You can add or remove hosts in `DJANGO_ALLOWED_HOSTS` as needed for your deployment.

### 4. Django Setup
- Navigate to the backend folder and run migrations:
  ```sh
  cd django_project
  python manage.py migrate
  ```
- Start the Django server:
  ```sh
  python manage.py runserver 0.0.0.0:8000
  ```
- (Optional, for public/mobile access) Start ngrok to expose your backend:
  ```sh
  ngrok http 8000
  ```
  Use the HTTPS forwarding URL from ngrok as your `API_BASE_URL` and add it to `DJANGO_ALLOWED_HOSTS` in your `.env` file.

### 5. Flutter Setup (Frontend)
- Connect your phone via USB and enable developer mode to run and debug the app on your device.
- Install Flutter dependencies:
  ```sh
  flutter pub get
  ```
- Run the app (it will prompt you to select a device if more than one is connected):
  ```sh
  flutter run
  ```

---

For more details, see the code comments and documentation in each folder.
