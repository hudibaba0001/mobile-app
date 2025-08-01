// src/controllers/analytics.controller.ts
import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import { subDays, format, startOfDay, endOfDay } from 'date-fns';

export const getDashboardData = async (req: Request, res: Response) => {
  const db = admin.firestore();
  const { startDate, endDate, userIds } = req.query;

  try {
    // 1. Build Base Query
    let entriesQuery: admin.firestore.Query = db.collection('entries');

    if (startDate) {
      entriesQuery = entriesQuery.where('date', '>=', new Date(startDate as string));
    }
    if (endDate) {
      entriesQuery = entriesQuery.where('date', '<=', new Date(endDate as string));
    }
    if (userIds) {
      const userIdsArray = (userIds as string).split(',');
      if (userIdsArray.length > 0) {
        entriesQuery = entriesQuery.where('userId', 'in', userIdsArray);
      }
    }

    const entriesSnapshot = await entriesQuery.get();
    const entries = entriesSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as any));

    // 2. Calculate KPIs
    const totalHours = entries.reduce((sum, entry) => sum + (entry.duration || 0), 0);
    const uniqueUserIds = [...new Set(entries.map(entry => entry.userId))];
    const activeUsers = uniqueUserIds.length;
    
    // Assuming 8 hours is a standard day for overtime calculation
    const overtimeBalance = entries.reduce((sum, entry) => sum + (entry.duration > 8 ? entry.duration - 8 : 0), 0);
    
    const totalDays = (startDate && endDate) 
      ? (new Date(endDate as string).getTime() - new Date(startDate as string).getTime()) / (1000 * 3600 * 24) + 1
      : 1;
    const averageDailyHours = totalDays > 0 ? totalHours / totalDays : 0;

    // 3. Prepare 7-Day Bar Chart Data
    const last7Days = Array.from({ length: 7 }).map((_, i) => subDays(new Date(), i));
    const dailyHoursData = await Promise.all(
      last7Days.map(async (day) => {
        const dayStart = startOfDay(day);
        const dayEnd = endOfDay(day);
        
        let dayQuery = db.collection('entries')
          .where('date', '>=', dayStart)
          .where('date', '<=', dayEnd);

        if (userIds) {
          const userIdsArray = (userIds as string).split(',');
          if (userIdsArray.length > 0) {
            dayQuery = dayQuery.where('userId', 'in', userIdsArray);
          }
        }
        
        const snapshot = await dayQuery.get();
        const total = snapshot.docs.reduce((sum, doc) => sum + (doc.data().duration || 0), 0);
        
        return {
          date: format(day, 'yyyy-MM-dd'),
          hours: total,
        };
      })
    );

    // 4. Prepare User Distribution Pie Chart Data
    const userHours: { [key: string]: number } = {};
    entries.forEach(entry => {
      userHours[entry.userId] = (userHours[entry.userId] || 0) + (entry.duration || 0);
    });

    const userDistribution = Object.entries(userHours).map(([userId, hours]) => ({
      userId,
      hours,
    }));

    // 5. Assemble Response
    res.json({
      kpis: {
        totalHours,
        activeUsers,
        overtimeBalance,
        averageDailyHours: parseFloat(averageDailyHours.toFixed(2)),
      },
      charts: {
        dailyHours: dailyHoursData.reverse(),
        userDistribution,
      },
    });

  } catch (error) {
    console.error('Error fetching dashboard data:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard data' });
  }
};
