/**
 * User profile from user_profiles table
 */
export interface UserProfile {
  id: string;
  email: string;
  full_name: string | null;
  is_admin: boolean;
  created_at: string;
  updated_at: string | null;
}

/**
 * Admin user from admin_users table
 */
export interface AdminUser {
  id: string;
  user_id: string;
  full_name: string;
  email: string;
  created_at: string;
  updated_at: string | null;
}

/**
 * Request body for creating a new user
 */
export interface CreateUserRequest {
  email: string;
  fullName: string;
  isAdmin?: boolean;
}

/**
 * Request body for updating a user
 */
export interface UpdateUserRequest {
  fullName?: string;
  isAdmin?: boolean;
}
