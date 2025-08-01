// src/middleware/auth.middleware.ts

import { Request, Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';

export const validateFirebaseIdToken = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  if ((!req.headers.authorization || !req.headers.authorization.startsWith('Bearer '))) {
    res.status(403).json({ error: 'No token provided' });
    return;
  }

  const idToken = req.headers.authorization.split('Bearer ')[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Error verifying auth token:', error);
    res.status(403).json({ error: 'Invalid token' });
  }
};

export const requireAdmin = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const user = req.user;
  
  if (!user) {
    res.status(403).json({ error: 'Unauthenticated request' });
    return;
  }

  if (!user.admin) {
    res.status(403).json({ error: 'Insufficient privileges' });
    return;
  }

  next();
};
