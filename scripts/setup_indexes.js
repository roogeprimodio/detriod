const admin = require('firebase-admin');
const serviceAccount = require('./frenzy-10e49-firebase-adminsdk-us849-6b3dcb03f3.json');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function setupIndexes() {
  try {
    const indexesPath = path.join(__dirname, '..', 'firestore.indexes.json');
    const indexesConfig = JSON.parse(fs.readFileSync(indexesPath, 'utf8'));
    
    console.log('Creating indexes...');
    
    // Get Firestore instance
    const db = admin.firestore();
    
    // Create each index
    for (const index of indexesConfig.indexes) {
      console.log(`Creating index for collection: ${index.collectionGroup}`);
      console.log('Fields:', JSON.stringify(index.fields, null, 2));
      
      try {
        // Note: This is a workaround as the admin SDK doesn't have direct index creation
        // In practice, you'll need to use the Firebase CLI (firebase deploy --only firestore:indexes)
        // or the Cloud Firestore API directly
        
        // Create a dummy query that will trigger index creation
        const query = db.collection(index.collectionGroup);
        let chainedQuery = query;
        
        for (const field of index.fields) {
          if (field.arrayConfig === 'CONTAINS') {
            chainedQuery = chainedQuery.where(field.fieldPath, 'array-contains', 'dummy');
          } else {
            chainedQuery = chainedQuery.orderBy(field.fieldPath, field.order.toLowerCase());
          }
        }
        
        // Execute query to trigger index creation
        await chainedQuery.limit(1).get();
        
        console.log(`Index creation triggered for ${index.collectionGroup}`);
      } catch (error) {
        if (error.code === 9 && error.message.includes('requires an index')) {
          console.log(`Index creation request sent for ${index.collectionGroup}`);
        } else {
          console.error(`Error creating index for ${index.collectionGroup}:`, error);
        }
      }
    }
    
    console.log('\nIMPORTANT: To complete index creation, please run:');
    console.log('firebase deploy --only firestore:indexes');
    console.log('\nThis will deploy all indexes defined in firestore.indexes.json');
    
  } catch (error) {
    console.error('Error setting up indexes:', error);
  } finally {
    process.exit(0);
  }
}

setupIndexes();
