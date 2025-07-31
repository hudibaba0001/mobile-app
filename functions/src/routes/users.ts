// functions/src/routes/users.ts

const { Router } = require('express');
const admin = require('firebase-admin');

const router = Router();

// GET /api/users - Lists all Firebase Authentication users
router.get('/', async (_req: Request, res: Response) => {
  try {
    const listUsersResult = await admin.auth().listUsers(1000);
    const users = listUsersResult.users.map((userRecord) => ({
      uid: userRecord.uid,
      email: userRecord.email,
      displayName: userRecord.displayName,
      disabled: userRecord.disabled,
    }));
    res.status(200).json({ users });
  } catch (error) {
    console.error('Error listing users:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
