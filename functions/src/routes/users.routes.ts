// src/routes/users.routes.ts

import express from 'express';
import { getUsers, deleteUser } from '../controllers/users.controller';

const router = express.Router();

// Get all users
router.get('/', getUsers);

// Delete a user
router.delete('/:userId', deleteUser);

export default router;
