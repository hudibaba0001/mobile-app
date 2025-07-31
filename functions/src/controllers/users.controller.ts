// src/controllers/users.controller.ts

import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import { User, UserUpdateData, TravelHistory } from '../models/user.model';

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
export const getUserById = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const userRecord = await admin.auth().getUser(userId);
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    
    const userData: User = {
      uid: userRecord.uid,
      email: userRecord.email,
      displayName: userRecord.displayName,
      disabled: userRecord.disabled,
      createdAt: userRecord.metadata.creationTime ? admin.firestore.Timestamp.fromDate(new Date(userRecord.metadata.creationTime)) : admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
      settings: userDoc.exists ? userDoc.data()?.settings : undefined
    };

    res.json(userData);
  } catch (error: any) {
    console.error('Error fetching user:', error);
    if (error?.code === 'auth/user-not-found') {
      res.status(404).json({ error: 'User not found' });
    } else {
      res.status(500).json({ error: 'Internal server error' });
    }
  }
};

// Update user
export const updateUser = async (req: Request, res: Response) => {
  try {
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

// Delete user
export const deleteUser = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    
    // Delete from Auth
    await admin.auth().deleteUser(userId);
    
    // Delete from Firestore
    await admin.firestore().collection('users').doc(userId).delete();
    
    res.json({ message: 'User deleted successfully' });
  } catch (error: any) {
    console.error('Error deleting user:', error);
    if (error?.code === 'auth/user-not-found') {
      res.status(404).json({ error: 'User not found' });
    } else {
      res.status(500).json({ error: 'Internal server error' });
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
