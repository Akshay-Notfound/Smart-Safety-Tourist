# Smart Tourist Safety App - Technical Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Key Features](#key-features)
5. [Data Flow](#data-flow)
6. [Safety Score Calculation](#safety-score-calculation)
7. [API Integrations](#api-integrations)
8. [Database Schema](#database-schema)
9. [Security Considerations](#security-considerations)
10. [Deployment](#deployment)

## Overview

The Smart Tourist Safety App is a comprehensive solution designed to enhance the safety and security of tourists by providing real-time location tracking, emergency contact management, and safety status monitoring. The app connects tourists with local authorities to ensure quick response in emergency situations.

## Architecture

The app follows a client-server architecture with the following components:

```
┌─────────────────┐    ┌──────────────────────┐    ┌──────────────────┐
│   Tourist App   │◄──►│  Firebase Backend    │◄──►│ Authority Portal │
└─────────────────┘    └──────────────────────┘    └──────────────────┘
                              │
                              ▼
                      ┌──────────────────┐
                      │  Google Maps API │
                      └──────────────────┘
```

### Client-Side (Flutter)
- Mobile application for tourists (Android/iOS)
- Web application for authorities
- Real-time UI updates using Flutter streams

### Server-Side (Firebase)
- Authentication (Firebase Auth)
- Database (Cloud Firestore)
- Real-time messaging (Firebase Messaging)
- Storage (Firebase Storage)

## Technology Stack

### Frontend
- **Flutter**: Cross-platform mobile and web development framework
- **Dart**: Programming language for Flutter
- **Google Maps SDK**: Location visualization and mapping

### Backend
- **Firebase**: Backend-as-a-Service platform
  - Firebase Authentication: User authentication and authorization
  - Cloud Firestore: NoSQL document database
  - Firebase Cloud Messaging: Push notifications
  - Firebase Storage: File storage

### APIs & Services
- **OpenWeatherMap API**: Weather data for safety score calculation
- **Google Maps API**: Location services and map visualization

### Development Tools
- **Android Studio/VS Code**: IDE for development
- **Flutter SDK**: Development framework
- **Git**: Version control

## Key Features

### 1. User Authentication
- Role-based access (Tourist/Authority)
- Email/password authentication
- Secure session management

### 2. Tourist Dashboard
- Safety status monitoring
- Live location sharing
- Emergency contacts management
- Digital ID generation
- Itinerary planning

### 3. Authority Dashboard
- Tourist list view with status indicators
- Real-time map view of tourist locations
- Tourist detail view with emergency contacts
- QR code scanning for tourist verification
- Panic alert notifications with vibration

### 4. Safety Features
- Real-time weather-based safety scoring
- Panic button with immediate authority notification
- Location tracking with status indicators (Safe/At Risk/Panic)

## Data Flow

### 1. User Registration
```
Tourist/Authority → Firebase Auth → Cloud Firestore (User Data)
```

### 2. Location Tracking
```
Tourist App → Location Service → Cloud Firestore (live_locations collection)
Authority App → Cloud Firestore → Google Maps API → Map Visualization
```

### 3. Safety Status Updates
```
Tourist App → Location Service → OpenWeatherMap API → Safety Score Calculation
→ Cloud Firestore (Updated safety data)
```

### 4. Emergency Contacts
```
Tourist App → Cloud Firestore (emergencyContacts collection)
Authority App → Cloud Firestore → Tourist Detail View
```

### 5. Panic Alerts
```
Tourist App → Cloud Firestore (panic status update)
→ Firebase Messaging → Authority App (notification)
→ Vibration API (physical alert)
```

## Safety Score Calculation

The safety score is a numerical value between 0-100 that represents the current safety level of a tourist based on weather conditions.

### Factors Considered:
1. **Weather Conditions**:
   - Thunderstorms/Tornadoes: -60 points
   - Rain/Snow: -30 points
   - Mist/Fog: -20 points

2. **Wind Speed**:
   - Wind > 50 km/h: -40 points
   - Wind > 30 km/h: -20 points

### Calculation Algorithm:
```dart
int calculateSafetyScore(Map<String, dynamic>? weather) {
  if (weather == null) return 50;
  int score = 100;
  String weatherCondition = weather['weather'][0]['main'];
  double windSpeed = weather['wind']['speed'] * 3.6;

  // Weather condition penalties
  if (weatherCondition == 'Thunderstorm' || weatherCondition == 'Tornado') {
    score -= 60;
  } else if (weatherCondition == 'Rain' || weatherCondition == 'Snow') {
    score -= 30;
  } else if (weatherCondition == 'Mist' || weatherCondition == 'Fog') {
    score -= 20;
  }

  // Wind speed penalties
  if (windSpeed > 50) {
    score -= 40;
  } else if (windSpeed > 30) {
    score -= 20;
  }

  return score.clamp(0, 100);
}
```

### Safety Status Categories:
- **80-100**: Safe Zone
- **40-79**: Caution Zone
- **0-39**: High-Risk Area

## API Integrations

### 1. OpenWeatherMap API
- **Purpose**: Fetch real-time weather data for safety scoring
- **Endpoint**: `https://api.openweathermap.org/data/2.5/weather`
- **Parameters**: Latitude, Longitude, API Key
- **Response**: Weather conditions, temperature, wind speed

### 2. Google Maps API
- **Purpose**: Display tourist locations on map
- **Integration**: Google Maps Flutter SDK
- **Features**: 
  - Real-time location visualization
  - Marker customization based on status
  - Interactive map controls

### 3. Firebase APIs
- **Authentication API**: User login/logout
- **Firestore API**: Real-time database operations
- **Messaging API**: Push notifications for panic alerts

## Database Schema

### Collections

#### 1. users
```javascript
{
  "userId": {
    "fullName": "string",
    "email": "string",
    "phoneNumber": "string",
    "role": "tourist|authority",
    "aadharNumber": "string",
    "emergencyContacts": [
      {
        "name": "string",
        "phone": "string"
      }
    ],
    "itinerary": [
      {
        "day": "string",
        "plan": "string"
      }
    ]
  }
}
```

#### 2. live_locations
```javascript
{
  "userId": {
    "latitude": "number",
    "longitude": "number",
    "timestamp": "timestamp",
    "touristName": "string",
    "status": "tracking|panic"
  }
}
```

## Security Considerations

### 1. Authentication
- Firebase Authentication for secure user login
- Role-based access control (Tourist vs Authority)
- Session management and token validation

### 2. Data Protection
- End-to-end encryption for sensitive data
- Secure storage of personal information
- GDPR compliance for user data handling

### 3. Privacy
- Location data only shared when explicitly enabled by tourist
- Emergency contacts stored securely
- Opt-in for all data sharing features

### 4. Network Security
- HTTPS for all API communications
- Secure API key management
- Rate limiting to prevent abuse

## Deployment

### Mobile App Deployment
1. **Android**:
   - Build APK/AAB using Flutter
   - Upload to Google Play Store
   - Signing key management

2. **iOS**:
   - Build IPA using Xcode
   - Upload to Apple App Store
   - App Store Connect configuration

### Web Deployment
1. **Firebase Hosting**:
   - Build web app using `flutter build web`
   - Deploy to Firebase Hosting
   - Custom domain configuration

### Backend Configuration
1. **Firebase Project Setup**:
   - Enable Authentication providers
   - Configure Firestore security rules
   - Set up Cloud Messaging

2. **API Keys**:
   - Google Maps API key
   - OpenWeatherMap API key
   - Firebase configuration

### Continuous Integration/Deployment
- GitHub Actions for automated testing
- Firebase CLI for deployment
- Version control and release management

## Future Enhancements
1. Machine learning-based threat detection
2. Multi-language support
3. Offline functionality for remote areas
4. Integration with local emergency services
5. Social features for tourist communities