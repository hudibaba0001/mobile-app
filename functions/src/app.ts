// src/app.ts

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
import { validateFirebaseIdToken } from './middleware/auth.middleware';
import analyticsRouter from './routes/analytics';
import usersRouter from './routes/users.routes';

const app = express();

// Middleware
app.use(helmet());
app.use(cors({ origin: true }));
app.use(express.json());

// Health check endpoint (no auth required)
app.get('/health', (_req, res) => res.status(200).json({ status: 'ok' }));

// Protected routes
app.use('/users', validateFirebaseIdToken, usersRouter);
app.use('/analytics', validateFirebaseIdToken, analyticsRouter);

export default app;
