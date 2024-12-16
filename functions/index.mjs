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
setGlobalOptions({ 
  maxInstances: 10,
  region: 'europe-west1'
});

// Inizializza Firebase Admin
initializeApp();

const firestore = getFirestore();
const auth = getAuth();

const packageName = 'com.alphaness.alphanessone';

// Inizializza Stripe utilizzando le variabili d'ambiente
//const stripeSecretKey = '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'; 
const stripeSecretKey = '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'; 

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
  const sig = req.headers['stripe-signature'];

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, stripeWebhookSecret);
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Gestisci diversi tipi di eventi
  switch (event.type) {
    case 'checkout.session.completed':
      const session = event.data.object;
      await handleWebhookPayment(session);
      break;
    case 'customer.subscription.updated':
    case 'customer.subscription.deleted':
      const subscription = event.data.object;
      await handleSubscriptionUpdate(subscription);
      break;
    // Aggiungi altri casi secondo necessità
    default:
  }

  res.json({ received: true });
});

// Esporta l'app Express come una Cloud Function
export const handleWebhookEventsFunction = onRequest({ 
  cors: true,
  region: 'europe-west1' 
}, app);

// Funzione per eliminare un utente (admin only)
export const deleteUser = onRequest({ 
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  // Imposta gli header CORS
  response.set('Access-Control-Allow-Origin', '*');
  response.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  response.set('Access-Control-Max-Age', '3600');

  // Gestisci le richieste OPTIONS
  if (request.method === 'OPTIONS') {
    response.status(204).send('');
    return;
  }

  try {
    const { userId } = request.body;
    const callerUid = request.body.callerUid;

    if (!callerUid) {
      response.status(401).json({ error: 'Must be authenticated to delete users.' });
      return;
    }

    const callerDoc = await firestore.collection('users').doc(callerUid).get();

    if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
      response.status(403).json({ error: 'Must be an admin to delete users.' });
      return;
    }

    await auth.deleteUser(userId);
    await firestore.collection('users').doc(userId).delete();
    response.json({ success: true });
  } catch (error) {
    response.status(500).json({ error: 'An error occurred while deleting the user.' });
  }
});

// Funzione per creare una sessione di checkout con Stripe
export const createCheckoutSession = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  // Imposta gli header CORS
  response.set('Access-Control-Allow-Origin', '*');
  response.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  response.set('Access-Control-Max-Age', '3600');

  // Gestisci le richieste OPTIONS
  if (request.method === 'OPTIONS') {
    response.status(204).send('');
    return;
  }

  try {
    const { productId, userId } = request.body;

    if (!userId) {
      response.status(401).json({ error: 'Must be authenticated to create a checkout session.' });
      return;
    }

    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      response.status(404).json({ error: 'User not found.' });
      return;
    }

    const userData = userDoc.data();
    const userEmail = userData.email;

    const productDoc = await firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) {
      response.status(404).json({ error: 'Product not found.' });
      return;
    }

    const product = productDoc.data();

    if (!product.stripePriceId) {
      response.status(400).json({ error: 'Product does not have a Stripe Price ID.' });
      return;
    }

    let customer;
    const existingCustomers = await stripe.customers.list({ email: userEmail, limit: 1 });
    if (existingCustomers.data.length > 0) {
      customer = existingCustomers.data[0];
    } else {
      customer = await stripe.customers.create({
        email: userEmail,
        metadata: { firebaseUid: userId },
      });

      await firestore.collection('users').doc(userId).update({
        stripeCustomerId: customer.id,
      });
    }

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{
        price: product.stripePriceId,
        quantity: 1,
      }],
      mode: 'subscription',
      success_url: 'https://yourapp.com/success',
      cancel_url: 'https://yourapp.com/cancel',
      customer: customer.id,
      client_reference_id: userId,
    });

    response.json({ sessionId: session.id, url: session.url });
  } catch (error) {
    response.status(500).json({ error: 'Unable to create checkout session' });
  }
});

// Funzione per gestire i pagamenti dai webhook
async function handleWebhookPayment(session) {
  const userId = session.client_reference_id;
  const subscriptionId = session.subscription;

  try {
    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    const productId = subscription.items.data[0].price.product;

    const productDoc = await firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) {
      return;
    }
    const product = productDoc.data();

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
  } catch (error) {
    console.error('Errore nel gestire il pagamento webhook:', error);
  }
}

// Funzione per gestire aggiornamenti delle sottoscrizioni
async function handleSubscriptionUpdate(subscription) {
  try {
    const customerId = subscription.customer;

    // Recupera il cliente Stripe per ottenere l'email
    const customer = await stripe.customers.retrieve(customerId);
    if (!customer || !customer.email) {
      return;
    }
    const userEmail = customer.email;

    // Cerca l'utente in Firestore per email
    const usersSnapshot = await firestore.collection('users').where('email', '==', userEmail).get();

    if (usersSnapshot.empty) {
      return;
    }

    const userDoc = usersSnapshot.docs[0];
    const userId = userDoc.id;

    const productId = subscription.items.data[0].price.product;

    const productDoc = await firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) {
      return;
    }
    const product = productDoc.data();

    const role = product.role || 'client_premium';

    await firestore.collection('users').doc(userId).update({
      role: role,
      subscriptionId: subscription.id,
      subscriptionStatus: subscription.status,
      subscriptionProductId: productId,
      subscriptionPlatform: 'stripe',
      subscriptionStartDate: new Date(subscription.start_date * 1000),
      subscriptionExpiryDate: new Date(subscription.current_period_end * 1000),
    });
  } catch (error) {
  }
}

// Funzione schedulata per verificare e aggiornare le sottoscrizioni
export const checkAndUpdateSubscription = onSchedule('every 24 hours', async (context) => {
  try {
    const usersSnapshot = await firestore.collection('users').where('subscriptionStatus', '==', 'active').get();

    const batch = firestore.batch();

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();

      if (userData.subscriptionPlatform === 'stripe') {
        await checkStripeSubscription(userDoc, batch);
      } else if (userData.subscriptionPlatform === 'google_play') {
        await checkGooglePlaySubscription(userDoc, batch);
      } else {
      }
    }

    // Commit the batch
    await batch.commit();
  } catch (error) {
  }
});

// Funzione per verificare le sottoscrizioni Stripe
async function checkStripeSubscription(userDoc, batch) {
  const userId = userDoc.id;
  const userData = userDoc.data();

  try {
    const subscription = await stripe.subscriptions.retrieve(userData.subscriptionId);

    if (subscription.status === 'active') {
      const newExpiryDate = new Date(subscription.current_period_end * 1000);

      batch.update(userDoc.ref, {
        subscriptionExpiryDate: newExpiryDate
      });
    } else {
      await updateUserToClient(userId, batch);
    }
  } catch (error) {
    await updateUserToClient(userId, batch);
  }
}

// Funzione per verificare le sottoscrizioni Google Play
async function checkGooglePlaySubscription(userDoc, batch) {
  const userId = userDoc.id;
  const userData = userDoc.data();

  const isValid = await verifyGooglePlaySubscription(userData.purchaseToken, userData.productId);
  if (isValid) {
    const newExpiryDate = calculateNewExpiryDate();

    batch.update(userDoc.ref, {
      subscriptionExpiryDate: newExpiryDate
    });
  } else {
    await updateUserToClient(userId, batch);
  }
}

// Funzione per verificare le sottoscrizioni Google Play tramite l'API di Google
async function verifyGooglePlaySubscription(purchaseToken, productId) {
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

    return res.data && res.data.expiryTimeMillis > Date.now();
  } catch (error) {
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
async function updateUserToClient(userId, batch) {
  batch.update(firestore.collection('users').doc(userId), {
    role: 'client',
    subscriptionStatus: 'inactive',
    subscriptionExpiryDate: FieldValue.delete(),
    subscriptionId: FieldValue.delete(),
    subscriptionPlatform: FieldValue.delete(),
    subscriptionProductId: FieldValue.delete(),
    purchaseToken: FieldValue.delete(),
  });
}

// Funzione schedulata per sincronizzare i prodotti Stripe
export const syncStripeProducts = onSchedule('every 24 hours', async (context) => {
  try {
    await syncStripeProductsLogic();
  } catch (error) {
  }
});

// Funzione manuale per sincronizzare i prodotti Stripe (admin only)
export const manualSyncStripeProducts = onCall(async (request) => {
  if (!request.auth || !(await isAdmin(request.auth.uid))) {
    throw new functions.https.HttpsError('permission-denied', 'Unauthorized access');
  }

  try {
    await syncStripeProductsLogic();
    return { success: true, message: 'Products synced successfully' };
  } catch (error) {
    return { success: false, message: error.message };
  }
});

// Funzione per verificare se un utente è admin
async function isAdmin(uid) {
  const userDoc = await firestore.collection('users').doc(uid).get();
  const isAdminUser = userDoc.exists && userDoc.data().role === 'admin';
  return isAdminUser;
}

// Logica per sincronizzare i prodotti Stripe con Firestore
async function syncStripeProductsLogic() {
  try {
    const stripeProducts = await stripe.products.list({ active: true });

    const stripePrices = await stripe.prices.list({ active: true });

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
      } else {
      }
    }

    await batch.commit();
  } catch (error) {
    throw error;
  }
}

// Funzione per sincronizzare tutte le sottoscrizioni Stripe
export const syncStripeSubscription = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  // Imposta gli header CORS
  response.set('Access-Control-Allow-Origin', '*');
  response.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  response.set('Access-Control-Max-Age', '3600');

  // Gestisci le richieste OPTIONS
  if (request.method === 'OPTIONS') {
    response.status(204).send('');
    return;
  }

  try {
    const { userId, syncAll } = request.body;

    if (!userId) {
      response.status(401).json({ error: 'Devi essere autenticato.' });
      return;
    }

    if (syncAll) {
      // Verifica se l'utente è un admin
      const userDoc = await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.data().role !== 'admin') {
        response.status(403).json({ error: 'Devi essere un admin per sincronizzare tutte le sottoscrizioni.' });
        return;
      }

      // Sincronizza tutte le sottoscrizioni
      await syncAllStripeSubscriptions();
      response.json({ success: true, message: 'Tutte le sottoscrizioni sono state sincronizzate con successo.' });
    } else {
      // Sincronizza solo l'abbonamento dell'utente corrente
      const userDoc = await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        response.status(404).json({ error: 'Utente non trovato.' });
        return;
      }

      const batch = firestore.batch();
      const result = await syncUserSubscription(userId, userDoc.data().email, batch);
      await batch.commit();

      response.json(result);
    }
  } catch (error) {
    response.status(500).json({ error: 'Errore nella sincronizzazione delle sottoscrizioni Stripe: ' + error.message });
  }
});

// Funzione per sincronizzare tutte le sottoscrizioni Stripe
async function syncAllStripeSubscriptions() {
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

      for (const subscription of subscriptions.data) {
        const customer = await stripe.customers.retrieve(subscription.customer);
        if (!customer || !customer.email) {
          continue;
        }

        const userEmail = customer.email;

        // Cerca l'utente in Firestore per email
        const usersSnapshot = await firestore.collection('users').where('email', '==', userEmail).get();

        if (usersSnapshot.empty) {
          continue;
        }

        const userDoc = usersSnapshot.docs[0];
        const userId = userDoc.id;

        const productId = subscription.items.data[0].price.product;

        const productDoc = await firestore.collection('products').doc(productId).get();
        if (!productDoc.exists) {
          continue;
        }
        const product = productDoc.data();

        const role = product.role || 'client_premium';

        batch.set(firestore.collection('users').doc(userId), {
          role: role,
          subscriptionId: subscription.id,
          subscriptionStatus: subscription.status,
          subscriptionProductId: productId,
          subscriptionPlatform: 'stripe',
          subscriptionStartDate: new Date(subscription.start_date * 1000),
          subscriptionExpiryDate: new Date(subscription.current_period_end * 1000),
        }, { merge: true });
      }

      hasMore = subscriptions.has_more;
      if (subscriptions.data.length > 0) {
        startingAfter = subscriptions.data[subscriptions.data.length - 1].id;
      }
    }

    await batch.commit();
  } catch (error) {
    throw error;
  }
}

// Funzione per sincronizzare l'abbonamento di un singolo utente
async function syncUserSubscription(userId, userEmail, batch) {
  try {
    // Cerca il cliente Stripe basato sull'email
    const customers = await stripe.customers.list({ email: userEmail, limit: 1 });

    if (customers.data.length === 0) {
      return { success: false, message: `Nessun abbonamento Stripe trovato per l'utente ${userId}.` };
    }

    const customer = customers.data[0];

    // Cerca le sottoscrizioni attive per questo cliente
    const subscriptions = await stripe.subscriptions.list({
      customer: customer.id,
      status: 'active',
      limit: 1,
    });

    if (subscriptions.data.length === 0) {
      return { success: false, message: `Nessun abbonamento attivo trovato per l'utente ${userId}.` };
    }

    const subscription = subscriptions.data[0];

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
    return { success: false, message: `Errore sincronizzando l'abbonamento per l'utente ${userId}.` };
  }
}

// Funzione per ottenere i prodotti Stripe
export const getStripeProducts = onRequest({ 
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  // Imposta gli header CORS
  response.set('Access-Control-Allow-Origin', '*');
  response.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  response.set('Access-Control-Max-Age', '3600');

  // Gestisci le richieste OPTIONS
  if (request.method === 'OPTIONS') {
    response.status(204).send('');
    return;
  }

  try {
    const productsSnapshot = await firestore.collection('products').get();

    const products = productsSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data
      };
    });

    response.json({ products });
  } catch (error) {
    response.status(500).json({ error: 'Unable to get products: ' + error.message });
  }
});

// Funzione di test per la connessione a Stripe
export const testStripeConnection = onCall({
  region: 'europe-west1'
}, async (request) => {
  try {
    const balance = await stripe.balance.retrieve();
    return { success: true, balance };
  } catch (error) {
    throw new functions.https.HttpsError('internal', 'Unable to connect to Stripe: ' + error.message);
  }
});

// Funzione per ottenere i dettagli della sottoscrizione
export const getSubscriptionDetails = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  // Imposta gli header CORS
  response.set('Access-Control-Allow-Origin', '*');
  response.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  response.set('Access-Control-Max-Age', '3600');

  // Gestisci le richieste OPTIONS
  if (request.method === 'OPTIONS') {
    response.status(204).send('');
    return;
  }

  try {
    // Verifica il token di autenticazione
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      response.status(401).json({ error: 'Token di autenticazione mancante o non valido.' });
      return;
    }

    const idToken = authHeader.split('Bearer ')[1];
    const decodedToken = await auth.verifyIdToken(idToken);
    const authenticatedUserId = decodedToken.uid;

    // Ottieni l'userId dalla richiesta o usa quello autenticato
    const { userId } = request.body;
    const targetUserId = userId || authenticatedUserId;

    // Se l'utente richiede i dettagli di un altro utente, verifica che sia admin
    if (userId && userId !== authenticatedUserId) {
      const adminDoc = await firestore.collection('users').doc(authenticatedUserId).get();
      if (!adminDoc.exists || adminDoc.data().role !== 'admin') {
        response.status(403).json({ error: 'Non hai i permessi per visualizzare i dettagli di questo utente.' });
        return;
      }
    }

    const userDoc = await firestore.collection('users').doc(targetUserId).get();
    if (!userDoc.exists) {
      response.status(404).json({ error: 'Utente non trovato.' });
      return;
    }

    const userData = userDoc.data();
    const subscriptionId = userData.subscriptionId;

    if (!subscriptionId) {
      response.json({ hasSubscription: false });
      return;
    }

    const subscription = await stripe.subscriptions.retrieve(subscriptionId);

    response.json({
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
    });
  } catch (error) {
    console.error('Errore in getSubscriptionDetails:', error);
    if (error.code === 'auth/id-token-expired' || error.code === 'auth/argument-error') {
      response.status(401).json({ error: 'Token di autenticazione non valido o scaduto.' });
    } else {
      response.status(500).json({ error: 'Errore nel recuperare i dettagli della sottoscrizione.' });
    }
  }
});

// Funzione per aggiornare la sottoscrizione
export const updateSubscription = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  // Imposta gli header CORS
  response.set('Access-Control-Allow-Origin', '*');
  response.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  response.set('Access-Control-Max-Age', '3600');

  // Gestisci le richieste OPTIONS
  if (request.method === 'OPTIONS') {
    response.status(204).send('');
    return;
  }

  try {
    const { userId, newPriceId } = request.body;

    if (!userId) {
      response.status(401).json({ error: 'Devi essere autenticato.' });
      return;
    }

    if (!newPriceId) {
      response.status(400).json({ error: 'Nuovo priceId richiesto.' });
      return;
    }

    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      response.status(404).json({ error: 'Utente non trovato.' });
      return;
    }

    const userData = userDoc.data();
    const subscriptionId = userData.subscriptionId;

    if (!subscriptionId) {
      response.status(404).json({ error: 'Nessuna sottoscrizione trovata.' });
      return;
    }

    const currentSubscription = await stripe.subscriptions.retrieve(subscriptionId);
    const currentItemId = currentSubscription.items.data[0].id;

    const updatedSubscription = await stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: false,
      proration_behavior: 'create_prorations',
      items: [{
        id: currentItemId,
        price: newPriceId,
      }],
    });

    await firestore.collection('users').doc(userId).update({
      subscriptionProductId: updatedSubscription.items.data[0].price.product,
      subscriptionExpiryDate: new Date(updatedSubscription.current_period_end * 1000),
      subscriptionStatus: updatedSubscription.status,
    });

    response.json({ success: true, subscription: updatedSubscription });
  } catch (error) {
    response.status(500).json({ error: 'Errore nell\'aggiornare la sottoscrizione.' });
  }
});

// Funzione per ottenere i dettagli della sottoscrizione di un utente specifico (admin only)
export const getUserSubscriptionDetails = onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Devi essere autenticato.');
  }

  const callerUid = request.auth.uid;

  // Verifica se l'utente è admin
  const callerDoc = await firestore.collection('users').doc(callerUid).get();

  if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Devi essere un admin per eseguire questa operazione.');
  }

  // Ottieni l'userId dalla richiesta
  const userId = request.data.userId;

  if (!userId) {
    throw new functions.https.HttpsError('invalid-argument', 'Il parametro userId è richiesto.');
  }

  // Recupera i dettagli della sottoscrizione dell'utente
  try {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Utente non trovato.');
    }

    const userData = userDoc.data();
    const subscriptionId = userData.subscriptionId;

    if (!subscriptionId) {
      return { hasSubscription: false };
    }

    const subscription = await stripe.subscriptions.retrieve(subscriptionId);

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
    throw new functions.https.HttpsError('internal', 'Errore nel recuperare i dettagli della sottoscrizione dell\'utente.');
  }
});

// Funzione per cancellare la sottoscrizione
export const cancelSubscription = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  // Imposta gli header CORS
  response.set('Access-Control-Allow-Origin', '*');
  response.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  response.set('Access-Control-Max-Age', '3600');

  // Gestisci le richieste OPTIONS
  if (request.method === 'OPTIONS') {
    response.status(204).send('');
    return;
  }

  try {
    const { userId } = request.body;

    if (!userId) {
      response.status(401).json({ error: 'Devi essere autenticato.' });
      return;
    }

    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      response.status(404).json({ error: 'Utente non trovato.' });
      return;
    }

    const userData = userDoc.data();
    const subscriptionId = userData.subscriptionId;

    if (!subscriptionId) {
      response.status(404).json({ error: 'Nessuna sottoscrizione trovata.' });
      return;
    }

    const canceledSubscription = await stripe.subscriptions.del(subscriptionId);

    await firestore.collection('users').doc(userId).update({
      subscriptionStatus: 'cancelled',
      subscriptionExpiryDate: new Date(canceledSubscription.current_period_end * 1000),
    });

    response.json({ success: true });
  } catch (error) {
    response.status(500).json({ error: 'Errore nel cancellare la sottoscrizione.' });
  }
});

// Funzione per elencare tutte le sottoscrizioni dell'utente (opzionale)
export const listSubscriptions = onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Devi essere autenticato.');
  }

  const userId = request.auth.uid;

  try {
    // Recupera l'email dell'utente
    const userDoc = await firestore.collection('users').doc(userId).get();
    const userData = userDoc.data();
    const userEmail = userData.email;

    if (!userEmail) {
      throw new functions.https.HttpsError('not-found', 'Nessuna email trovata per l\'utente.');
    }

    // Cerca il cliente Stripe basato sull'email
    const customers = await stripe.customers.list({ email: userEmail, limit: 1 });

    if (customers.data.length === 0) {
      throw new functions.https.HttpsError('not-found', 'Nessun customer trovato per l\'email dell\'utente.');
    }

    const customer = customers.data[0];
    const customerId = customer.id;

    const subscriptions = await stripe.subscriptions.list({
      customer: customerId,
      status: 'all',
      expand: ['data.default_payment_method'],
    });

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
    throw new functions.https.HttpsError('internal', 'Errore nel recuperare le sottoscrizioni.');
  }
});

// Funzione per creare un abbonamento regalo
export const createGiftSubscription = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  // Imposta gli header CORS
  response.set('Access-Control-Allow-Origin', '*');
  response.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  response.set('Access-Control-Max-Age', '3600');

  // Gestisci le richieste OPTIONS
  if (request.method === 'OPTIONS') {
    response.status(204).send('');
    return;
  }

  try {
    const { adminUid, userId, durationInDays } = request.body;

    // Verify admin status
    const adminDoc = await firestore.collection('users').doc(adminUid).get();
    if (!adminDoc.exists || adminDoc.data().role !== 'admin') {
      response.status(403).json({ error: 'Only admins can create gift subscriptions.' });
      return;
    }

    // Get user document
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      response.status(404).json({ error: 'User not found.' });
      return;
    }

    // Calculate subscription dates
    const startDate = new Date();
    const expiryDate = new Date(startDate.getTime() + durationInDays * 24 * 60 * 60 * 1000);

    // Update user document with gift subscription
    await firestore.collection('users').doc(userId).update({
      role: 'client_premium',
      subscriptionStatus: 'active',
      subscriptionPlatform: 'gift',
      subscriptionStartDate: startDate,
      subscriptionExpiryDate: expiryDate,
      giftedBy: adminUid,
      giftedAt: startDate,
    });

    response.json({
      success: true,
      message: 'Gift subscription created successfully',
    });
  } catch (error) {
    response.status(500).json({ error: 'Error creating gift subscription: ' + error.message });
  }
});

// Funzione per gestire il pagamento riuscito
export const handleSuccessfulPayment = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  // Imposta gli header CORS
  response.set('Access-Control-Allow-Origin', '*');
  response.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  response.set('Access-Control-Max-Age', '3600');

  // Gestisci le richieste OPTIONS
  if (request.method === 'OPTIONS') {
    response.status(204).send('');
    return;
  }

  try {
    const { paymentId, productId, userId } = request.body;

    if (!userId) {
      response.status(401).json({ error: 'Devi essere autenticato.' });
      return;
    }

    const paymentIntent = await stripe.paymentIntents.retrieve(paymentId);
    if (paymentIntent.status !== 'succeeded') {
      response.status(400).json({ error: 'Il pagamento non è stato completato con successo.' });
      return;
    }

    const productDoc = await firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) {
      response.status(404).json({ error: 'Prodotto non trovato.' });
      return;
    }

    const product = productDoc.data();

    // Calcola la data di scadenza (1 mese o 1 anno a seconda del prodotto)
    const now = new Date();
    const expiryDate = new Date(now);
    if (productId.includes('yearly')) {
      expiryDate.setFullYear(expiryDate.getFullYear() + 1);
    } else {
      expiryDate.setMonth(expiryDate.getMonth() + 1);
    }

    // Aggiorna l'utente con i dettagli dell'abbonamento
    await firestore.collection('users').doc(userId).update({
      role: 'client_premium',
      subscriptionStatus: 'active',
      subscriptionPlatform: 'stripe',
      subscriptionStartDate: now,
      subscriptionExpiryDate: expiryDate,
      subscriptionProductId: productId,
      lastPaymentId: paymentId,
      lastPaymentDate: now,
    });

    response.json({ success: true });
  } catch (error) {
    response.status(500).json({ error: 'Errore nella gestione del pagamento: ' + error.message });
  }
});
