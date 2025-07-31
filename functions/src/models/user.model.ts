// src/models/user.model.ts

export interface User {
  uid: string;
  email: string | null;
  displayName: string | null;
  disabled: boolean;
}

export interface UserResponse {
  users: User[];
}
