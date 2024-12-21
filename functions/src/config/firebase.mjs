import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { setGlobalOptions } from 'firebase-functions/v2';

// Configurazione globale
setGlobalOptions({ 
  maxInstances: 10,
  region: 'europe-west1'
});

// Inizializzazione Firebase
initializeApp();

export const firestore = getFirestore();
export const auth = getAuth(); 