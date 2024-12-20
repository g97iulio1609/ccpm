import { onRequest } from 'firebase-functions/v2/https';
import { AuthMiddleware } from '../middleware/auth.mjs';
import { ResponseHandler } from '../utils/responseHandler.mjs';
import { auth, firestore } from '../config/firebase.mjs';

export const deleteUser = onRequest({ cors: true }, async (request, response) => {
  if (request.method === 'OPTIONS') {
    return ResponseHandler.handleOptions(response);
  }

  try {
    const { userId, callerUid } = request.body;

    if (!callerUid) {
      return ResponseHandler.unauthorized(response);
    }

    await AuthMiddleware.verifyAdmin(callerUid);
    await auth.deleteUser(userId);
    await firestore.collection('users').doc(userId).delete();
    
    ResponseHandler.success(response);
  } catch (error) {
    ResponseHandler.error(response, error);
  }
}); 