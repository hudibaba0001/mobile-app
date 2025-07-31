// src/routes/users.routes.ts

import { Router } from 'express';
import { listUsers, getUserById, updateUser, deleteUser, getUserTravelHistory } from '../controllers/users.controller';
import { validateFirebaseIdToken } from '../middleware/auth.middleware';

const router = Router();

// Get all users (admin only)
router.get('/', validateFirebaseIdToken, listUsers);

// Get specific user by ID
router.get('/:userId', validateFirebaseIdToken, getUserById);

// Update user details
router.put('/:userId', validateFirebaseIdToken, updateUser);

// Delete user
router.delete('/:userId', validateFirebaseIdToken, deleteUser);

// Get user's travel history
router.get('/:userId/travel-history', validateFirebaseIdToken, getUserTravelHistory);

export default router;
