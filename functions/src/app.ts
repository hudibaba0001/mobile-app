// src/app.ts

// Initialize Firebase Admin first
import * as admin from 'firebase-admin';
admin.initializeApp();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
import { Request, Response } from 'express';
import { validateFirebaseIdToken } from './middleware/auth.middleware';
import analyticsRouter from './routes/analytics';
import usersRouter from './routes/users.routes';
import paymentsRouter from './routes/payments';

const app = express();

// Middleware
app.use(helmet());
// Define a whitelist of allowed domains for production
const whitelist = [
  'https://app-kviktime-se.web.app',
  'https://kviktime-9ee5f.web.app',
  'https://www.app.kviktime.se',
  'https://app.kviktime.se',
];

const corsOptions = {
  origin: function (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) {
      return callback(null, true);
    }
    // Allow from the whitelist or any localhost origin
    if (whitelist.indexOf(origin) !== -1 || /localhost:\d+$/.test(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
};

app.use(cors(corsOptions));
// Explicitly handle preflight for all routes
app.options('*', cors(corsOptions));
app.use(express.json());

// Health check endpoint (no auth required)
app.get('/health', (_req: Request, res: Response) => res.status(200).json({ status: 'ok' }));

// Test endpoint (no auth required)
app.get('/test', (_req: Request, res: Response) => res.status(200).json({
  message: 'Backend is working with optional fields fix!',
  timestamp: new Date().toISOString(),
  project: 'kviktime-9ee5f',
  region: 'europe-west3'
}));

// Root endpoint (no auth required)
app.get('/', (_req: Request, res: Response) => res.status(200).json({
  message: 'KvikTime API is running!',
  endpoints: {
    health: '/health',
    test: '/test',
    users: '/users (requires auth)',
    analytics: '/analytics (requires auth)',
    payments: '/payments'
  }
}));

// Protected routes
app.use('/users', validateFirebaseIdToken, usersRouter);
app.use('/analytics', validateFirebaseIdToken, analyticsRouter);

// Payment routes (no auth required for now)
app.use('/payments', paymentsRouter);

export default app;
