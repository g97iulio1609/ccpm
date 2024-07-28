import { onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { setGlobalOptions } from 'firebase-functions/v2';
import admin from 'firebase-admin';
import { google } from 'googleapis';

// Set global options
setGlobalOptions({ maxInstances: 10 });

// Percorso al file di credenziali nella cartella functions
const serviceAccountKeyFile = './serviceAccountKeyFile.json';

// Inizializza l'app Firebase Admin con il file delle credenziali
admin.initializeApp({
  credential: admin.credential.cert(serviceAccountKeyFile),
  databaseURL: "https://alphaness-322423.firebaseio.com"
});

const firestore = admin.firestore();
const _auth = admin.auth();

const packageName = 'com.alphaness.alphanessone';

export const deleteUser = onCall({ maxInstances: 1 }, async (request) => {
  const callerUid = request.auth.uid;
  const callerDoc = await firestore.collection('users').doc(callerUid).get();

  if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
    throw new Error('Must be an admin to delete users.');
  }

  const uid = request.data.userId;

  try {
    await _auth.deleteUser(uid);
    await firestore.collection('users').doc(uid).delete();
    return { success: true };
  } catch (error) {
    console.error('Error deleting user:', error);
    throw new Error('An error occurred while deleting the user.');
  }
});

export const checkAndUpdateSubscription = onSchedule('every 24 hours', async (context) => {
  const usersRef = firestore.collection('users');
  const usersSnapshot = await usersRef.where('role', 'in', ['client_premium', 'coach']).get();

  for (const userDoc of usersSnapshot.docs) {
    const userData = userDoc.data();
    const expiryDate = userData.subscriptionExpiryDate.toDate();
    const now = new Date();

    if (expiryDate < now) {
      const isValid = await verifySubscription(userData.purchaseToken, userData.productId);
      if (isValid) {
        const newExpiryDate = calculateNewExpiryDate();
        await userDoc.ref.update({
          subscriptionExpiryDate: admin.firestore.Timestamp.fromDate(newExpiryDate)
        });
      } else {
        await userDoc.ref.update({
          role: 'client',
          subscriptionExpiryDate: null
        });
      }
    }
  }

  return null;
});

async function verifySubscription(purchaseToken, productId) {
  try {
    const auth = new google.auth.GoogleAuth({
      keyFile: serviceAccountKeyFile,
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });

    const authClient = await auth.getClient();
    google.options({ auth: authClient });

    const playDeveloperApi = google.androidpublisher('v3');
    const res = await playDeveloperApi.purchases.subscriptions.get({
      packageName: packageName,
      subscriptionId: productId,
      token: purchaseToken,
    });

    return res.data && res.data.expiryTimeMillis > Date.now();
  } catch (error) {
    console.error('Error verifying subscription:', error);
    return false;
  }
}

function calculateNewExpiryDate() {
  const newDate = new Date();
  newDate.setMonth(newDate.getMonth() + 1);
  return newDate;
}