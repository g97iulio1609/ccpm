import { onSchedule } from 'firebase-functions/v2/scheduler';
import { firestore } from './src/config/firebase.mjs';
import { SubscriptionService } from './src/services/subscriptionService.mjs';
import { ProductService } from './src/services/productService.mjs';

// Esporta tutte le funzioni dai controller
export * from './src/controllers/subscriptionController.mjs';
export * from './src/controllers/productController.mjs';
export * from './src/controllers/userController.mjs';

// Funzione schedulata per verificare e aggiornare le sottoscrizioni
export const checkAndUpdateSubscription = onSchedule({
  schedule: 'every 24 hours',
  region: 'europe-west1'
}, async () => {
  try {
    const usersSnapshot = await firestore.collection('users')
      .where('subscriptionStatus', '==', 'active')
      .get();

    const batch = firestore.batch();

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const userId = userDoc.id;

      try {
        if (userData.subscriptionPlatform === 'stripe') {
          await SubscriptionService.checkAndUpdateStripeSubscription(userId, batch);
        } else if (userData.subscriptionPlatform === 'google_play') {
          await SubscriptionService.checkGooglePlaySubscription(userId, batch);
        }
      } catch (error) {
        console.error(`Error checking subscription for user ${userId}:`, error);
        await SubscriptionService.revertToBasicUser(userId, batch);
      }
    }

    await batch.commit();
  } catch (error) {
    console.error('Error in checkAndUpdateSubscription:', error);
  }
});

// Funzione schedulata per sincronizzare i prodotti Stripe
export const syncStripeProducts = onSchedule({
  schedule: 'every 24 hours',
  region: 'europe-west1'
}, async () => {
  try {
    await ProductService.syncProducts();
  } catch (error) {
    console.error('Error in syncStripeProducts:', error);
  }
});
