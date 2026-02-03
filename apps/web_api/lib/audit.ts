import { NextRequest } from 'next/server';
import { supabaseAdmin } from './supabase';

export interface AuditLogEntry {
  action: string;
  resourceType?: string;
  resourceId?: string;
  details?: Record<string, any>;
}

export async function logAdminAction(
  adminUserId: string,
  entry: AuditLogEntry,
  request?: NextRequest
) {
  try {
    const ipAddress = request?.headers.get('x-forwarded-for') ||
                     request?.headers.get('x-real-ip') ||
                     null;
    const userAgent = request?.headers.get('user-agent') || null;

    const { error } = await supabaseAdmin
      .from('admin_audit_log')
      .insert({
        admin_user_id: adminUserId,
        action: entry.action,
        resource_type: entry.resourceType,
        resource_id: entry.resourceId,
        details: entry.details,
        ip_address: ipAddress,
        user_agent: userAgent,
      });

    if (error) {
      console.error('Failed to log admin action:', error);
      // Don't throw - audit logging failure shouldn't break the main operation
    }
  } catch (error) {
    console.error('Unexpected error logging admin action:', error);
  }
}
