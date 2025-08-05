// functions/src/index.ts

import { onRequest } from 'firebase-functions/v2/https';
import app from './app';

export const api = onRequest(
  { region: 'europe-west3' },
  app
);
