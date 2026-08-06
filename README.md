# 🗺️ RoamWise — AI-Powered Smart Travel Companion

RoamWise is a state-of-the-art mobile travel assistant built with **Flutter** and powered by a **Node.js, Express, and MongoDB** backend. The application is designed to act as an all-in-one assistant for modern travelers, offering features like AI-generated day-by-day itineraries, real-time location exploration, an AI translator and travel assistant, safety/emergency tools, and secure cross-platform data synchronization.

---

## 🚀 Key Features

### 1. 📱 Dynamic Traveler Dashboard (`DashboardTab`)
- **Quick Action Tools**: Instant shortcuts to critical widgets including **Emergency Services**, **Language Translator**, and **Saved Places/Bookmarks**.
- **Active Trip Tracker**: A custom progress card tracking your active itinerary dates, displaying remaining duration, and calculating visual progress.
- **Top Recommendations**: A horizontal carousel of high-rated travel attractions categorized dynamically (e.g., Sightseeing, Culture, History) with reviews and location snapshots.

### 2. 🗺️ Interactive Maps & Explore (`ExploreTab`)
- **Simulated GPS Location Tracking**: Displays a pulse GPS locator on a custom preview map grid showing the traveler's position.
- **Category Filter Chips**: Filter local places dynamically across **Hotels**, **Dining**, **Sights**, and **Transit**.
- **Detailed Place Cards**: Lists nearby locations showing ratings, distance from user, pricing indicators (`$$`), and icons.

### 3. 🪄 AI Itinerary Planner (`PlannerTab`)
- **Interactive Trip Generator**: Pop up a custom bottom-sheet interface to request a new trip.
- **Tailored Options**: Input Destination (City, Country), Duration (3, 5, 7, or 10 days), and Travel Style (Leisure, Adventure, Budget, Luxury, Cultural).
- **Expandable Day-by-Day Timeline**: Browse saved trips and expand individual itineraries to review scheduled, time-blocked activities (e.g., Check-in, Sightseeing, Dinings).

### 4. 💬 AI Travel Assistant & Translator (`ChatTab`)
- **Gemini-Powered Chatbot**: Simulated conversational assistant providing recommendations, translations, and suggestions.
- **Live Translation Selector**: Choose source and target translations (e.g., English to Japanese `JA`, Spanish `ES`, or French `FR`) on the fly.
- **Voice Input Integration**: Voice recognition mic utility prompting real-time translation inputs.

### 5. 🔐 Secure Account Management (`AuthScreen` & `ProfileTab`)
- **Secure Sessions**: Token-based authentication using JSON Web Tokens (JWT) cached in cross-platform secure memory.
- **Travel Stats Tracker**: Visual counters reflecting overall **Trips Count**, **Countries Count**, and **Saved Items Count** linked directly to the database.

---

## 🛠️ Technology Stack

| Layer | Technology | Key Libraries / Frameworks |
| :--- | :--- | :--- |
| **Frontend** | Flutter (Dart SDK ^3.12.2) | `flutter_riverpod` (State Management), `dio` (HTTP client), `google_fonts` (Outfit), `flutter_secure_storage` (Keychain/Keystore), `shared_preferences` (Local storage), `google_maps_flutter` |
| **Backend** | Node.js (v18+) & Express | Mongoose (MongoDB ODM), `bcryptjs` (Password hashing), `jsonwebtoken` (Auth tokens), `cors`, `dotenv` |
| **Database** | MongoDB | Cloud-hosted MongoDB Atlas or local deployment |
| **Media & Storage** | Cloudinary | Cloudinary API integration for profile and itinerary assets |

---

## 🎨 Visual Design System

RoamWise features a premium, state-of-the-art dark user interface:
- **Typography**: Powered by the modern [Outfit Font](https://fonts.google.com/specimen/Outfit) via Google Fonts.
- **Color Palette**:
  - **Background**: `#0D0E12` (Ultra-dark slate)
  - **Surface**: `#171821` (Premium dark grey cards)
  - **Primary**: `#8A2BE2` (Electric Violet)
  - **Accent**: `#00F0FF` (Neon Cyan/Teal)
  - **Success**: `#39FF14` (Neon Green)
  - **Card Border**: `#2C2E3E` (Subtle separator)

---

## 📁 Repository Structure

```
RoamWise/
├── android/               # Android Native App Configuration
├── ios/                   # iOS Native App Configuration
├── backend/               # Node.js API Service
│   ├── config/            # DB Connection & Configuration Setup
│   ├── controllers/       # Route request controllers (Auth)
│   ├── middleware/        # Authorization verification handlers
│   ├── models/            # MongoDB schemas (User, Trip)
│   ├── routes/            # Express router endpoints
│   ├── server.js          # API Server entry point
│   ├── .env.example       # Example configuration files
│   └── package.json       # Backend dependency index
├── lib/                   # Flutter App Logic
│   ├── models/            # Client data schemas (User)
│   ├── providers/         # Riverpod State Management controllers
│   ├── routes/            # Client side navigation routes
│   ├── screens/           # Dashboard, Chat, Explore, Planner, Auth UI
│   ├── utils/             # Themes, Styles, Base Config paths
│   └── main.dart          # Flutter App root entry point
├── pubspec.yaml           # Flutter package dependencies
└── README.md              # Documentation
```

---

## ⚙️ Getting Started & Local Setup

### Step 1: Clone the Repository
```bash
git clone https://github.com/yourusername/RoamWise.git
cd RoamWise
```

### Step 2: Configure and Run the Backend API
1. Navigate to the backend folder:
   ```bash
   cd backend
   ```
2. Install the Node modules:
   ```bash
   npm install
   ```
3. Create your `.env` configuration file from the template:
   ```bash
   cp .env.example .env
   ```
4. Update the environment variables in `.env` with your API credentials:
   ```ini
   PORT=5000
   MONGODB_URI=your_mongodb_connection_string
   JWT_SECRET=your_custom_jwt_secret_token
   GEMINI_API_KEY=your_gemini_api_key
   CLOUDINARY_CLOUD_NAME=your_cloudinary_name
   CLOUDINARY_API_KEY=your_cloudinary_key
   CLOUDINARY_API_SECRET=your_cloudinary_secret
   GOOGLE_MAPS_API_KEY=your_maps_key
   ```
5. Start the development server (runs via nodemon for hot-reload):
   ```bash
   npm run dev
   ```

### Step 3: Launch the Flutter Mobile App
1. Make sure your flutter environment is configured and you have an emulator/device active:
   ```bash
   flutter doctor
   ```
2. Fetch Flutter packages:
   ```bash
   flutter pub get
   ```
3. Select an emulator or connected device and launch the app:
   ```bash
   flutter run
   ```
   > [!NOTE]
   > The application contains automatic loopback routing configuration in `lib/utils/config.dart`. When running on an **Android Emulator**, request endpoints redirect to host port `10.0.2.2:5000`. On **iOS Simulators** or desktop wrappers, it points directly to `localhost:5000`.

---

## 📡 API Reference Endpoints

### Authentication Endpoints

#### 1. Register User
* **URL**: `/api/auth/register`
* **Method**: `POST`
* **Auth Required**: No (Public)
* **Request Body**:
  ```json
  {
    "name": "Jane Doe",
    "email": "jane@example.com",
    "password": "securepassword123"
  }
  ```
* **Success Response (Code 201)**:
  ```json
  {
    "_id": "60d0fe4f5311236168a109ca",
    "name": "Jane Doe",
    "email": "jane@example.com",
    "profilePic": "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde...",
    "travelStats": {
      "tripsCount": 0,
      "countriesCount": 0,
      "savedItemsCount": 0
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```

#### 2. Log In User
* **URL**: `/api/auth/login`
* **Method**: `POST`
* **Auth Required**: No (Public)
* **Request Body**:
  ```json
  {
    "email": "jane@example.com",
    "password": "securepassword123"
  }
  ```
* **Success Response (Code 200)**:
  ```json
  {
    "_id": "60d0fe4f5311236168a109ca",
    "name": "Jane Doe",
    "email": "jane@example.com",
    "profilePic": "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde...",
    "travelStats": {
      "tripsCount": 0,
      "countriesCount": 0,
      "savedItemsCount": 0
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```

#### 3. Fetch User Profile
* **URL**: `/api/auth/profile`
* **Method**: `GET`
* **Auth Required**: Yes (Bearer Token in Authorization Header)
* **Headers**: `Authorization: Bearer <your_jwt_token>`
* **Success Response (Code 200)**:
  ```json
  {
    "_id": "60d0fe4f5311236168a109ca",
    "name": "Jane Doe",
    "email": "jane@example.com",
    "profilePic": "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde...",
    "travelStats": {
      "tripsCount": 2,
      "countriesCount": 4,
      "savedItemsCount": 15
    },
    "createdAt": "2026-08-06T08:00:00.000Z"
  }
  ```

---

## 💾 Database Schemas

### User Schema (`User`)
Represents registered traveler profiles. Contains core identity values, a profile picture URI, and numerical statistics showing aggregate trip, country, and saved item counts.

### Trip Schema (`Trip`)
Represents an itinerary generated for a traveler. 
- Contains a reference linking back to the user ID.
- Includes high-level trip settings like Destination, Duration (Days count), and Travel Style.
- Nested timeline items store scheduled activities day-by-day (e.g., title, description, time-blocks).
