// Firebase Configuration
// Replace the values below with your Firebase project credentials
// You can find these in your Firebase Console > Project Settings > General > Your apps

const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID",
};

// Initialize Firebase
let app, db;

try {
  app = firebase.initializeApp(firebaseConfig);
  db = firebase.firestore();
  console.log("Firebase initialized successfully");
} catch (error) {
  console.error("Error initializing Firebase:", error);
  alert("Firebase configuration error. Please check firebase-config.js");
}

/*
SETUP INSTRUCTIONS:
1. Go to https://console.firebase.google.com/
2. Select your project
3. Click on the gear icon (Project Settings)
4. Scroll down to "Your apps" section
5. If you haven't added a web app, click "Add app" and select Web (</>) icon
6. Copy the configuration values and replace the placeholders above
7. Make sure Firestore Database is enabled in your Firebase project:
   - Go to Firestore Database in the left menu
   - Click "Create database"
   - Choose "Start in test mode" for development (or production mode with security rules)
   - Select a location and click "Enable"
*/
