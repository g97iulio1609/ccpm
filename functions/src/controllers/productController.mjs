import { onRequest, onCall } from 'firebase-functions/v2/https';
import { ProductService } from '../services/productService.mjs';
import { AuthMiddleware } from '../middleware/auth.mjs';
import { ResponseHandler } from '../utils/responseHandler.mjs';
import { firestore } from '../config/firebase.mjs';

export const getProducts = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  if (request.method === 'OPTIONS') {
    return ResponseHandler.handleOptions(response);
  }

  try {
    const productsSnapshot = await firestore.collection('products').get();
    const products = productsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    response.json({ products });
  } catch (error) {
    console.error('Unable to get products:', error);
    response.status(500).json({ error: 'Unable to get products: ' + error.message });
  }
});

export const syncProducts = onRequest({
  cors: true,
  region: 'europe-west1'
}, async (request, response) => {
  if (request.method === 'OPTIONS') {
    return ResponseHandler.handleOptions(response);
  }

  try {
    const decodedToken = await AuthMiddleware.verifyAuth(request);
    await AuthMiddleware.verifyAdmin(decodedToken.uid);
    
    const result = await ProductService.syncProducts();
    ResponseHandler.success(response, result);
  } catch (error) {
    if (error.message.includes('Token di autenticazione')) {
      response.status(401).json({ error: error.message });
    } else if (error.message.includes('ruolo di amministratore')) {
      response.status(403).json({ error: error.message });
    } else {
      console.error('Error syncing products:', error);
      response.status(500).json({ error: 'Unable to sync products: ' + error.message });
    }
  }
});

export const manualSyncStripeProducts = onCall({
  region: 'europe-west1'
}, async (request) => {
  if (!request.auth) {
    throw new Error('Unauthorized access');
  }

  try {
    await AuthMiddleware.verifyAdmin(request.auth.uid);
    const result = await ProductService.syncProducts();
    return { success: true, message: 'Products synced successfully' };
  } catch (error) {
    console.error('Failed to sync products:', error);
    throw new Error(`Failed to sync products: ${error.message}`);
  }
}); 