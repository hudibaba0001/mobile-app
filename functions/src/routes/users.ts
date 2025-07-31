// functions/src/routes/users.ts

import { Router } from 'express';
import { 
  listUsers, 
  getUserById, 
  updateUser, 
  validateUpdateUser,
  deleteUser, 
  getUserTravelHistory 
} from '../controllers/users.controller';

const router = Router();

// List all users (admin only)
router.get('/', listUsers);

// Get specific user
router.get('/:userId', getUserById);

// Update user - with validation middleware
router.put('/:userId', validateUpdateUser, updateUser);

// Delete user
router.delete('/:userId', deleteUser);

// Get user's travel history
router.get('/:userId/travel-history', getUserTravelHistory);

export default router;
