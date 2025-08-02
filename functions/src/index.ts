// functions/src/index.ts

import * as functions from 'firebase-functions';
import app from './app';

export const api = functions
  .region('europe-west3')
  .https.onRequest(app);
