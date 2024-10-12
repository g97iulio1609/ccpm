// index.mjs

import { onCall, onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { setGlobalOptions } from 'firebase-functions/v2';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { google } from 'googleapis';
import Stripe from 'stripe';
import express from 'express';
import cors from 'cors';

// Imposta le opzioni globali
setGlobalOptions({ maxInstances: 10 });

// Inizializza Firebase Admin
initializeApp();

const firestore = getFirestore();
const auth = getAuth();

const packageName = 'com.alphaness.alphanessone';

// Inizializza Stripe utilizzando le variabili d'ambiente
const stripeSecretKey = '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'; // Sostituisci con la tua chiave segreta
const stripeWebhookSecret = 'whsec_Btsi8YKXYiM1OZA3FxEhVD2IImblVB0O'; // Sostituisci con il tuo segreto webhook

if (!stripeSecretKey || !stripeWebhookSecret) {
  throw new Error('Stripe secret keys are not set in environment variables.');
}

const stripe = new Stripe(stripeSecretKey, {
  apiVersion: '2024-06-20',
});

// Crea un'app Express per gestire i webhook
const app = express();

// Usa CORS per consentire richieste da tutte le origini (puoi restringere se necessario)
app.use(cors({ origin: true }));

// Middleware per ottenere il rawBody
app.use(express.raw({ type: 'application/json' }));

// Funzione per gestire gli eventi webhook di Stripe
app.post('/handleWebhookEvents', async (req, res) => {
  console.log('Webhook event received');

  const sig = req.headers['stripe-signature'];
  console.log(`Stripe Signature: ${sig}`);

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, stripeWebhookSecret);
    console.log(`Webhook event constructed successfully: ${event.type}`);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Gestisci diversi tipi di eventi
  switch (event.type) {
    case 'checkout.session.completed':
      console.log('Handling checkout.session.completed event');
      const session = event.data.object;
      await handleSuccessfulPayment(session);
      break;
    case 'customer.subscription.updated':
    case 'customer.subscription.deleted':
      console.log(`Handling ${event.type} event`);
      const subscription = event.data.object;
      await handleSubscriptionUpdate(subscription);
      break;
    // Aggiungi altri casi secondo necessità
    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  res.json({ received: true });
});

// Esporta l'app Express come una Cloud Function
export const handleWebhookEventsFunction = onRequest({ cors: true }, app);

// Funzione per eliminare un utente (admin only)
export const deleteUser = onCall({ maxInstances: 1 }, async (request) => {
  console.log('deleteUser function called');

  const callerUid = request.auth?.uid;
  console.log(`Caller UID: ${callerUid}`);

  if (!callerUid) {
    console.error('Unauthenticated request to deleteUser');
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated to delete users.');
  }

  const callerDoc = await firestore.collection('users').doc(callerUid).get();
  console.log(`Caller Document Exists: ${callerDoc.exists}, Role: ${callerDoc.data()?.role}`);

  if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
    console.error('Permission denied: Caller is not admin');
    throw new functions.https.HttpsError('permission-denied', 'Must be an admin to delete users.');
  }

  const uid = request.data.userId;
  console.log(`User ID to delete: ${uid}`);

  try {
    await auth.deleteUser(uid);
    console.log(`Stripe user ${uid} deleted successfully`);
    await firestore.collection('users').doc(uid).delete();
    console.log(`Firestore user ${uid} deleted successfully by admin ${callerUid}`);
    return { success: true };
  } catch (error) {
    console.error('Error deleting user:', error);
    throw new functions.https.HttpsError('internal', 'An error occurred while deleting the user.');
  }
});

// Funzione per creare una sessione di checkout con Stripe utilizzando stripePriceId esistente
export const createCheckoutSession = onCall(async (request) => {
  console.log('createCheckoutSession function called');
  console.log('Request data:', request.data);

  if (!request.auth) {
    console.error('Unauthenticated request to createCheckoutSession');
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated to create a checkout session.');
  }

  const { productId } = request.data;
  const userId = request.auth.uid;
  console.log(`Authenticated user ID: ${userId}`);
  console.log(`Product ID received: ${productId}`);

  try {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.error(`User not found: ${userId}`);
      throw new functions.https.HttpsError('not-found', 'User not found.');
    }

    const userData = userDoc.data();
    const userEmail = userData.email;
    console.log(`User email: ${userEmail}`);

    const productDoc = await firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) {
      console.error(`Product not found: ${productId}`);
      throw new functions.https.HttpsError('not-found', 'Product not found.');
    }

    const product = productDoc.data();
    console.log(`Product data retrieved:`, product);

    if (!product.stripePriceId) {
      console.error(`Product does not have a Stripe Price ID: ${productId}`);
      throw new functions.https.HttpsError('invalid-argument', 'Product does not have a Stripe Price ID.');
    }

    console.log(`Using Stripe Price ID: ${product.stripePriceId}`);

    // Crea un cliente Stripe con l'email dell'utente, se non esiste già
    let customer;
    console.log(`Searching for existing Stripe customer with email: ${userEmail}`);
    const existingCustomers = await stripe.customers.list({ email: userEmail, limit: 1 });
    if (existingCustomers.data.length > 0) {
      customer = existingCustomers.data[0];
      console.log(`Existing Stripe customer found: ${customer.id}`);
    } else {
      console.log(`No existing Stripe customer found. Creating new customer.`);
      customer = await stripe.customers.create({
        email: userEmail,
        metadata: { firebaseUid: userId },
      });
      console.log(`New Stripe customer created: ${customer.id}`);

      // Salva il customerId in Firestore
      await firestore.collection('users').doc(userId).update({
        stripeCustomerId: customer.id,
      });
      console.log(`stripeCustomerId ${customer.id} saved in Firestore for user ${userId}`);
    }

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{
        price: product.stripePriceId, // Utilizza l'ID del prezzo esistente
        quantity: 1,
      }],
      mode: 'subscription',
      success_url: 'https://yourapp.com/success',
      cancel_url: 'https://yourapp.com/cancel',
      customer: customer.id,
      client_reference_id: userId,
    });

    console.log(`Checkout session created successfully: ${session.id}`);
    console.log(`Checkout session URL: ${session.url}`);

    // Restituisci sia l'ID della sessione che l'URL
    return { sessionId: session.id, url: session.url };
  } catch (error) {
    console.error('Error creating checkout session:', error);
    throw new functions.https.HttpsError('internal', 'Unable to create checkout session');
  }
});

// Funzione per gestare pagamenti riusciti
async function handleSuccessfulPayment(session) {
  console.log('handleSuccessfulPayment called');
  const userId = session.client_reference_id;
  const subscriptionId = session.subscription;
  console.log(`User ID: ${userId}, Subscription ID: ${subscriptionId}`);

  try {
    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    console.log(`Retrieved subscription: ${subscription.id}, Status: ${subscription.status}`);
    const productId = subscription.items.data[0].price.product;
    console.log(`Product ID from subscription: ${productId}`);

    const productDoc = await firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) {
      console.error('Product not found in Firestore:', productId);
      return;
    }
    const product = productDoc.data();
    console.log('Product data:', product);

    const role = product.role || 'client_premium';
    console.log(`Assigning role: ${role} to user ${userId}`);

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

// Funzione per gestire aggiornamenti delle sottoscrizioni
async function handleSubscriptionUpdate(subscription) {
  console.log('handleSubscriptionUpdate called');
  try {
    const customerId = subscription.customer;
    console.log(`Subscription Customer ID: ${customerId}`);

    // Recupera il cliente Stripe per ottenere l'email
    const customer = await stripe.customers.retrieve(customerId);
    if (!customer || !customer.email) {
      console.error('Customer email not found for subscription:', subscription.id);
      return;
    }
    const userEmail = customer.email;
    console.log(`Customer email: ${userEmail}`);

    // Cerca l'utente in Firestore per email
    console.log(`Searching for Firestore user with email: ${userEmail}`);
    const usersSnapshot = await firestore.collection('users').where('email', '==', userEmail).get();

    if (usersSnapshot.empty) {
      console.error('No user found with email:', userEmail);
      return;
    }

    const userDoc = usersSnapshot.docs[0];
    const userId = userDoc.id;
    console.log(`Found Firestore user: ${userId}`);

    const productId = subscription.items.data[0].price.product;
    console.log(`Product ID from subscription: ${productId}`);

    const productDoc = await firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) {
      console.error('Product not found in Firestore:', productId);
      return;
    }
    const product = productDoc.data();
    console.log('Product data:', product);

    const role = product.role || 'client_premium';
    console.log(`Assigning role: ${role} to user ${userId}`);

    await firestore.collection('users').doc(userId).update({
      role: role,
      subscriptionId: subscription.id,
      subscriptionStatus: subscription.status,
      subscriptionProductId: productId,
      subscriptionPlatform: 'stripe',
      subscriptionStartDate: new Date(subscription.start_date * 1000),
      subscriptionExpiryDate: new Date(subscription.current_period_end * 1000),
    });

    console.log(`User ${userId} subscription updated to ${subscription.status}.`);
  } catch (error) {
    console.error('Error handling subscription update:', error);
  }
}

// Funzione schedulata per verificare e aggiornare le sottoscrizioni
export const checkAndUpdateSubscription = onSchedule('every 24 hours', async (context) => {
  console.log('checkAndUpdateSubscription triggered');
  try {
    const usersSnapshot = await firestore.collection('users').where('subscriptionStatus', '==', 'active').get();
    console.log(`Found ${usersSnapshot.size} active subscriptions to check`);

    const batch = firestore.batch();

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      console.log(`Checking subscription for user: ${userDoc.id}`);

      if (userData.subscriptionPlatform === 'stripe') {
        await checkStripeSubscription(userDoc, batch);
      } else if (userData.subscriptionPlatform === 'google_play') {
        await checkGooglePlaySubscription(userDoc, batch);
      } else {
        console.warn(`Unknown subscription platform for user ${userDoc.id}: ${userData.subscriptionPlatform}`);
      }
    }

    // Commit the batch
    await batch.commit();
    console.log('Subscription check and update completed successfully.');
  } catch (error) {
    console.error('Error in checkAndUpdateSubscription:', error);
  }
});

// Funzione per verificare le sottoscrizioni Stripe
async function checkStripeSubscription(userDoc, batch) {
  const userId = userDoc.id;
  const userData = userDoc.data();
  console.log(`Checking Stripe subscription for user: ${userId}, Subscription ID: ${userData.subscriptionId}`);

  try {
    const subscription = await stripe.subscriptions.retrieve(userData.subscriptionId);
    console.log(`Retrieved subscription: ${subscription.id}, Status: ${subscription.status}`);

    if (subscription.status === 'active') {
      const newExpiryDate = new Date(subscription.current_period_end * 1000);
      console.log(`Subscription is active. Updating expiry date to ${newExpiryDate}`);

      batch.update(userDoc.ref, {
        subscriptionExpiryDate: newExpiryDate
      });
      console.log(`Updated subscriptionExpiryDate for user ${userId}`);
    } else {
      console.log(`Subscription status is ${subscription.status}. Updating user to client.`);
      await updateUserToClient(userId, batch);
    }
  } catch (error) {
    console.error(`Error retrieving Stripe subscription for user ${userId}:`, error);
    console.log(`Updating user ${userId} to client due to error.`);
    await updateUserToClient(userId, batch);
  }
}

// Funzione per verificare le sottoscrizioni Google Play
async function checkGooglePlaySubscription(userDoc, batch) {
  const userId = userDoc.id;
  const userData = userDoc.data();
  console.log(`Checking Google Play subscription for user: ${userId}, Product ID: ${userData.productId}, Purchase Token: ${userData.purchaseToken}`);

  const isValid = await verifyGooglePlaySubscription(userData.purchaseToken, userData.productId);
  if (isValid) {
    const newExpiryDate = calculateNewExpiryDate();
    console.log(`Google Play subscription is valid. Updating expiry date to ${newExpiryDate}`);

    batch.update(userDoc.ref, {
      subscriptionExpiryDate: newExpiryDate
    });
    console.log(`Updated subscriptionExpiryDate for user ${userId}`);
  } else {
    console.log(`Google Play subscription is invalid. Updating user ${userId} to client.`);
    await updateUserToClient(userId, batch);
  }
}

// Funzione per verificare le sottoscrizioni Google Play tramite l'API di Google
async function verifyGooglePlaySubscription(purchaseToken, productId) {
  console.log(`Verifying Google Play subscription: productId=${productId}, purchaseToken=${purchaseToken}`);
  try {
    const authClient = await new google.auth.GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    }).getClient();

    const androidpublisher = google.androidpublisher('v3');
    const res = await androidpublisher.purchases.subscriptions.get({
      packageName: packageName,
      subscriptionId: productId,
      token: purchaseToken,
      auth: authClient,
    });

    console.log(`Google Play subscription verification response:`, res.data);
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
  console.log(`Calculated new expiry date: ${newDate}`);
  return newDate;
}

// Funzione per aggiornare l'utente a "client" in caso di sottoscrizione non valida
async function updateUserToClient(userId, batch) {
  console.log(`Updating user ${userId} to client role due to inactive/invalid subscription`);
  batch.update(firestore.collection('users').doc(userId), {
    role: 'client',
    subscriptionStatus: 'inactive',
    subscriptionExpiryDate: FieldValue.delete(),
    subscriptionId: FieldValue.delete(),
    subscriptionPlatform: FieldValue.delete(),
    subscriptionProductId: FieldValue.delete(),
    purchaseToken: FieldValue.delete(),
  });
  console.log(`User ${userId} updated to client successfully.`);
}

// Funzione schedulata per sincronizzare i prodotti Stripe
export const syncStripeProducts = onSchedule('every 24 hours', async (context) => {
  console.log('syncStripeProducts scheduled function triggered');
  try {
    await syncStripeProductsLogic();
    console.log('Stripe products synced successfully.');
  } catch (error) {
    console.error('Error syncing Stripe products:', error);
  }
});

// Funzione manuale per sincronizzare i prodotti Stripe (admin only)
export const manualSyncStripeProducts = onCall(async (request) => {
  console.log('manualSyncStripeProducts function called');

  if (!request.auth || !(await isAdmin(request.auth.uid))) {
    console.error('Unauthorized access to manualSyncStripeProducts');
    throw new functions.https.HttpsError('permission-denied', 'Unauthorized access');
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
  console.log(`Checking if user ${uid} is admin`);
  const userDoc = await firestore.collection('users').doc(uid).get();
  const isAdminUser = userDoc.exists && userDoc.data().role === 'admin';
  console.log(`User ${uid} is admin: ${isAdminUser}`);
  return isAdminUser;
}

// Logica per sincronizzare i prodotti Stripe con Firestore
async function syncStripeProductsLogic() {
  console.log('syncStripeProductsLogic started');
  try {
    const stripeProducts = await stripe.products.list({ active: true });
    console.log(`Fetched ${stripeProducts.data.length} active Stripe products`);

    const stripePrices = await stripe.prices.list({ active: true });
    console.log(`Fetched ${stripePrices.data.length} active Stripe prices`);

    const batch = firestore.batch();

    for (const product of stripeProducts.data) {
      const price = stripePrices.data.find(p => p.product === product.id);
      if (price) {
        const productRef = firestore.collection('products').doc(product.id);
        batch.set(productRef, {
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
        console.warn(`Price not found for product ${product.id}. Skipping.`);
      }
    }

    await batch.commit();
    console.log('All active Stripe products have been synchronized.');
  } catch (error) {
    console.error('Error in syncStripeProductsLogic:', error);
    throw error;
  }
}

// Funzione per sincronizzare tutte le sottoscrizioni Stripe
export const syncStripeSubscription = onCall(async (request) => {
  console.log('syncStripeSubscription function called');

  if (!request.auth) {
    console.error('Unauthenticated request to syncStripeSubscription');
    throw new functions.https.HttpsError('unauthenticated', 'Devi essere autenticato.');
  }

  const userId = request.auth.uid;
  const syncAll = request.data.syncAll || false;
  console.log(`User ID: ${userId}, syncAll: ${syncAll}`);

  try {
    if (syncAll) {
      // Verifica se l'utente è un admin
      const userDoc = await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.data().role !== 'admin') {
        console.error('Permission denied: User is not admin');
        throw new functions.https.HttpsError('permission-denied', 'Devi essere un admin per sincronizzare tutte le sottoscrizioni.');
      }

      console.log('Syncing all Stripe subscriptions as admin');

      // Sincronizza tutte le sottoscrizioni
      await syncAllStripeSubscriptions();
      console.log('All Stripe subscriptions have been synchronized successfully.');

      return { success: true, message: 'Tutte le sottoscrizioni sono state sincronizzate con successo.' };
    } else {
      // Sincronizza solo l'abbonamento dell'utente corrente
      const userDoc = await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        console.error(`User not found: ${userId}`);
        throw new functions.https.HttpsError('not-found', 'Utente non trovato.');
      }

      console.log(`Syncing subscription for user: ${userId}`);

      const batch = firestore.batch();
      const result = await syncUserSubscription(userId, userDoc.data().email, batch);
      console.log(`Subscription sync result for user ${userId}:`, result);

      await batch.commit();
      console.log(`Batch commit completed successfully for user ${userId}`);

      return result;
    }
  } catch (error) {
    console.error('Error syncing Stripe subscription:', error);
    throw new functions.https.HttpsError('internal', 'Errore nella sincronizzazione delle sottoscrizioni Stripe.');
  }
});

// Funzione per sincronizzare tutte le sottoscrizioni Stripe
async function syncAllStripeSubscriptions() {
  console.log('syncAllStripeSubscriptions started');

  try {
    let hasMore = true;
    let startingAfter = null;
    const limit = 100; // Numero massimo di sottoscrizioni per pagina

    const batch = firestore.batch();

    while (hasMore) {
      const params = { limit };
      if (startingAfter) {
        params.starting_after = startingAfter;
      }

      const subscriptions = await stripe.subscriptions.list(params);
      console.log(`Fetched ${subscriptions.data.length} subscriptions from Stripe`);

      for (const subscription of subscriptions.data) {
        const customer = await stripe.customers.retrieve(subscription.customer);
        if (!customer || !customer.email) {
          console.warn(`Customer email not found for subscription ${subscription.id}. Skipping.`);
          continue;
        }

        const userEmail = customer.email;
        console.log(`Mapping subscription ${subscription.id} to user with email ${userEmail}`);

        // Cerca l'utente in Firestore per email
        const usersSnapshot = await firestore.collection('users').where('email', '==', userEmail).get();

        if (usersSnapshot.empty) {
          console.warn(`No user found with email ${userEmail}. Skipping subscription ${subscription.id}.`);
          continue;
        }

        const userDoc = usersSnapshot.docs[0];
        const userId = userDoc.id;
        console.log(`Found Firestore user: ${userId} for subscription ${subscription.id}`);

        const productId = subscription.items.data[0].price.product;
        console.log(`Product ID from subscription: ${productId}`);

        const productDoc = await firestore.collection('products').doc(productId).get();
        if (!productDoc.exists) {
          console.error(`Product not found in Firestore: ${productId}. Skipping subscription ${subscription.id}.`);
          continue;
        }

        const product = productDoc.data();
        console.log('Product data:', product);

        const role = product.role || 'client_premium';
        console.log(`Assigning role: ${role} to user ${userId}`);

        batch.set(firestore.collection('users').doc(userId), {
          role: role,
          subscriptionId: subscription.id,
          subscriptionStatus: subscription.status,
          subscriptionProductId: productId,
          subscriptionPlatform: 'stripe',
          subscriptionStartDate: new Date(subscription.start_date * 1000),
          subscriptionExpiryDate: new Date(subscription.current_period_end * 1000),
        }, { merge: true });

        console.log(`Subscription ${subscription.id} mapped and scheduled for update for user ${userId}`);
      }

      hasMore = subscriptions.has_more;
      if (subscriptions.data.length > 0) {
        startingAfter = subscriptions.data[subscriptions.data.length - 1].id;
      }
    }

    await batch.commit();
    console.log('All Stripe subscriptions have been synchronized.');
  } catch (error) {
    console.error('Error in syncAllStripeSubscriptions:', error);
    throw error;
  }
}

// Funzione per sincronizzare l'abbonamento di un singolo utente
async function syncUserSubscription(userId, userEmail, batch) {
  console.log(`syncUserSubscription called for userId: ${userId}, email: ${userEmail}`);
  try {
    // Cerca il cliente Stripe basato sull'email
    console.log(`Searching for Stripe customer with email: ${userEmail}`);
    const customers = await stripe.customers.list({ email: userEmail, limit: 1 });

    if (customers.data.length === 0) {
      console.warn(`No Stripe customer found for user ${userId} with email ${userEmail}`);
      return { success: false, message: `Nessun abbonamento Stripe trovato per l'utente ${userId}.` };
    }

    const customer = customers.data[0];
    console.log(`Found Stripe customer: ${customer.id} for user ${userId}`);

    // Cerca le sottoscrizioni attive per questo cliente
    console.log(`Fetching active subscriptions for customer: ${customer.id}`);
    const subscriptions = await stripe.subscriptions.list({
      customer: customer.id,
      status: 'active',
      limit: 1,
    });

    if (subscriptions.data.length === 0) {
      console.warn(`No active subscription found for user ${userId}`);
      return { success: false, message: `Nessun abbonamento attivo trovato per l'utente ${userId}.` };
    }

    const subscription = subscriptions.data[0];
    console.log(`Found active subscription: ${subscription.id} for user ${userId}`);

    // Aggiorna i dati dell'utente in Firestore
    const userRef = firestore.collection('users').doc(userId);
    batch.update(userRef, {
      role: 'client_premium', // o 'coach' a seconda del prodotto
      subscriptionId: subscription.id,
      subscriptionStatus: 'active',
      subscriptionProductId: subscription.items.data[0].price.product,
      subscriptionPlatform: 'stripe',
      subscriptionStartDate: new Date(subscription.start_date * 1000),
      subscriptionExpiryDate: new Date(subscription.current_period_end * 1000),
    });

    console.log(`Subscription details updated in Firestore for user ${userId}`);

    return { 
      success: true, 
      message: `Abbonamento dell'utente ${userId} sincronizzato con successo.`,
      subscription: {
        id: subscription.id,
        status: subscription.status,
        current_period_end: subscription.current_period_end,
      }
    };
  } catch (error) {
    console.error(`Error syncing subscription for user ${userId}:`, error);
    return { success: false, message: `Errore sincronizzando l'abbonamento per l'utente ${userId}.` };
  }
}

// Funzione per ottenere i prodotti Stripe
export const getStripeProducts = onCall(async (request) => {
  console.log('getStripeProducts function called');
  console.log('Request auth:', request.auth); // Log solo la parte necessaria

  if (!request.auth) {
    console.warn('Unauthenticated request to getStripeProducts');
    // Procedi senza controllo di autenticazione se necessario
  } else {
    console.log(`Authenticated request by user: ${request.auth.uid}`);
  }

  try {
    console.log('Fetching products from Firestore...');
    const productsSnapshot = await firestore.collection('products').get();
    console.log(`Firestore query successful. Number of products fetched: ${productsSnapshot.size}`);

    const products = productsSnapshot.docs.map(doc => {
      const data = doc.data();
      console.log(`Product ID: ${doc.id}, Data: ${JSON.stringify(data)}`);
      return {
        id: doc.id,
        ...data
      };
    });

    console.log(`Returning products. Total products: ${products.length}`);
    return { products };
  } catch (error) {
    console.error('Error in getStripeProducts:', error);
    console.error('Error stack:', error.stack);
    throw new functions.https.HttpsError('internal', 'Unable to get products: ' + error.message);
  }
});

// Funzione di test per la connessione a Stripe
export const testStripeConnection = onCall(async (request) => {
  console.log('testStripeConnection function called');
  try {
    const balance = await stripe.balance.retrieve();
    console.log('Stripe connection successful. Balance:', balance);
    return { success: true, balance };
  } catch (error) {
    console.error('Stripe connection failed:', error);
    throw new functions.https.HttpsError('internal', 'Unable to connect to Stripe: ' + error.message);
  }
});

// Funzione per recuperare i dettagli della sottoscrizione dell'utente
export const getSubscriptionDetails = onCall(async (request) => {
  console.log('getSubscriptionDetails function called');

  if (!request.auth) {
    console.warn('Unauthenticated request to getSubscriptionDetails');
    throw new functions.https.HttpsError('unauthenticated', 'Devi essere autenticato.');
  }

  const userId = request.auth.uid;
  console.log(`Fetching subscription details for user: ${userId}`);

  try {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.error(`User not found: ${userId}`);
      throw new functions.https.HttpsError('not-found', 'Utente non trovato.');
    }

    const userData = userDoc.data();
    const subscriptionId = userData.subscriptionId;
    console.log(`Subscription ID: ${subscriptionId}`);

    if (!subscriptionId) {
      console.log(`User ${userId} has no subscription.`);
      return { hasSubscription: false };
    }

    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    console.log(`Retrieved subscription: ${subscription.id}, Status: ${subscription.status}`);

    return {
      hasSubscription: true,
      subscription: {
        id: subscription.id,
        status: subscription.status,
        current_period_end: subscription.current_period_end,
        items: subscription.items.data.map(item => ({
          priceId: item.price.id,
          productId: item.price.product,
          quantity: item.quantity,
        })),
      },
    };
  } catch (error) {
    console.error('Error getting subscription details:', error);
    throw new functions.https.HttpsError('internal', 'Errore nel recuperare i dettagli della sottoscrizione.');
  }
});

// Funzione per aggiornare la sottoscrizione dell'utente
export const updateSubscription = onCall(async (request) => {
  console.log('updateSubscription function called');

  if (!request.auth) {
    console.warn('Unauthenticated request to updateSubscription');
    throw new functions.https.HttpsError('unauthenticated', 'Devi essere autenticato.');
  }

  const userId = request.auth.uid;
  const { newPriceId } = request.data;
  console.log(`User ID: ${userId}, New Price ID: ${newPriceId}`);

  if (!newPriceId) {
    console.error('Missing newPriceId in request data');
    throw new functions.https.HttpsError('invalid-argument', 'Nuovo priceId richiesto.');
  }

  try {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.error(`User not found: ${userId}`);
      throw new functions.https.HttpsError('not-found', 'Utente non trovato.');
    }

    const userData = userDoc.data();
    const subscriptionId = userData.subscriptionId;
    console.log(`Current Subscription ID: ${subscriptionId}`);

    if (!subscriptionId) {
      console.error(`No subscription found for user: ${userId}`);
      throw new functions.https.HttpsError('not-found', 'Nessuna sottoscrizione trovata.');
    }

    // Recupera la sottoscrizione corrente
    const currentSubscription = await stripe.subscriptions.retrieve(subscriptionId);
    console.log(`Current Subscription retrieved: ${currentSubscription.id}, Status: ${currentSubscription.status}`);
    const currentItemId = currentSubscription.items.data[0].id;
    console.log(`Current Item ID: ${currentItemId}`);

    // Aggiorna la sottoscrizione con il nuovo priceId
    const updatedSubscription = await stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: false,
      proration_behavior: 'create_prorations',
      items: [{
        id: currentItemId,
        price: newPriceId,
      }],
    });
    console.log(`Subscription updated successfully: ${updatedSubscription.id}, New Status: ${updatedSubscription.status}`);

    // Aggiorna i dettagli nella Firestore
    await firestore.collection('users').doc(userId).update({
      subscriptionProductId: updatedSubscription.items.data[0].price.product,
      subscriptionExpiryDate: new Date(updatedSubscription.current_period_end * 1000),
      subscriptionStatus: updatedSubscription.status,
    });
    console.log(`Firestore subscription details updated for user ${userId}`);

    return { success: true, subscription: updatedSubscription };
  } catch (error) {
    console.error('Error updating subscription:', error);
    throw new functions.https.HttpsError('internal', 'Errore nell\'aggiornare la sottoscrizione.');
  }
});

// Funzione per ottenere i dettagli della sottoscrizione di un utente specifico (admin only)
export const getUserSubscriptionDetails = onCall(async (request) => {
  console.log('getUserSubscriptionDetails function called');

  // Verifica l'autenticazione
  if (!request.auth) {
    console.warn('Unauthenticated request to getUserSubscriptionDetails');
    throw new functions.https.HttpsError('unauthenticated', 'Devi essere autenticato.');
  }

  const callerUid = request.auth.uid;
  console.log(`Caller UID: ${callerUid}`);

  // Verifica se l'utente è admin
  const callerDoc = await firestore.collection('users').doc(callerUid).get();
  console.log(`Caller Document Exists: ${callerDoc.exists}, Role: ${callerDoc.data()?.role}`);

  if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
    console.error('Permission denied: Caller is not admin');
    throw new functions.https.HttpsError('permission-denied', 'Devi essere un admin per eseguire questa operazione.');
  }

  // Ottieni l'userId dalla richiesta
  const userId = request.data.userId;
  console.log(`User ID to fetch subscription details: ${userId}`);

  if (!userId) {
    console.error('Missing userId in request data');
    throw new functions.https.HttpsError('invalid-argument', 'Il parametro userId è richiesto.');
  }

  // Recupera i dettagli della sottoscrizione dell'utente
  try {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.error(`User not found: ${userId}`);
      throw new functions.https.HttpsError('not-found', 'Utente non trovato.');
    }

    const userData = userDoc.data();
    const subscriptionId = userData.subscriptionId;
    console.log(`Subscription ID for user ${userId}: ${subscriptionId}`);

    if (!subscriptionId) {
      console.log(`User ${userId} has no subscription.`);
      return { hasSubscription: false };
    }

    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    console.log(`Retrieved subscription: ${subscription.id}, Status: ${subscription.status}`);

    return {
      hasSubscription: true,
      subscription: {
        id: subscription.id,
        status: subscription.status,
        current_period_end: subscription.current_period_end,
        items: subscription.items.data.map(item => ({
          priceId: item.price.id,
          productId: item.price.product,
          quantity: item.quantity,
        })),
      },
    };
  } catch (error) {
    console.error('Error getting user subscription details:', error);
    throw new functions.https.HttpsError('internal', 'Errore nel recuperare i dettagli della sottoscrizione dell\'utente.');
  }
});

// Funzione per cancellare la sottoscrizione dell'utente
export const cancelSubscription = onCall(async (request) => {
  console.log('cancelSubscription function called');

  if (!request.auth) {
    console.warn('Unauthenticated request to cancelSubscription');
    throw new functions.https.HttpsError('unauthenticated', 'Devi essere autenticato.');
  }

  const userId = request.auth.uid;
  console.log(`Cancelling subscription for user: ${userId}`);

  try {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.error(`User not found: ${userId}`);
      throw new functions.https.HttpsError('not-found', 'Utente non trovato.');
    }

    const userData = userDoc.data();
    const subscriptionId = userData.subscriptionId;
    console.log(`Subscription ID to cancel: ${subscriptionId}`);

    if (!subscriptionId) {
      console.error(`No subscription found for user: ${userId}`);
      throw new functions.https.HttpsError('not-found', 'Nessuna sottoscrizione trovata.');
    }

    // Cancella la sottoscrizione su Stripe
    const canceledSubscription = await stripe.subscriptions.del(subscriptionId);
    console.log(`Stripe subscription ${subscriptionId} cancelled. Status: ${canceledSubscription.status}`);

    // Aggiorna Firestore
    await firestore.collection('users').doc(userId).update({
      subscriptionStatus: 'cancelled',
      subscriptionExpiryDate: new Date(canceledSubscription.current_period_end * 1000),
    });
    console.log(`Firestore updated: subscriptionStatus set to 'cancelled' for user ${userId}`);

    return { success: true };
  } catch (error) {
    console.error('Error cancelling subscription:', error);
    throw new functions.https.HttpsError('internal', 'Errore nel cancellare la sottoscrizione.');
  }
});

// Funzione per elencare tutte le sottoscrizioni dell'utente (opzionale)
export const listSubscriptions = onCall(async (request) => {
  console.log('listSubscriptions function called');

  if (!request.auth) {
    console.warn('Unauthenticated request to listSubscriptions');
    throw new functions.https.HttpsError('unauthenticated', 'Devi essere autenticato.');
  }

  const userId = request.auth.uid;
  console.log(`Listing subscriptions for user: ${userId}`);

  try {
    // Recupera l'email dell'utente
    const userDoc = await firestore.collection('users').doc(userId).get();
    const userData = userDoc.data();
    const userEmail = userData.email;
    console.log(`User email: ${userEmail}`);

    if (!userEmail) {
      console.error(`No email found for user: ${userId}`);
      throw new functions.https.HttpsError('not-found', 'Nessuna email trovata per l\'utente.');
    }

    // Cerca il cliente Stripe basato sull'email
    console.log(`Searching for Stripe customer with email: ${userEmail}`);
    const customers = await stripe.customers.list({ email: userEmail, limit: 1 });

    if (customers.data.length === 0) {
      console.warn(`No Stripe customer found for user ${userId} with email ${userEmail}`);
      throw new functions.https.HttpsError('not-found', 'Nessun customer trovato per l\'email dell\'utente.');
    }

    const customer = customers.data[0];
    const customerId = customer.id;
    console.log(`Found Stripe customer: ${customerId} for user ${userId}`);

    const subscriptions = await stripe.subscriptions.list({
      customer: customerId,
      status: 'all',
      expand: ['data.default_payment_method'],
    });
    console.log(`Fetched ${subscriptions.data.length} subscriptions for customer ${customerId}`);

    return {
      subscriptions: subscriptions.data.map(sub => ({
        id: sub.id,
        status: sub.status,
        current_period_end: sub.current_period_end,
        items: sub.items.data.map(item => ({
          priceId: item.price.id,
          productId: item.price.product,
          quantity: item.quantity,
        })),
      })),
    };
  } catch (error) {
    console.error('Error listing subscriptions:', error);
    throw new functions.https.HttpsError('internal', 'Errore nel recuperare le sottoscrizioni.');
  }
});
