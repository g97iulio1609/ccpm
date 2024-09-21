// index.mjs
import { onCall, onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { setGlobalOptions } from 'firebase-functions/v2';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { google } from 'googleapis';
import Stripe from 'stripe';

// Set global options
setGlobalOptions({ maxInstances: 10 });

// Initialize Firebase Admin
initializeApp();

const firestore = getFirestore();
const auth = getAuth();

const packageName = 'com.alphaness.alphanessone';

// Inizializza Stripe con chiave API direttamente nel codice (NON SICURO per produzione)
const stripeSecretKey = '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'; // Sostituisci con la tua chiave segreta
const stripeWebhookSecret = 'whsec_Btsi8YKXYiM1OZA3FxEhVD2IImblVB0O'; // Sostituisci con il tuo segreto webhook

const stripe = new Stripe(stripeSecretKey, {
  apiVersion: '2024-06-20',
});

// Funzione per eliminare un utente (admin only)
export const deleteUser = onCall({ maxInstances: 1 }, async (request) => {
  const callerUid = request.auth?.uid;

  if (!callerUid) {
    throw new Error('Must be authenticated to delete users.');
  }

  const callerDoc = await firestore.collection('users').doc(callerUid).get();

  if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
    throw new Error('Must be an admin to delete users.');
  }

  const uid = request.data.userId;

  try {
    await auth.deleteUser(uid);
    await firestore.collection('users').doc(uid).delete();
    console.log(`User ${uid} deleted successfully by admin ${callerUid}.`);
    return { success: true };
  } catch (error) {
    console.error('Error deleting user:', error);
    throw new Error('An error occurred while deleting the user.');
  }
});

// Funzione per creare una sessione di checkout con Stripe
export const createCheckoutSession = onCall(async (request) => {
  if (!request.auth) {
    throw new Error('Must be authenticated to create a checkout session.');
  }

  const { productId } = request.data;
  const userId = request.auth.uid;

  try {
    const productDoc = await firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) {
      throw new Error('Product not found');
    }
    const product = productDoc.data();

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{
        price_data: {
          currency: product.currency,
          product_data: {
            name: product.name,
          },
          unit_amount: product.price * 100, // Converti in centesimi per Stripe
        },
        quantity: 1,
      }],
      mode: 'subscription',
      success_url: 'https://yourapp.com/success',
      cancel_url: 'https://yourapp.com/cancel',
      client_reference_id: userId,
    });

    console.log(`Checkout session created for user ${userId}: ${session.id}`);
    return { sessionId: session.id };
  } catch (error) {
    console.error('Error creating checkout session:', error);
    throw new Error('Unable to create checkout session');
  }
});

// Funzione per gestire gli eventi webhook di Stripe
export const handleWebhookEvents = onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, stripeWebhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    await handleSuccessfulPayment(session);
  }

  res.json({ received: true });
});

// Funzione per gestire pagamenti riusciti
async function handleSuccessfulPayment(session) {
  const userId = session.client_reference_id;
  const subscriptionId = session.subscription;

  try {
    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    const productId = subscription.items.data[0].price.product;

    const productDoc = await firestore.collection('products').doc(productId).get();
    const product = productDoc.data();

    if (!product) {
      console.error('Product not found:', productId);
      return;
    }

    const role = product.role || 'client_premium';

    await firestore.collection('users').doc(userId).update({
      role: role,
      subscriptionId: subscriptionId,
      subscriptionStatus: 'active',
      subscriptionProductId: productId,
      subscriptionPlatform: 'stripe',
      subscriptionStartDate: new Date(),
      subscriptionExpiryDate: new Date(subscription.current_period_end * 1000),
    });

    console.log(`User ${userId} subscription updated to active.`);
  } catch (error) {
    console.error('Error handling successful payment:', error);
  }
}

// Funzione schedulata per verificare e aggiornare le sottoscrizioni
export const checkAndUpdateSubscription = onSchedule('every 24 hours', async (context) => {
  try {
    const usersSnapshot = await firestore.collection('users').where('subscriptionStatus', '==', 'active').get();

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      
      if (userData.subscriptionPlatform === 'stripe') {
        await checkStripeSubscription(userDoc);
      } else if (userData.subscriptionPlatform === 'google_play') {
        await checkGooglePlaySubscription(userDoc);
      }
    }

    console.log('Subscription check and update completed.');
  } catch (error) {
    console.error('Error in checkAndUpdateSubscription:', error);
  }
});

// Funzione per verificare le sottoscrizioni Stripe
async function checkStripeSubscription(userDoc) {
  const userData = userDoc.data();
  try {
    const subscription = await stripe.subscriptions.retrieve(userData.subscriptionId);
    if (subscription.status === 'active') {
      await userDoc.ref.update({
        subscriptionExpiryDate: new Date(subscription.current_period_end * 1000)
      });
      console.log(`Subscription for user ${userDoc.id} is active. Updated expiry date.`);
    } else {
      await updateUserToClient(userDoc.id);
      console.log(`Subscription for user ${userDoc.id} is not active. Updated to client.`);
    }
  } catch (error) {
    console.error('Error checking Stripe subscription:', error);
    await updateUserToClient(userDoc.id);
  }
}

// Funzione per verificare le sottoscrizioni Google Play
async function checkGooglePlaySubscription(userDoc) {
  const userData = userDoc.data();
  const isValid = await verifyGooglePlaySubscription(userData.purchaseToken, userData.productId);
  if (isValid) {
    const newExpiryDate = calculateNewExpiryDate();
    await userDoc.ref.update({
      subscriptionExpiryDate: newExpiryDate
    });
    console.log(`Subscription for user ${userDoc.id} is valid. Updated expiry date.`);
  } else {
    await updateUserToClient(userDoc.id);
    console.log(`Subscription for user ${userDoc.id} is invalid. Updated to client.`);
  }
}

// Funzione per verificare le sottoscrizioni Google Play tramite l'API di Google
async function verifyGooglePlaySubscription(purchaseToken, productId) {
  try {
    const auth = new google.auth.GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });

    const authClient = await auth.getClient();
    google.options({ auth: authClient });

    const androidpublisher = google.androidpublisher('v3');
    const res = await androidpublisher.purchases.subscriptions.get({
      packageName: packageName,
      subscriptionId: productId,
      token: purchaseToken,
    });

    return res.data && res.data.expiryTimeMillis > Date.now();
  } catch (error) {
    console.error('Error verifying Google Play subscription:', error);
    return false;
  }
}

// Funzione per calcolare la nuova data di scadenza
function calculateNewExpiryDate() {
  const newDate = new Date();
  newDate.setMonth(newDate.getMonth() + 1);
  return newDate;
}

// Funzione per aggiornare l'utente a "client" in caso di sottoscrizione non valida
async function updateUserToClient(userId) {
  try {
    await firestore.collection('users').doc(userId).update({
      role: 'client',
      subscriptionStatus: 'inactive',
      subscriptionExpiryDate: null,
      subscriptionId: null,
      subscriptionPlatform: null,
      subscriptionProductId: null,
      purchaseToken: null,
    });
    console.log(`User ${userId} updated to client.`);
  } catch (error) {
    console.error('Error updating user to client:', error);
  }
}

// Funzione schedulata per sincronizzare i prodotti Stripe
export const syncStripeProducts = onSchedule('every 24 hours', async (context) => {
  try {
    await syncStripeProductsLogic();
    console.log('Stripe products synced successfully.');
  } catch (error) {
    console.error('Error syncing Stripe products:', error);
  }
});

// Funzione manuale per sincronizzare i prodotti Stripe (admin only)
export const manualSyncStripeProducts = onCall(async (request) => {
  if (!request.auth || !(await isAdmin(request.auth.uid))) {
    throw new Error('Unauthorized access');
  }

  try {
    await syncStripeProductsLogic();
    console.log('Manual sync of Stripe products completed successfully.');
    return { success: true, message: 'Products synced successfully' };
  } catch (error) {
    console.error('Error in manual sync:', error);
    return { success: false, message: error.message };
  }
});

// Funzione per verificare se un utente è admin
async function isAdmin(uid) {
  const userDoc = await firestore.collection('users').doc(uid).get();
  return userDoc.exists && userDoc.data().role === 'admin';
}

// Logica per sincronizzare i prodotti Stripe con Firestore
async function syncStripeProductsLogic() {
  try {
    const stripeProducts = await stripe.products.list({ active: true });
    const stripePrices = await stripe.prices.list({ active: true });

    for (const product of stripeProducts.data) {
      const price = stripePrices.data.find(p => p.product === product.id);
      if (price) {
        await firestore.collection('products').doc(product.id).set({
          name: product.name,
          description: product.description,
          price: price.unit_amount / 100, // Dividi per 100 per ottenere il prezzo nella valuta principale
          currency: price.currency,
          stripeProductId: product.id,
          stripePriceId: price.id,
          role: product.metadata.role || 'client_premium',
        }, { merge: true });
        console.log(`Product ${product.id} synchronized successfully.`);
      } else {
        console.warn(`Price not found for product ${product.id}.`);
      }
    }

    console.log('All active Stripe products have been synchronized.');
  } catch (error) {
    console.error('Error in syncStripeProductsLogic:', error);
    throw error;
  }
}

// Funzione per ottenere i prodotti Stripe
export const getStripeProducts = onCall(async (request) => {
  console.log('getStripeProducts function called');
  console.log('Context auth:', request.auth); // Log solo la parte necessaria

  if (!request.auth) {
    console.log('Context or auth is undefined');
    console.log('Data received:', request.data); // Log solo i dati necessari
    // Procedi senza controllo di autenticazione se necessario
    console.log('Proceeding without authentication check');
  } else if (!request.auth.uid) {
    console.log('Authentication check failed');
    throw new Error('Must be authenticated to get products.');
  }

  try {
    console.log('Fetching products from Firestore...');
    const productsSnapshot = await firestore.collection('products').get();
    console.log('Firestore query successful. Number of products:', productsSnapshot.size);

    const products = productsSnapshot.docs.map(doc => {
      const data = doc.data();
      console.log('Product data:', data);
      return {
        id: doc.id,
        ...data
      };
    });

    console.log('Returning products. Total products:', products.length);
    return { products };
  } catch (error) {
    console.error('Error in getStripeProducts:', error);
    console.error('Error stack:', error.stack);
    throw new Error(`Unable to get products: ${error.message}`);
  }
});

// Funzione di test per la connessione a Stripe
export const testStripeConnection = onCall(async (request) => {
  try {
    const balance = await stripe.balance.retrieve();
    console.log('Stripe connection successful. Balance:', balance);
    return { success: true, balance };
  } catch (error) {
    console.error('Stripe connection failed:', error);
    throw new Error('Unable to connect to Stripe: ' + error.message);
  }
});
