# Queue Management System

A Flutter web application for managing queues in a bun shop. Customers can scan QR codes to join queues, view their position, and admins can manage multiple queues efficiently.

## Features

- ✅ **Multiple Queues**: Create and manage multiple queues simultaneously
- ✅ **QR Code Integration**: Each queue has a unique QR code for easy customer access
- ✅ **Real-time Updates**: All screens update in real-time using Firebase Firestore
- ✅ **Customer Interface**: Join queue with name and quantity, view position and estimated wait time
- ✅ **Admin Dashboard**: Manage queue members, mark as served, skip tokens
- ✅ **Public Display**: Large screen display showing current token being served
- ✅ **Mobile Responsive**: Works on all devices

## Setup Instructions

### 1. Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Click on the gear icon (Project Settings)
4. Scroll down to "Your apps" section
5. If you haven't added a web app, click "Add app" and select Web (</>) icon
6. Copy the configuration values

### 2. Enable Firestore Database

1. In Firebase Console, go to "Firestore Database" in the left menu
2. Click "Create database"
3. Choose "Start in test mode" for development (or production mode with security rules)
4. Select a location and click "Enable"

### 3. Update Firebase Config

Open `lib/main.dart` and replace the Firebase configuration (around line 12):

```dart
const firebaseOptions = FirebaseOptions(
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID",
);
```

### 4. Run the Application

```bash
# Get dependencies (already done)
flutter pub get

# Run on Chrome (for development)
flutter run -d chrome

# Build for web deployment
flutter build web
```

## Usage

### Creating a Queue

1. Open the home page
2. Enter a queue name (e.g., "Morning Batch")
3. Click "Create Queue"
4. You'll be redirected to the admin page

### Admin Panel

- **QR Code**: Display and print the QR code for customers to scan
- **Statistics**: View current token, waiting count, and total served
- **Queue Members**: See all members with their token numbers
- **Mark as Served**: Click to serve the current customer
- **Skip**: Skip a customer's token

### Customer Flow

1. Scan the QR code or visit the join URL
2. Enter your name and quantity
3. Receive your token number
4. View your position in queue and estimated wait time
5. Wait for your turn (page updates automatically)

### Public Display

- Access via the "Display" button on home page
- Shows current token being served in large font
- Perfect for TV/monitor display
- Updates in real-time

## Project Structure

```
lib/
├── main.dart                 # App entry point & Firebase config
├── models/
│   └── queue_model.dart      # Data models
├── screens/
│   ├── home_screen.dart      # Landing page & queue creation
│   ├── admin_screen.dart     # Admin dashboard
│   ├── join_queue_screen.dart # Customer join interface
│   └── display_screen.dart   # Public display
├── services/
│   └── firebase_service.dart # Firebase operations
└── theme/
    └── app_theme.dart        # App theming
```

## Firestore Database Structure

```
queues/
  {queueId}/
    name: string
    createdAt: timestamp
    currentToken: number
    totalServed: number
    averageServeTime: number (seconds)
    status: "active"

    members/
      {memberId}/
        name: string
        quantity: number
        tokenNumber: number
        status: "waiting" | "served" | "skipped"
        joinedAt: timestamp
        servedAt: timestamp (optional)
        skippedAt: timestamp (optional)
```

## Firebase Security Rules (Optional)

For production, add these rules in Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /queues/{queueId} {
      allow read: if true;
      allow create: if true;
      allow update: if true;

      match /members/{memberId} {
        allow read: if true;
        allow create: if true;
        allow update: if true;
      }
    }
  }
}
```

## Deployment

### Deploy to Firebase Hosting

```bash
# Build the web app
flutter build web

# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init hosting

# Deploy
firebase deploy
```

### Deploy to Other Platforms

The built web app is in the `build/web` directory. You can deploy it to:

- Vercel
- Netlify
- GitHub Pages
- Any static hosting service

## Troubleshooting

### Firebase not initializing

- Check that you've replaced the Firebase configuration in `lib/main.dart`
- Ensure Firestore is enabled in Firebase Console

### QR Code not working

- Make sure you're accessing the app via a proper URL (not `localhost` for production)
- Check that the URL in the QR code is correct

### Real-time updates not working

- Verify Firestore security rules allow read/write
- Check browser console for errors

## License

This project is open source and available for personal and commercial use.
