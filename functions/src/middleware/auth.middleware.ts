// src/middleware/auth.middleware.ts

import { Request, Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';

export const validateFirebaseIdToken = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  if ((!req.headers.authorization || !req.headers.authorization.startsWith('Bearer '))) {
    res.status(403).json({ error: 'Unauthorized' });
    return;
  }

  const idToken = req.headers.authorization.split('Bearer ')[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Error verifying auth token:', error);
    res.status(403).json({ error: 'Unauthorized' });
  }
};
