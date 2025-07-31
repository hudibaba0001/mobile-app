// src/routes/users.routes.ts

import { Router } from 'express';
import { listUsers } from '../controllers/users.controller';

const router = Router();

router.get('/', listUsers);

export default router;
