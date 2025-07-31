// src/models/user.model.ts

export interface User {
  uid: string;
  email: string | null;
  displayName: string | null;
  disabled: boolean;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
  settings?: {
    theme?: 'light' | 'dark' | 'system';
    notifications?: boolean;
    defaultTravelMode?: string;
  };
}

export interface TravelHistory {
  userId: string;
  entries: Array<{
    id: string;
    date: FirebaseFirestore.Timestamp;
    from: string;
    to: string;
    duration: number;
    type: string;
  }>;
}

export interface UserUpdateData {
  displayName?: string;
  settings?: {
    theme?: 'light' | 'dark' | 'system';
    notifications?: boolean;
    defaultTravelMode?: string;
  };
}

export interface UserResponse {
  users: User[];
}
