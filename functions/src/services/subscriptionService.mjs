import { stripe } from '../config/stripe.mjs';
import { firestore } from '../config/firebase.mjs';
import { FieldValue } from 'firebase-admin/firestore';
import { google } from 'googleapis';

const packageName = 'com.alphaness.alphanessone';

export class SubscriptionService {
  static async createCheckoutSession(userId, productId) {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new Error('User not found.');
    }

    const userData = userDoc.data();
    const userEmail = userData.email;

    const productDoc = await firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) {
      throw new Error('Product not found.');
    }

    const product = productDoc.data();
    if (!product.stripePriceId) {
      throw new Error('Product does not have a Stripe Price ID.');
    }

    let customer = await this.getOrCreateCustomer(userEmail, userId);

    // Crea il PaymentIntent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: product.price * 100, // Converti in centesimi
      currency: product.currency || 'eur',
      customer: customer.id,
      payment_method_types: ['card'],
      metadata: {
        userId,
        productId,
      },
      automatic_payment_methods: {
        enabled: true,
      },
    });

    return { 
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id
    };
  }

  static async retrieveCheckoutSession(sessionId) {
    try {
      const session = await stripe.checkout.sessions.retrieve(sessionId);
      return {
        status: session.status,
        customer: session.customer,
        paymentStatus: session.payment_status,
        subscriptionId: session.subscription
      };
    } catch (error) {
      throw new Error(`Errore nel recuperare la sessione di checkout: ${error.message}`);
    }
  }

  static async getOrCreateCustomer(email, userId) {
    const existingCustomers = await stripe.customers.list({ email, limit: 1 });
    if (existingCustomers.data.length > 0) {
      return existingCustomers.data[0];
    }

    const customer = await stripe.customers.create({
      email,
      metadata: { firebaseUid: userId },
    });

    await firestore.collection('users').doc(userId).update({
      stripeCustomerId: customer.id,
    });

    return customer;
  }

  static async updateSubscriptionInFirestore(userId, subscription, role = 'client_premium') {
    await firestore.collection('users').doc(userId).update({
      role,
      subscriptionId: subscription.id,
      subscriptionStatus: subscription.status,
      subscriptionProductId: subscription.items.data[0].price.product,
      subscriptionPlatform: 'stripe',
      subscriptionStartDate: new Date(subscription.start_date * 1000),
      subscriptionExpiryDate: new Date(subscription.current_period_end * 1000),
    });
  }

  static async cancelSubscription(userId) {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new Error('User not found.');
    }

    const userData = userDoc.data();
    const subscriptionId = userData.subscriptionId;

    if (!subscriptionId) {
      throw new Error('No subscription found.');
    }

    const canceledSubscription = await stripe.subscriptions.del(subscriptionId);

    await this.updateSubscriptionStatus(userId, 'cancelled', canceledSubscription.current_period_end);
    return { success: true };
  }

  static async updateSubscriptionStatus(userId, status, expiryTimestamp) {
    await firestore.collection('users').doc(userId).update({
      subscriptionStatus: status,
      subscriptionExpiryDate: new Date(expiryTimestamp * 1000),
    });
  }

  static async revertToBasicUser(userId, batch) {
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

  static async checkAndUpdateStripeSubscription(userId, batch) {
    const userDoc = await firestore.collection('users').doc(userId).get();
    const userData = userDoc.data();

    try {
      const subscription = await stripe.subscriptions.retrieve(userData.subscriptionId);

      if (subscription.status === 'active') {
        batch.update(userDoc.ref, {
          subscriptionExpiryDate: new Date(subscription.current_period_end * 1000)
        });
      } else {
        await this.revertToBasicUser(userId, batch);
      }
    } catch (error) {
      await this.revertToBasicUser(userId, batch);
    }
  }

  static async updateSubscription(userId, newPriceId) {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new Error('Utente non trovato.');
    }

    const userData = userDoc.data();
    const subscriptionId = userData.subscriptionId;

    if (!subscriptionId) {
      throw new Error('Nessuna sottoscrizione trovata.');
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

    return { success: true, subscription: updatedSubscription };
  }

  static async createGiftSubscription(adminUid, userId, durationInDays) {
    const startDate = new Date();
    const expiryDate = new Date(startDate.getTime() + durationInDays * 24 * 60 * 60 * 1000);

    await firestore.collection('users').doc(userId).update({
      role: 'client_premium',
      subscriptionStatus: 'active',
      subscriptionPlatform: 'gift',
      subscriptionStartDate: startDate,
      subscriptionExpiryDate: expiryDate,
      giftedBy: adminUid,
      giftedAt: startDate,
    });

    return {
      success: true,
      message: 'Gift subscription created successfully',
    };
  }

  static async handleSuccessfulPayment(paymentId, productId, userId) {
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentId);
    if (paymentIntent.status !== 'succeeded') {
      throw new Error('Il pagamento non è stato completato con successo.');
    }

    const now = new Date();
    const expiryDate = new Date(now);
    if (productId.includes('yearly')) {
      expiryDate.setFullYear(expiryDate.getFullYear() + 1);
    } else {
      expiryDate.setMonth(expiryDate.getMonth() + 1);
    }

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

    return { success: true };
  }

  static async listUserSubscriptions(userId) {
    const userDoc = await firestore.collection('users').doc(userId).get();
    const userData = userDoc.data();
    const userEmail = userData.email;

    if (!userEmail) {
      throw new Error('Nessuna email trovata per l\'utente.');
    }

    const customers = await stripe.customers.list({ email: userEmail, limit: 1 });
    if (customers.data.length === 0) {
      throw new Error('Nessun customer trovato per l\'email dell\'utente.');
    }

    const customer = customers.data[0];
    const subscriptions = await stripe.subscriptions.list({
      customer: customer.id,
      status: 'all',
      expand: ['data.default_payment_method'],
    });

    return subscriptions.data.map(sub => ({
      id: sub.id,
      status: sub.status,
      current_period_end: sub.current_period_end,
      items: sub.items.data.map(item => ({
        priceId: item.price.id,
        productId: item.price.product,
        quantity: item.quantity,
      })),
    }));
  }

  static async checkGooglePlaySubscription(userId, batch) {
    const userDoc = await firestore.collection('users').doc(userId).get();
    const userData = userDoc.data();

    const isValid = await this.verifyGooglePlaySubscription(userData.purchaseToken, userData.productId);
    if (isValid) {
      const newExpiryDate = this.calculateNewExpiryDate();
      batch.update(userDoc.ref, {
        subscriptionExpiryDate: newExpiryDate
      });
    } else {
      await this.revertToBasicUser(userId, batch);
    }
  }

  static async verifyGooglePlaySubscription(purchaseToken, productId) {
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
      console.error('Error verifying Google Play subscription:', error);
      return false;
    }
  }

  static calculateNewExpiryDate() {
    const newDate = new Date();
    newDate.setMonth(newDate.getMonth() + 1);
    return newDate;
  }

  static async syncAllSubscriptions() {
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
          const usersSnapshot = await firestore.collection('users')
            .where('email', '==', userEmail)
            .get();

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
      return { success: true, message: 'Tutte le sottoscrizioni sono state sincronizzate con successo.' };
    } catch (error) {
      throw new Error(`Errore nella sincronizzazione delle sottoscrizioni: ${error.message}`);
    }
  }

  static async syncUserSubscription(userId, userEmail) {
    try {
      const customers = await stripe.customers.list({ email: userEmail, limit: 1 });

      if (customers.data.length === 0) {
        return { success: false, message: `Nessun abbonamento Stripe trovato per l'utente ${userId}.` };
      }

      const customer = customers.data[0];
      const subscriptions = await stripe.subscriptions.list({
        customer: customer.id,
        status: 'active',
        limit: 1,
      });

      if (subscriptions.data.length === 0) {
        return { success: false, message: `Nessun abbonamento attivo trovato per l'utente ${userId}.` };
      }

      const subscription = subscriptions.data[0];
      await this.updateSubscriptionInFirestore(userId, subscription);

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
      throw new Error(`Errore sincronizzando l'abbonamento per l'utente ${userId}: ${error.message}`);
    }
  }

  static async getUserSubscriptionDetails(userId) {
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
  }

  static async createPaymentIntent(userId, productId) {
    try {
      // Recupera il prodotto da Firestore
      const productDoc = await firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) {
        throw new Error('Prodotto non trovato');
      }
      const product = productDoc.data();

      // Crea il Payment Intent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(product.price * 100), // Converti in centesimi
        currency: product.currency || 'eur',
        metadata: {
          userId,
          productId,
          stripePriceId: product.stripePriceId,
        },
        automatic_payment_methods: {
          enabled: true,
        },
      });

      return paymentIntent;
    } catch (error) {
      console.error('Error creating payment intent:', error);
      throw error;
    }
  }
} 