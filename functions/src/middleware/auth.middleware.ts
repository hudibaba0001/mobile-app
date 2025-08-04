// src/middleware/auth.middleware.ts

import { Request, Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';

// Extend the Request interface to include user
declare global {
  namespace Express {
    interface Request {
      user?: admin.auth.DecodedIdToken;
    }
  }
}

export const validateFirebaseIdToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'No valid authorization header' });
    return;
  }

  const idToken = authHeader.split('Bearer ')[1];

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
): Promise<void> => {
  const user = req.user;
  
  if (!user) {
    console.error('requireAdmin: No user found in request');
    res.status(403).json({ error: 'Unauthenticated request' });
    return;
  }

  // Check for admin custom claim
  const isAdmin = (user as any).admin === true;
  
  if (!isAdmin) {
    console.error(`requireAdmin: User ${user.uid} (${user.email}) lacks admin privileges`);
    res.status(403).json({ error: 'Insufficient privileges - Admin access required' });
    return;
  }

  console.log(`requireAdmin: User ${user.uid} (${user.email}) granted admin access`);
  next();
};
