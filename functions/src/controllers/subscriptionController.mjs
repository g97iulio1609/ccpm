import { onRequest, onCall } from 'firebase-functions/v2/https';
import { SubscriptionService } from '../services/subscriptionService.mjs';
import { AuthMiddleware } from '../middleware/auth.mjs';
import { ResponseHandler } from '../utils/responseHandler.mjs';
import { stripe, stripeWebhookSecret } from '../config/stripe.mjs';
import { firestore } from '../config/firebase.mjs';
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
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object;
        await handleSuccessfulPayment(session);
        break;
      }
      case 'customer.subscription.updated':
      case 'customer.subscription.deleted': {
        const subscription = event.data.object;
        await handleSubscriptionUpdate(subscription);
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

// Funzione per gestire pagamenti riusciti
async function handleSuccessfulPayment(session) {
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
    console.error('Error in handleSuccessfulPayment:', error);
  }
}

// Funzione per gestire aggiornamenti delle sottoscrizioni
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

export const handleWebhookEventsFunction = onRequest({ 
  cors: true,
  region: 'europe-west1' 
}, app);

export const createCheckoutSession = onCall(async (request) => {
  if (!request.auth) {
    throw new Error('Devi essere autenticato per creare una sessione di checkout.');
  }

  const { productId } = request.data;
  const userId = request.auth.uid;

  try {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new Error('Utente non trovato.');
    }

    const userData = userDoc.data();
    const userEmail = userData.email;

    const productDoc = await firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) {
      throw new Error('Prodotto non trovato.');
    }

    const product = productDoc.data();

    if (!product.stripePriceId) {
      throw new Error('Il prodotto non ha un ID prezzo Stripe.');
    }

    // Crea o recupera il cliente Stripe
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
      ui_mode: 'embedded',
      payment_method_types: ['card'],
      line_items: [{
        price: product.stripePriceId,
        quantity: 1,
      }],
      mode: 'subscription',
      return_url: `https://alphaness.online/success?session_id={CHECKOUT_SESSION_ID}`,
      customer: customer.id,
      client_reference_id: userId,
      expand: ['payment_intent'],
    });

    return { 
      success: true,
      clientSecret: session.client_secret,
      sessionId: session.id
    };
  } catch (error) {
    throw new Error('Impossibile creare la sessione di checkout: ' + error.message);
  }
});

export const retrieveCheckoutSession = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  if (request.method === 'OPTIONS') {
    return ResponseHandler.handleOptions(response);
  }

  try {
    const { sessionId } = request.body;
    if (!sessionId) {
      return ResponseHandler.error(response, new Error('sessionId è richiesto'), 400);
    }

    const session = await stripe.checkout.sessions.retrieve(sessionId);
    ResponseHandler.success(response, {
      success: true,
      session
    });
  } catch (error) {
    console.error('Error in retrieveCheckoutSession:', error);
    ResponseHandler.error(response, error);
  }
});

export const getSubscriptionDetails = onCall(async (request) => {
  if (!request.auth) {
    throw new Error('Devi essere autenticato.');
  }

  const userId = request.auth.uid;

  try {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new Error('Utente non trovato.');
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
    throw new Error('Errore nel recuperare i dettagli della sottoscrizione: ' + error.message);
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
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new Error('Utente non trovato.');
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
    throw new Error('Errore nel recuperare i dettagli della sottoscrizione: ' + error.message);
  }
});

export const listSubscriptions = onCall({
  region: 'europe-west1'
}, async (request) => {
  if (!request.auth) {
    throw new Error('Devi essere autenticato.');
  }

  try {
    const userDoc = await firestore.collection('users').doc(request.auth.uid).get();
    const userData = userDoc.data();
    const userEmail = userData.email;

    if (!userEmail) {
      throw new Error('Email utente non trovata.');
    }

    const customers = await stripe.customers.list({ email: userEmail, limit: 1 });

    if (customers.data.length === 0) {
      throw new Error('Nessun cliente Stripe trovato.');
    }

    const customer = customers.data[0];
    const subscriptions = await stripe.subscriptions.list({
      customer: customer.id,
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
    throw new Error('Errore nel recuperare le sottoscrizioni: ' + error.message);
  }
});

export const testStripeConnection = onCall({
  region: 'europe-west1'
}, async () => {
  try {
    const balance = await stripe.balance.retrieve();
    return { success: true, balance };
  } catch (error) {
    throw new Error('Impossibile connettersi a Stripe: ' + error.message);
  }
});

export const syncSubscription = onCall({
  region: 'europe-west1'
}, async (request) => {
  if (!request.auth) {
    throw new Error('Devi essere autenticato.');
  }

  const callerUid = request.auth.uid;
  const targetUserId = request.data?.userId || callerUid;

  try {
    // Se l'utente sta cercando di sincronizzare un altro account, verifica che sia admin
    if (targetUserId !== callerUid) {
      const adminDoc = await firestore.collection('users').doc(callerUid).get();
      if (!adminDoc.exists || adminDoc.data().role !== 'admin') {
        throw new Error('Non hai i permessi per sincronizzare le sottoscrizioni di altri utenti.');
      }
    }

    // Recupera il documento dell'utente target
    const userDoc = await firestore.collection('users').doc(targetUserId).get();
    if (!userDoc.exists) {
      throw new Error('Utente non trovato.');
    }

    const userData = userDoc.data();
    const userEmail = userData.email;

    // Prima verifica se l'utente ha già una sottoscrizione in Firestore
    const currentSubscriptionId = userData.subscriptionId;
    if (currentSubscriptionId) {
      try {
        // Verifica lo stato della sottoscrizione esistente in Stripe
        const subscription = await stripe.subscriptions.retrieve(currentSubscriptionId);
        
        if (subscription.status === 'active') {
          // Aggiorna i dati in Firestore
          await firestore.collection('users').doc(targetUserId).update({
            subscriptionStatus: subscription.status,
            subscriptionExpiryDate: new Date(subscription.current_period_end * 1000),
          });

          return {
            success: true,
            message: 'Sottoscrizione esistente sincronizzata con successo.',
            subscription: {
              id: subscription.id,
              status: subscription.status,
              current_period_end: subscription.current_period_end,
            }
          };
        }
      } catch (stripeError) {
        console.error('Errore nel recupero della sottoscrizione da Stripe:', stripeError);
      }
    }

    // Se non ha una sottoscrizione attiva o c'è stato un errore, cerca nuove sottoscrizioni
    const customers = await stripe.customers.list({ email: userEmail, limit: 1 });
    
    if (customers.data.length === 0) {
      return { 
        success: false, 
        message: `Nessun cliente Stripe trovato per l'utente ${targetUserId}.` 
      };
    }

    const customer = customers.data[0];
    const subscriptions = await stripe.subscriptions.list({
      customer: customer.id,
      status: 'active',
      limit: 1,
    });

    if (subscriptions.data.length === 0) {
      // Se non ci sono sottoscrizioni attive, resetta lo stato dell'utente
      await firestore.collection('users').doc(targetUserId).update({
        role: 'client',
        subscriptionStatus: 'inactive',
        subscriptionId: null,
        subscriptionExpiryDate: null,
        subscriptionPlatform: null,
        subscriptionProductId: null,
      });

      return { 
        success: false, 
        message: `Nessuna sottoscrizione attiva trovata per l'utente ${targetUserId}.` 
      };
    }

    // Aggiorna con la nuova sottoscrizione trovata
    const subscription = subscriptions.data[0];
    const productId = subscription.items.data[0].price.product;
    
    // Recupera il prodotto per ottenere il ruolo corretto
    const productDoc = await firestore.collection('products').doc(productId).get();
    const role = productDoc.exists ? productDoc.data().role || 'client_premium' : 'client_premium';

    await firestore.collection('users').doc(targetUserId).update({
      role: role,
      subscriptionId: subscription.id,
      subscriptionStatus: subscription.status,
      subscriptionProductId: productId,
      subscriptionPlatform: 'stripe',
      subscriptionStartDate: new Date(subscription.start_date * 1000),
      subscriptionExpiryDate: new Date(subscription.current_period_end * 1000),
    });

    return {
      success: true,
      message: `Sottoscrizione sincronizzata con successo per l'utente ${targetUserId}.`,
      subscription: {
        id: subscription.id,
        status: subscription.status,
        current_period_end: subscription.current_period_end,
      }
    };
  } catch (error) {
    console.error('Errore nella sincronizzazione:', error);
    throw new Error(`Errore nella sincronizzazione: ${error.message}`);
  }
}); 