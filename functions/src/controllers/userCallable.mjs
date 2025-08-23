import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { auth, firestore } from '../config/firebase.mjs';
import { AuthMiddleware } from '../middleware/auth.mjs';

// Callable wrapper for deleting a user using admin privileges.
// Expects { userId } in data and requires the caller to be an admin.
export const deleteUserCallable = onCall({ region: 'europe-west1' }, async (request) => {
  try {
    const callerUid = request.auth?.uid;
    const { userId } = request.data || {};

    if (!callerUid) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }
    if (!userId) {
      throw new HttpsError('invalid-argument', 'userId is required');
    }

    const isAdmin = await AuthMiddleware.isAdmin(callerUid);
    if (!isAdmin) {
      throw new HttpsError('permission-denied', 'Admin privileges required');
    }

    // Delete from Firebase Auth and remove Firestore user doc (idempotent)
    try {
      await auth.deleteUser(userId);
    } catch (e) {
      // If user does not exist in Auth, continue; otherwise rethrow
      const msg = String(e?.message || e);
      if (!/not found|user-not-found/i.test(msg)) {
        throw new HttpsError('internal', 'Failed to delete auth user');
      }
    }
    await firestore.collection('users').doc(userId).delete();

    return { ok: true };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    throw new HttpsError('internal', String(err?.message || err));
  }
});
