import { auth, firestore } from '../config/firebase.mjs';

export class AuthMiddleware {
  static async verifyAuth(request) {
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new Error('Token di autenticazione mancante o non valido.');
    }

    const idToken = authHeader.split('Bearer ')[1];
    return await auth.verifyIdToken(idToken);
  }

  static async verifyAdmin(userId) {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists || userDoc.data().role !== 'admin') {
      throw new Error('Accesso non autorizzato. È richiesto il ruolo di amministratore.');
    }
    return true;
  }

  static async verifyUser(userId) {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new Error('Utente non trovato.');
    }
    return userDoc;
  }

  static async isAdmin(uid) {
    const userDoc = await firestore.collection('users').doc(uid).get();
    return userDoc.exists && userDoc.data().role === 'admin';
  }
} 