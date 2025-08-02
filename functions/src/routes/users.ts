// functions/src/routes/users.ts

import { Router } from 'express';
import { 
  getUsers,
  deleteUser
} from '../controllers/users.controller';
import { validateFirebaseIdToken, requireAdmin } from '../middleware/auth.middleware';

const router = Router();

// Apply auth middleware to all routes
router.use(validateFirebaseIdToken);

// Admin-only routes
router.get('/', requireAdmin, getUsers);
router.delete('/:userId', requireAdmin, deleteUser);

// User-accessible routes (still need authentication)

export default router;
