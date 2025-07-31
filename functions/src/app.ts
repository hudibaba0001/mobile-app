// src/app.ts

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { validateFirebaseIdToken } from './middleware/auth.middleware';
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

export default app;
