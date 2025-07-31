// src/types/express.d.ts

import { auth } from 'firebase-admin';

declare global {
  namespace Express {
    interface Request {
      user?: auth.DecodedIdToken;
    }
  }
}
