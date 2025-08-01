// src/routes/users.routes.ts

import { Router } from 'express';
import { listUsers, getUserById, updateUser, deleteUser, getUserTravelHistory } from '../controllers/users.controller';
import { validateFirebaseIdToken, requireAdmin } from '../middleware/auth.middleware';

const router = Router();

// Get all users (admin only)
router.get('/', validateFirebaseIdToken, requireAdmin, listUsers);

// Get specific user by ID
router.get('/:userId', validateFirebaseIdToken, getUserById);

// Update user details
router.put('/:userId', validateFirebaseIdToken, updateUser);

// Delete user (admin only)
router.delete('/:uid', validateFirebaseIdToken, requireAdmin, deleteUser);

// Get user's travel history
router.get('/:userId/travel-history', validateFirebaseIdToken, getUserTravelHistory);

export default router;
