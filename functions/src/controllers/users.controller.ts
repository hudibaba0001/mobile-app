// src/controllers/users.controller.ts

import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import { body, validationResult } from 'express-validator';
import { User, UserUpdateData, TravelHistory } from '../models/user.model';
import { FirebaseError } from 'firebase-admin';

// Disable a user
export const disableUser = async (req: Request, res: Response) => {
  try {
    const { uid } = req.params;

    // Check if user exists
    try {
      await admin.auth().getUser(uid);
    } catch (error: any) {
      if (error?.code === 'auth/user-not-found') {
        res.status(404).json({ error: 'User not found' });
        return;
      }
      throw error;
    }

    // Cannot disable yourself
    const requestingUser = req.user;
    if (requestingUser?.uid === uid) {
      res.status(403).json({ error: 'Cannot disable your own account' });
      return;
    }

    // Disable the user
    await admin.auth().updateUser(uid, { disabled: true });
    res.json({ message: 'User disabled successfully' });
  } catch (error) {
    console.error('Error disabling user:', error);
    res.status(500).json({ error: 'Failed to disable user' });
  }
};

// Enable a user
export const enableUser = async (req: Request, res: Response) => {
  try {
    const { uid } = req.params;

    // Check if user exists
    try {
      const user = await admin.auth().getUser(uid);
      if (!user.disabled) {
        res.status(400).json({ error: 'User is already enabled' });
        return;
      }
    } catch (error: any) {
      if (error?.code === 'auth/user-not-found') {
        res.status(404).json({ error: 'User not found' });
        return;
      }
      throw error;
    }

    // Enable the user
    await admin.auth().updateUser(uid, { disabled: false });
    res.json({ message: 'User enabled successfully' });
  } catch (error) {
    console.error('Error enabling user:', error);
    res.status(500).json({ error: 'Failed to enable user' });
  }
};

// Delete a user
export const deleteUser = async (req: Request, res: Response) => {
  try {
    const { uid } = req.params;
    
    // Check if user exists
    let userRecord;
    try {
      userRecord = await admin.auth().getUser(uid);
    } catch (error: any) {
      if (error?.code === 'auth/user-not-found') {
        res.status(404).json({ error: 'User not found' });
        return;
      }
      throw error;
    }

    // Cannot delete yourself
    const requestingUser = req.user;
    if (requestingUser?.uid === uid) {
      res.status(403).json({ error: 'Cannot delete your own account' });
      return;
    }

    // Start a Firestore batch
    const db = admin.firestore();
    const batch = db.batch();

    // Delete user's travel entries
    const travelEntries = await db.collection('travel_entries')
      .where('userId', '==', uid)
      .get();
    travelEntries.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    // Delete user's profile document
    const userProfileRef = db.collection('users').doc(uid);
    batch.delete(userProfileRef);

    // Execute batch deletion of Firestore data
    await batch.commit();

    // Finally, delete the user from Firebase Auth
    await admin.auth().deleteUser(uid);

    res.json({ message: 'User and all associated data deleted successfully' });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: 'Failed to delete user and associated data' });
  }
};

// List all users (admin only)
export const listUsers = async (_req: Request, res: Response) => {
  try {
    const listUsersResult = await admin.auth().listUsers(1000);
    const users = listUsersResult.users.map((userRecord) => ({
      uid: userRecord.uid,
      email: userRecord.email,
      displayName: userRecord.displayName,
      disabled: userRecord.disabled,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(userRecord.metadata.creationTime || Date.now())),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date(userRecord.metadata.lastSignInTime || Date.now()))
    }));
    res.json({ users });
  } catch (error) {
    console.error('Error listing users:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get user by ID
export const getUserById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { userId } = req.params;

    // Step 1: Check if user exists in Firebase Auth
    let userRecord;
    try {
      userRecord = await admin.auth().getUser(userId);
    } catch (error: any) {
      if (error?.code === 'auth/user-not-found') {
        res.status(404).json({ error: 'User not found in authentication system' });
        return;
      }
      throw error; // Re-throw other auth errors
    }

    // Step 2: Check if user exists in Firestore
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      res.status(404).json({ error: 'User profile not found in database' });
      return;
    }

    // Step 3: Construct user data from both sources
    const userData: User = {
      uid: userRecord.uid,
      email: userRecord.email,
      displayName: userRecord.displayName,
      disabled: userRecord.disabled,
      createdAt: userRecord.metadata.creationTime 
        ? admin.firestore.Timestamp.fromDate(new Date(userRecord.metadata.creationTime)) 
        : admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
      settings: userDoc.data()?.settings
    };

    // Step 4: Return successful response
    res.json(userData);
  } catch (error: any) {
    // Log the full error for debugging
    console.error('Error in getUserById:', {
      userId: req.params.userId,
      errorCode: error?.code,
      errorMessage: error?.message,
      stack: error?.stack
    });

    // Return appropriate error response
    if (error?.code === 'auth/invalid-uid') {
      res.status(400).json({ error: 'Invalid user ID format' });
    } else {
      res.status(500).json({ 
        error: 'Internal server error',
        message: process.env.NODE_ENV === 'development' ? error?.message : undefined
      });
    }
  }
};

// Validation middleware for updateUser
export const validateUpdateUser = [
  body('displayName')
    .optional()
    .isString()
    .trim()
    .isLength({ min: 3 })
    .withMessage('Display name must be at least 3 characters long'),
  body('settings')
    .optional()
    .isObject()
    .withMessage('Settings must be an object'),
  body('settings.theme')
    .optional()
    .isIn(['light', 'dark', 'system'])
    .withMessage('Theme must be either light, dark, or system'),
  body('settings.notifications')
    .optional()
    .isBoolean()
    .withMessage('Notifications must be a boolean'),
  body('settings.defaultTravelMode')
    .optional()
    .isString()
    .withMessage('Default travel mode must be a string')
];

// Update user
export const updateUser = async (req: Request, res: Response): Promise<void> => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ 
        error: 'Validation failed',
        details: errors.array()
      });
      return;
    }

    const { userId } = req.params;
    const updateData: UserUpdateData = req.body;

    // Update Auth display name if provided
    if (updateData.displayName) {
      await admin.auth().updateUser(userId, { displayName: updateData.displayName });
    }

    // Update Firestore user data
    await admin.firestore().collection('users').doc(userId).set({
      settings: updateData.settings,
      updatedAt: admin.firestore.Timestamp.now()
    }, { merge: true });

    res.json({ message: 'User updated successfully' });
  } catch (error: any) {
    console.error('Error updating user:', error);
    if (error?.code === 'auth/user-not-found') {
      res.status(404).json({ error: 'User not found' });
    } else {
      res.status(500).json({ error: 'Internal server error' });
    }
  }
};

// Delete user and all associated data
export const deleteUser = async (req: Request, res: Response): Promise<void> => {
  const db = admin.firestore();
  const { userId } = req.params;
  
  try {
    // Step 1: Verify user exists
    const userRecord = await admin.auth().getUser(userId);
      
    // Step 2: Prevent self-deletion
    const requestingUser = req.user;
    if (requestingUser?.uid === userRecord.uid) {
      res.status(403).json({ error: 'Cannot delete your own account' });
      return;
    }

    // Step 3: Start Firestore batch operations
    const batch = db.batch();

    // Step 4: Collect all data to be deleted
    const [userDoc, entriesSnapshot] = await Promise.all([
      db.collection('users').doc(userId).get(),
      db.collection('entries').where('userId', '==', userId).get()
    ]);

    // Step 5: Add all deletions to batch
    if (userDoc.exists) {
      batch.delete(userDoc.ref);
    }

    entriesSnapshot.forEach(doc => {
      batch.delete(doc.ref);
    });

    // Step 6: Execute Firestore deletions
    await batch.commit();

    // Step 7: Delete Firebase Auth user
    await admin.auth().deleteUser(userId);

    res.json({
      message: 'User deleted successfully',
      details: {
        profileDeleted: userDoc.exists,
        entriesDeleted: entriesSnapshot.size
      }
    });

  } catch (error: any) {
    console.error('Error deleting user:', error);
    
    if (error?.code === 'auth/user-not-found') {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    if (error?.code?.startsWith('auth/')) {
      res.status(403).json({ error: 'Authentication error', details: error.message });
      return;
    }

    res.status(500).json({
      error: 'Failed to delete user',
      details: error.message
    });
  }
};
      
      entriesSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      // Execute Firestore batch
      await batch.commit();
      
      // Delete from Firebase Auth (do this last as it can't be rolled back)
      await admin.auth().deleteUser(userId);

      // Log successful deletion
      console.info('User successfully deleted:', {
        userId,
        hadFirestoreData: userDoc.exists,
        entriesDeleted: entriesSnapshot.size
      });

      res.json({ 
        message: 'User deleted successfully',
        details: {
          profileDeleted: userDoc.exists,
          entriesDeleted: entriesSnapshot.size
        }
      });
    } catch (error: any) {
      // If we fail after some operations, log the incomplete state
      console.error('Partial deletion failure:', {
        userId,
        errorCode: error?.code,
        errorMessage: error?.message,
        stack: error?.stack
      });
      throw error; // Re-throw to be handled by outer catch
    }
  } catch (error: any) {
    // Log the full error context
    console.error('Error in deleteUser:', {
      userId: req.params.userId,
      errorCode: error?.code,
      errorMessage: error?.message,
      stack: error?.stack
    });

    // Return appropriate error response
    if (error?.code === 'auth/invalid-uid') {
      res.status(400).json({ error: 'Invalid user ID format' });
    } else if (error?.code?.startsWith('auth/')) {
      res.status(403).json({ error: 'Authentication error', message: error.message });
    } else {
      res.status(500).json({ 
        error: 'Internal server error',
        message: process.env.NODE_ENV === 'development' ? error?.message : undefined
      });
    }
  }
};

// Get user's travel history
export const getUserTravelHistory = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const { startDate, endDate } = req.query;

    let query = admin.firestore()
      .collection('entries')
      .where('userId', '==', userId)
      .where('type', '==', 'travel')
      .orderBy('date', 'desc');

    if (startDate) {
      query = query.where('date', '>=', new Date(startDate as string));
    }
    if (endDate) {
      query = query.where('date', '<=', new Date(endDate as string));
    }

    const snapshot = await query.get();
    const entries = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        date: data.date,
        from: data.from,
        to: data.to,
        duration: data.duration,
        type: data.type
      };
    });

    const history: TravelHistory = {
      userId,
      entries
    };

    res.json(history);
  } catch (error: any) {
    console.error('Error fetching travel history:', error);
    if (error?.code === 'auth/user-not-found') {
      res.status(404).json({ error: 'User not found' });
    } else {
      res.status(500).json({ error: 'Internal server error' });
    }
  }
};
