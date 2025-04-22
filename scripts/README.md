# Firebase Collections Setup Script

This script automatically sets up all the required collections for the esports app in Firebase.

## Prerequisites

1. Node.js installed on your system
2. Firebase Admin SDK credentials

## Setup Instructions

1. Install dependencies:
```bash
npm install firebase-admin
```

2. Get your Firebase Admin SDK credentials:
   - Go to Firebase Console
   - Navigate to Project Settings
   - Go to Service Accounts tab
   - Click "Generate New Private Key"
   - Save the downloaded file as `serviceAccountKey.json` in this directory

3. Run the script:
```bash
node setup_firebase_collections.js
```

## What This Script Does

Creates the following collections with sample data:
1. Games
2. Matches
3. Match Registrations
4. Notifications
5. Transactions

Each collection is created with proper schema and sample data to get you started.

## After Running

1. Check your Firebase Console to verify the collections are created
2. Update the sample data with your actual data
3. The script adds relationships between collections (e.g., matching IDs for games and matches)
