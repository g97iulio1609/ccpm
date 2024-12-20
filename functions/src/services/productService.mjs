import { stripe } from '../config/stripe.mjs';
import { firestore } from '../config/firebase.mjs';

export class ProductService {
  static async syncProducts() {
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
            price: price.unit_amount / 100,
            currency: price.currency,
            stripeProductId: product.id,
            stripePriceId: price.id,
            role: product.metadata.role || 'client_premium',
          }, { merge: true });
        }
      }

      await batch.commit();
      return { success: true, message: 'Products synced successfully' };
    } catch (error) {
      throw new Error(`Error syncing products: ${error.message}`);
    }
  }

  static async getProducts() {
    try {
      const productsSnapshot = await firestore.collection('products').get();
      return productsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error getting products: ${error.message}`);
    }
  }
} 