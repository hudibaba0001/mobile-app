// src/controllers/analytics.controller.ts
import { Request, Response } from 'express';
import * as admin from 'firebase-admin';

export const getDashboardData = async (req: Request, res: Response) => {
  const db = admin.firestore();
  const { startDate, endDate } = req.query;

  try {
    let entriesQuery: admin.firestore.Query = db.collection('entries');
    let travelEntriesQuery: admin.firestore.Query = db.collection('travel_entries');

    if (startDate) {
      entriesQuery = entriesQuery.where('date', '>=', new Date(startDate as string));
      travelEntriesQuery = travelEntriesQuery.where('date', '>=', new Date(startDate as string));
    }
    if (endDate) {
      entriesQuery = entriesQuery.where('date', '<=', new Date(endDate as string));
      travelEntriesQuery = travelEntriesQuery.where('date', '<=', new Date(endDate as string));
    }

    const [entriesSnapshot, travelEntriesSnapshot] = await Promise.all([
      entriesQuery.get(),
      travelEntriesQuery.get()
    ]);

    const activeUserIds = new Set<string>();
    let totalMinutesLogged = 0;

    entriesSnapshot.forEach(doc => {
      const data = doc.data();
      activeUserIds.add(data.userId);
      totalMinutesLogged += data.duration || 0; // Assuming duration is in minutes
    });

    travelEntriesSnapshot.forEach(doc => {
      const data = doc.data();
      activeUserIds.add(data.userId);
      totalMinutesLogged += data.duration || 0; // Assuming duration is in minutes
    });

    res.json({
      activeUsers: activeUserIds.size,
      totalMinutesLogged: totalMinutesLogged
    });

  } catch (error) {
    console.error('Error fetching dashboard data:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard data' });
  }
};
