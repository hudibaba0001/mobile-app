// functions/src/index.ts

import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import app from './app';

// Initialize Firebase Admin
admin.initializeApp();

// Export the Express app as a Firebase Function with Europe West 3 region
export const api = onRequest({
  region: 'europe-west3'
}, app);
