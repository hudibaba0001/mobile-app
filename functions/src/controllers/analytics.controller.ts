// src/controllers/analytics.controller.ts
import { Request, Response } from 'express';
import * as admin from 'firebase-admin';

interface DashboardData {
  // KPIs
  totalHoursLoggedThisWeek: number;
  activeUsers: number;
  overtimeBalance: number;
  averageDailyHours: number;
  
  // Chart Data
  dailyTrends: Array<{
    date: string;
    totalHours: number;
    workHours: number;
    travelHours: number;
  }>;
  userDistribution: Array<{
    userId: string;
    userName: string;
    totalHours: number;
    percentage: number;
  }>;
  
  // Additional data for filters
  availableUsers: Array<{
    userId: string;
    userName: string;
  }>;
}

export const getDashboardData = async (req: Request, res: Response) => {
  const db = admin.firestore();
  const { startDate, endDate, userId } = req.query;

  try {
    // Parse date range - default to current week if not provided
    const now = new Date();
    const start = startDate ? new Date(startDate as string) : new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate as string) : now;

    // Build queries
    let entriesQuery: admin.firestore.Query = db.collection('entries');
    let travelEntriesQuery: admin.firestore.Query = db.collection('travel_entries');
    let usersQuery: admin.firestore.Query = db.collection('users');

    // Apply date filters
    entriesQuery = entriesQuery.where('date', '>=', start).where('date', '<=', end);
    travelEntriesQuery = travelEntriesQuery.where('date', '>=', start).where('date', '<=', end);

    // Apply user filter if provided
    if (userId) {
      entriesQuery = entriesQuery.where('userId', '==', userId);
      travelEntriesQuery = travelEntriesQuery.where('userId', '==', userId);
    }

    // Execute queries
    const [entriesSnapshot, travelEntriesSnapshot, usersSnapshot] = await Promise.all([
      entriesQuery.get(),
      travelEntriesQuery.get(),
      usersQuery.get()
    ]);

    // Process user data
    const usersMap = new Map<string, string>();
    usersSnapshot.forEach(doc => {
      const data = doc.data();
      usersMap.set(doc.id, data.displayName || data.email || 'Unknown User');
    });

    // Process entries data
    const userHoursMap = new Map<string, { workMinutes: number; travelMinutes: number }>();
    const dailyDataMap = new Map<string, { workMinutes: number; travelMinutes: number }>();
    
    let totalWorkMinutes = 0;
    let totalTravelMinutes = 0;

    // Process work entries
    entriesSnapshot.forEach(doc => {
      const data = doc.data();
      const userId = data.userId;
      const workMinutes = data.workMinutes || 0;
      const date = data.date.toDate ? data.date.toDate().toISOString().split('T')[0] : data.date.split('T')[0];
      
      // Aggregate by user
      if (!userHoursMap.has(userId)) {
        userHoursMap.set(userId, { workMinutes: 0, travelMinutes: 0 });
      }
      const userData = userHoursMap.get(userId)!;
      userData.workMinutes += workMinutes;
      
      // Aggregate by date
      if (!dailyDataMap.has(date)) {
        dailyDataMap.set(date, { workMinutes: 0, travelMinutes: 0 });
      }
      const dailyData = dailyDataMap.get(date)!;
      dailyData.workMinutes += workMinutes;
      
      totalWorkMinutes += workMinutes;
    });

    // Process travel entries
    travelEntriesSnapshot.forEach(doc => {
      const data = doc.data();
      const userId = data.userId;
      const travelMinutes = data.travelMinutes || 0;
      const date = data.date.toDate ? data.date.toDate().toDate().toISOString().split('T')[0] : data.date.split('T')[0];
      
      // Aggregate by user
      if (!userHoursMap.has(userId)) {
        userHoursMap.set(userId, { workMinutes: 0, travelMinutes: 0 });
      }
      const userData = userHoursMap.get(userId)!;
      userData.travelMinutes += travelMinutes;
      
      // Aggregate by date
      if (!dailyDataMap.has(date)) {
        dailyDataMap.set(date, { workMinutes: 0, travelMinutes: 0 });
      }
      const dailyData = dailyDataMap.get(date)!;
      dailyData.travelMinutes += travelMinutes;
      
      totalTravelMinutes += travelMinutes;
    });

    // Calculate KPIs
    const totalMinutesLoggedThisWeek = totalWorkMinutes + totalTravelMinutes;
    const totalHoursLoggedThisWeek = totalMinutesLoggedThisWeek / 60;
    const activeUsers = userHoursMap.size;
    
    // Calculate overtime balance (assuming 40 hours/week standard)
    const standardWeeklyHours = 40;
    const overtimeBalance = totalHoursLoggedThisWeek - standardWeeklyHours;
    
    // Calculate average daily hours
    const daysInRange = Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
    const averageDailyHours = daysInRange > 0 ? totalHoursLoggedThisWeek / daysInRange : 0;

    // Generate daily trends data (last 7 days)
    const dailyTrends = [];
    const today = new Date();
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today.getTime() - i * 24 * 60 * 60 * 1000);
      const dateStr = date.toISOString().split('T')[0];
      const dayData = dailyDataMap.get(dateStr) || { workMinutes: 0, travelMinutes: 0 };
      
      dailyTrends.push({
        date: dateStr,
        totalHours: (dayData.workMinutes + dayData.travelMinutes) / 60,
        workHours: dayData.workMinutes / 60,
        travelHours: dayData.travelMinutes / 60,
      });
    }

    // Generate user distribution data
    const userDistribution = [];
    const totalMinutes = totalWorkMinutes + totalTravelMinutes;
    
    for (const [userId, hours] of userHoursMap.entries()) {
      const userTotalMinutes = hours.workMinutes + hours.travelMinutes;
      const percentage = totalMinutes > 0 ? (userTotalMinutes / totalMinutes) * 100 : 0;
      
      userDistribution.push({
        userId,
        userName: usersMap.get(userId) || 'Unknown User',
        totalHours: userTotalMinutes / 60,
        percentage: Math.round(percentage * 100) / 100, // Round to 2 decimal places
      });
    }

    // Sort user distribution by total hours (descending)
    userDistribution.sort((a, b) => b.totalHours - a.totalHours);

    // Generate available users list for filters
    const availableUsers = Array.from(usersMap.entries()).map(([userId, userName]) => ({
      userId,
      userName,
    }));

    const dashboardData: DashboardData = {
      totalHoursLoggedThisWeek: Math.round(totalHoursLoggedThisWeek * 100) / 100,
      activeUsers,
      overtimeBalance: Math.round(overtimeBalance * 100) / 100,
      averageDailyHours: Math.round(averageDailyHours * 100) / 100,
      dailyTrends,
      userDistribution,
      availableUsers,
    };

    res.json(dashboardData);

  } catch (error) {
    console.error('Error fetching dashboard data:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard data' });
  }
};
