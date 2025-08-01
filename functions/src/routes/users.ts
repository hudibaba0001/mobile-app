// functions/src/routes/users.ts

import { Router } from 'express';
import { 
  listUsers, 
  getUserById, 
  updateUser, 
  validateUpdateUser,
  deleteUser,
  disableUser,
  enableUser,
  getUserTravelHistory 
} from '../controllers/users.controller';
import { validateFirebaseIdToken, requireAdmin } from '../middleware/auth.middleware';

const router = Router();

// Apply auth middleware to all routes
router.use(validateFirebaseIdToken);

// Admin-only routes
router.get('/', requireAdmin, listUsers);
router.put('/:userId', requireAdmin, validateUpdateUser, updateUser);
router.post('/:uid/disable', requireAdmin, disableUser);
router.post('/:uid/enable', requireAdmin, enableUser);
router.delete('/:userId', requireAdmin, deleteUser);

// User-accessible routes (still need authentication)
router.get('/:userId', getUserById);
router.get('/:userId/travel-history', getUserTravelHistory);

export default router;
