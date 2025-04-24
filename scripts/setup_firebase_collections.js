const admin = require('firebase-admin');
const serviceAccount = require('./frenzy-10e49-firebase-adminsdk-us849-6b3dcb03f3.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function setupCollections() {
  try {
    // Sample data for each collection
    const sampleGame = {
      title: 'PUBG Mobile',
      description: 'Battle Royale game for mobile devices',
      genre: 'Battle Royale',
      imageUrl: 'https://example.com/pubg.jpg',
      bannerUrl: 'https://example.com/pubg-banner.jpg',
      rating: 4.5,
      platforms: ['Mobile', 'PC'],
      requirements: {
        minimum: 'Android 5.1.1 or above',
        recommended: 'Android 7.1.2 or above'
      },
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: 'admin',
      totalMatches: 0,
      activeTournaments: 0
    };

    const sampleMatch = {
      title: 'PUBG Mobile Championship',
      gameId: 'game_id_placeholder',
      description: 'Monthly championship tournament',
      rules: 'Standard tournament rules apply',
      date: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
      time: '14:00',
      timeZone: 'UTC+5:30',
      streamInfo: {
        platform: 'YouTube',
        streamUrl: 'https://youtube.com/watch?v=example',
        isLive: false,
        viewerCount: 0
      },
      format: 'Single Elimination',
      prizePool: 1000,
      entryFee: 50,
      maxParticipants: 100,
      currentParticipants: 0,
      platforms: ['Mobile'],
      location: {
        venue: 'Online',
        address: 'N/A',
        isOnline: true
      },
      registrationEndDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 6 * 24 * 60 * 60 * 1000)),
      registeredUsers: [],
      status: 'upcoming',
      isActive: true,
      bracketUrl: '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      startedAt: null,
      endedAt: null
    };

    const sampleRegistration = {
      userId: 'user_id_placeholder',
      matchId: 'match_id_placeholder',
      matchTitle: 'PUBG Mobile Championship',
      inGameName: 'PlayerOne',
      teamName: 'Team Alpha',
      platform: 'Mobile',
      status: 'pending',
      registeredAt: admin.firestore.FieldValue.serverTimestamp(),
      checkedInAt: null,
      paymentStatus: 'pending',
      paymentId: '',
      transactionId: '',
      amount: 50,
      rank: null,
      score: 0,
      eliminated: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const sampleNotification = {
      userId: 'user_id_placeholder',
      title: 'Tournament Registration Open',
      message: 'Registration for PUBG Mobile Championship is now open!',
      type: 'tournament_update',
      matchId: 'match_id_placeholder',
      gameId: 'game_id_placeholder',
      actionUrl: 'esports://matches/match_id_placeholder',
      isRead: false,
      metadata: {
        startTime: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
        prizeAmount: 1000
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 14 * 24 * 60 * 60 * 1000))
    };

    const sampleTransaction = {
      userId: 'user_id_placeholder',
      type: 'entry_fee',
      amount: 50,
      currency: 'USD',
      matchId: 'match_id_placeholder',
      registrationId: 'registration_id_placeholder',
      status: 'pending',
      paymentMethod: 'card',
      paymentId: '',
      metadata: {},
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    // Create collections with sample data
    console.log('Creating game collection...');
    const gameRef = await db.collection('games').add(sampleGame);
    console.log('Game created with ID:', gameRef.id);

    // Update match with actual game ID
    sampleMatch.gameId = gameRef.id;
    console.log('Creating match collection...');
    const matchRef = await db.collection('matches').add(sampleMatch);
    console.log('Match created with ID:', matchRef.id);

    // Update registration with actual match ID
    sampleRegistration.matchId = matchRef.id;
    console.log('Creating match_registrations collection...');
    const registrationRef = await db.collection('match_registrations').add(sampleRegistration);
    console.log('Registration created with ID:', registrationRef.id);

    // Update notification with actual IDs
    sampleNotification.matchId = matchRef.id;
    sampleNotification.gameId = gameRef.id;
    console.log('Creating notifications collection...');
    const notificationRef = await db.collection('notifications').add(sampleNotification);
    console.log('Notification created with ID:', notificationRef.id);

    // Update transaction with actual IDs
    sampleTransaction.matchId = matchRef.id;
    sampleTransaction.registrationId = registrationRef.id;
    console.log('Creating transactions collection...');
    const transactionRef = await db.collection('transactions').add(sampleTransaction);
    console.log('Transaction created with ID:', transactionRef.id);

    console.log('All collections created successfully!');
  } catch (error) {
    console.error('Error setting up collections:', error);
  } finally {
    process.exit(0);
  }
}

setupCollections();
