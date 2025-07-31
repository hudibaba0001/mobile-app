// functions/src/index.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import app from './app';

// Initialize Firebase Admin
admin.initializeApp();

// Export the Express app as a Firebase Function
export const api = functions.https.onRequest(app);
