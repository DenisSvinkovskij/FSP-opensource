# find_safe_places

A new Flutter project.

## Getting Started

#### Firebase base configuration
1. Add Firebase to your existing Google Cloud project:
a. Log in to the Firebase console, then click Add project.
b. Select your existing Google Cloud project from the dropdown menu, then click Continue.
c. (Optional) Enable Google Analytics for your project, then follow the prompts to select or create a Google Analytics account.
d. Click Add Firebase.

2. Add Firebase to your app by following the platform-specific guide:
a. Flutter: https://firebase.google.com/docs/flutter/setup
b. Apple platforms: https://firebase.google.com/docs/ios/setup
c. Android: https://firebase.google.com/docs/android/setup
d. Web: https://firebase.google.com/docs/web/setup

Add flutter app by following steps at https://console.firebase.google.com/project/{YOUR_PROJECT_ID}/overview 
To initialize firebase uncomment lines 17,40,41,42 in lib/main.dart

3. Enable authentication for your Firebase project to use Firestore:
a. In the Firebase console, click Authentication from the navigation panel.
b. Go to the Sign-in Method tab.
c. Enable Email/Password and Google authentication.

Then Configure SHA-1 certificate and download google-services.json in project settings
a. Go to android folder 'cd android'
b. Run command './gradlew signingreport'

- Enable firestore in you app
- In cloud console enable service - Google Cloud Firestore API
- replace all "com.example.find_safe_places" to your own unique Application ID you can find it in your firebase app settings https://console.firebase.google.com/project/{YOUR_PROJECT_ID}/settings/general 

#### Mapbox settings
1. Add your public key in lib/constants/map.dart
2. Create secret key with scopes DOWNLOAD:READ, MAP:READ, OFFLINE:READ
3. Add secret download token in /android/gradle.properties file

Run - flutter pub get
Run - flutter run