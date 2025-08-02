// src/app.ts

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
import { validateFirebaseIdToken } from './middleware/auth.middleware';
import analyticsRouter from './routes/analytics';
import usersRouter from './routes/users.routes';
import paymentsRouter from './routes/payments';

const app = express();

// Middleware
app.use(helmet());
app.use(cors({ origin: true }));
app.use(express.json());

// Health check endpoint (no auth required)
app.get('/health', (_req, res) => res.status(200).json({ status: 'ok' }));

// Test endpoint (no auth required)
app.get('/test', (_req, res) => res.status(200).json({ 
  message: 'Backend is working!', 
  timestamp: new Date().toISOString(),
  project: 'kviktime-9ee5f',
  region: 'europe-west3'
}));

// Root endpoint (no auth required)
app.get('/', (_req, res) => res.status(200).json({ 
  message: 'KvikTime API is running!', 
  endpoints: {
    health: '/health',
    test: '/test',
    users: '/users (requires auth)',
    analytics: '/analytics (requires auth)'
  }
}));

// Protected routes
app.use('/users', validateFirebaseIdToken, usersRouter);
app.use('/analytics', validateFirebaseIdToken, analyticsRouter);

// Payment routes (no auth required for now)
app.use('/payments', paymentsRouter);

export default app;
