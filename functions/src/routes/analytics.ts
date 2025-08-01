// src/routes/analytics.ts
import { Router } from 'express';
import { getDashboardData } from '../controllers/analytics.controller';
import { validateFirebaseIdToken, requireAdmin } from '../middleware/auth.middleware';

const router = Router();

// GET /analytics/dashboard
router.get('/dashboard', validateFirebaseIdToken, requireAdmin, getDashboardData);

export default router;
