import { onRequest, onCall } from 'firebase-functions/v2/https';
import { SubscriptionService } from '../services/subscriptionService.mjs';
import { AuthMiddleware } from '../middleware/auth.mjs';
import { ResponseHandler } from '../utils/responseHandler.mjs';
import { stripe, stripeWebhookSecret } from '../config/stripe.mjs';
import { firestore, auth } from '../config/firebase.mjs';
import express from 'express';
import cors from 'cors';

const app = express();
app.use(cors({ origin: true }));
app.use(express.raw({ type: 'application/json' }));

// Webhook handler
app.post('/handleWebhookEvents', async (req, res) => {
  const sig = req.headers['stripe-signature'];

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, stripeWebhookSecret);
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  try {
    // Gestisci diversi tipi di eventi
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object;
        await handleWebhookPayment(session);
        break;
      }
      case 'customer.subscription.updated':
      case 'customer.subscription.deleted': {
        await handleSubscriptionUpdate(event.data.object);
        break;
      }
      default:
        console.log(`Unhandled event type ${event.type}`);
    }

    res.json({ received: true });
  } catch (error) {
    console.error('Error processing webhook:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

async function handleSubscriptionUpdate(subscription) {
  try {
    const customerId = subscription.customer;
    const customer = await stripe.customers.retrieve(customerId);
    
    if (!customer?.email) {
      return;
    }
    
    const usersSnapshot = await firestore.collection('users')
      .where('email', '==', customer.email)
      .get();

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
      role,
      subscriptionId: subscription.id,
      subscriptionStatus: subscription.status,
      subscriptionProductId: productId,
      subscriptionPlatform: 'stripe',
      subscriptionStartDate: new Date(subscription.start_date * 1000),
      subscriptionExpiryDate: new Date(subscription.current_period_end * 1000),
    });
  } catch (error) {
    console.error('Error in handleSubscriptionUpdate:', error);
  }
}

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

// Esporta l'app Express come una Cloud Function
export const handleWebhookEventsFunction = onRequest({ 
  cors: true,
  region: 'europe-west1' 
}, app);

export const createCheckoutSession = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  if (request.method === 'OPTIONS') return ResponseHandler.handleOptions(response);

  try {
    const { userId, productId } = request.body;
    if (!userId) return ResponseHandler.unauthorized(response);

    await AuthMiddleware.verifyUser(userId);
    const session = await SubscriptionService.createCheckoutSession(userId, productId);
    ResponseHandler.success(response, session);
  } catch (error) {
    ResponseHandler.error(response, error);
  }
});

export const cancelSubscription = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  if (request.method === 'OPTIONS') return ResponseHandler.handleOptions(response);

  try {
    const { userId } = request.body;
    if (!userId) return ResponseHandler.unauthorized(response);

    await AuthMiddleware.verifyUser(userId);
    const result = await SubscriptionService.cancelSubscription(userId);
    ResponseHandler.success(response, result);
  } catch (error) {
    ResponseHandler.error(response, error);
  }
});

export const updateSubscription = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  if (request.method === 'OPTIONS') return ResponseHandler.handleOptions(response);

  try {
    const { userId, newPriceId } = request.body;
    if (!userId || !newPriceId) return ResponseHandler.unauthorized(response);

    await AuthMiddleware.verifyUser(userId);
    const result = await SubscriptionService.updateSubscription(userId, newPriceId);
    ResponseHandler.success(response, result);
  } catch (error) {
    ResponseHandler.error(response, error);
  }
});

export const getSubscriptionDetails = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  if (request.method === 'OPTIONS') {
    return ResponseHandler.handleOptions(response);
  }

  try {
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      response.status(401).json({ error: 'Token di autenticazione mancante o non valido.' });
      return;
    }

    const idToken = authHeader.split('Bearer ')[1];
    const decodedToken = await auth.verifyIdToken(idToken);
    const authenticatedUserId = decodedToken.uid;

    const { userId } = request.body;
    const targetUserId = userId || authenticatedUserId;

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

export const createGiftSubscription = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  if (request.method === 'OPTIONS') return ResponseHandler.handleOptions(response);

  try {
    const { adminUid, userId, durationInDays } = request.body;
    await AuthMiddleware.verifyAdmin(adminUid);
    await AuthMiddleware.verifyUser(userId);

    const result = await SubscriptionService.createGiftSubscription(adminUid, userId, durationInDays);
    ResponseHandler.success(response, result);
  } catch (error) {
    ResponseHandler.error(response, error);
  }
});

export const handleSuccessfulPayment = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  if (request.method === 'OPTIONS') return ResponseHandler.handleOptions(response);

  try {
    const { paymentId, productId, userId } = request.body;
    if (!userId) return ResponseHandler.unauthorized(response);

    await AuthMiddleware.verifyUser(userId);
    const result = await SubscriptionService.handleSuccessfulPayment(paymentId, productId, userId);
    ResponseHandler.success(response, result);
  } catch (error) {
    ResponseHandler.error(response, error);
  }
});

export const listSubscriptions = onCall({
  region: 'europe-west1'
}, async (request) => {
  if (!request.auth) {
    throw new Error('Devi essere autenticato.');
  }

  try {
    const subscriptions = await SubscriptionService.listUserSubscriptions(request.auth.uid);
    return { subscriptions };
  } catch (error) {
    throw new Error(`Errore nel recuperare le sottoscrizioni: ${error.message}`);
  }
});

export const testStripeConnection = onCall({
  region: 'europe-west1'
}, async () => {
  try {
    const balance = await stripe.balance.retrieve();
    return { success: true, balance };
  } catch (error) {
    throw new Error(`Unable to connect to Stripe: ${error.message}`);
  }
});

export const syncStripeSubscription = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  if (request.method === 'OPTIONS') return ResponseHandler.handleOptions(response);

  try {
    const { userId, syncAll } = request.body;

    if (!userId) {
      return ResponseHandler.unauthorized(response);
    }

    if (syncAll) {
      await AuthMiddleware.verifyAdmin(userId);
      const result = await SubscriptionService.syncAllSubscriptions();
      ResponseHandler.success(response, result);
    } else {
      const userDoc = await AuthMiddleware.verifyUser(userId);
      const batch = firestore.batch();
      const result = await SubscriptionService.syncUserSubscription(userId, userDoc.data().email);
      await batch.commit();
      ResponseHandler.success(response, result);
    }
  } catch (error) {
    ResponseHandler.error(response, error);
  }
});

export const getUserSubscriptionDetails = onCall({
  region: 'europe-west1'
}, async (request) => {
  if (!request.auth) {
    throw new Error('Devi essere autenticato.');
  }

  const callerUid = request.auth.uid;
  const adminDoc = await firestore.collection('users').doc(callerUid).get();

  if (!adminDoc.exists || adminDoc.data().role !== 'admin') {
    throw new Error('Devi essere un admin per eseguire questa operazione.');
  }

  const userId = request.data.userId;
  if (!userId) {
    throw new Error('Il parametro userId è richiesto.');
  }

  try {
    return await SubscriptionService.getUserSubscriptionDetails(userId);
  } catch (error) {
    throw new Error(`Errore nel recuperare i dettagli della sottoscrizione dell'utente: ${error.message}`);
  }
}); 