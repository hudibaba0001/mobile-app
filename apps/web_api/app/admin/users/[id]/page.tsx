'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import AdminLayout from '@/components/AdminLayout';

interface UserDetail {
  profile: {
    id: string;
    email: string;
    first_name?: string;
    last_name?: string;
    created_at: string;
  };
  contract: {
    full_time_hours: number;
    contract_percent: number;
    tracking_start_date?: string;
    opening_flex_minutes: number;
  };
  balances: {
    balanceToday: number;
    monthNet: number;
    yearNet: number;
    openingBalance: number;
  } | null;
  counts: {
    entries: number;
    absences: number;
    adjustments: number;
    redDays: number;
  };
}

export default function UserDetailPage({ params }: { params: { id: string } }) {
  const router = useRouter();
  const [userDetail, setUserDetail] = useState<UserDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [isExporting, setIsExporting] = useState(false);

  useEffect(() => {
    fetchUserDetail();
  }, [params.id]);

  const fetchUserDetail = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('admin_access_token');
      const response = await fetch(`/api/admin/users/${params.id}`, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        if (response.status === 404) {
          throw new Error('User not found');
        }
        throw new Error('Failed to fetch user details');
      }

      const data = await response.json();
      setUserDetail(data);
      setError('');
    } catch (err: any) {
      setError(err.message || 'Failed to load user details');
    } finally {
      setLoading(false);
    }
  };

  const handleExport = async () => {
    try {
      setIsExporting(true);
      const token = localStorage.getItem('admin_access_token');
      const response = await fetch(`/api/admin/users/${params.id}/export`, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error('Export failed');
      }

      // Get filename from Content-Disposition header or use default
      const contentDisposition = response.headers.get('Content-Disposition');
      const filenameMatch = contentDisposition?.match(/filename="(.+)"/);
      const filename = filenameMatch ? filenameMatch[1] : `user-${params.id}-export.json`;

      // Download the file
      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    } catch (err: any) {
      alert(`Export failed: ${err.message}`);
    } finally {
      setIsExporting(false);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  const formatMinutesToHours = (minutes: number) => {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    const sign = minutes < 0 ? '-' : '+';
    return `${sign}${Math.abs(hours)}h ${Math.abs(mins)}m`;
  };

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex justify-center py-12">
          <div className="text-gray-500">Loading user details...</div>
        </div>
      </AdminLayout>
    );
  }

  if (error || !userDetail) {
    return (
      <AdminLayout>
        <div className="space-y-6">
          <button
            onClick={() => router.back()}
            className="text-sm text-blue-600 hover:text-blue-800"
          >
            ← Back to Users
          </button>
          <div className="rounded-md bg-red-50 p-4">
            <div className="text-sm text-red-800">{error || 'User not found'}</div>
          </div>
        </div>
      </AdminLayout>
    );
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <button
              onClick={() => router.back()}
              className="text-sm text-blue-600 hover:text-blue-800 mb-2"
            >
              ← Back to Users
            </button>
            <h1 className="text-2xl font-bold text-gray-900">
              {userDetail.profile.first_name || userDetail.profile.last_name
                ? `${userDetail.profile.first_name || ''} ${userDetail.profile.last_name || ''}`.trim()
                : 'User Details'}
            </h1>
            <p className="mt-1 text-sm text-gray-500">
              {userDetail.profile.email}
            </p>
          </div>
          <button
            onClick={handleExport}
            disabled={isExporting}
            className="rounded-md bg-green-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-green-500 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isExporting ? 'Exporting...' : '⬇ Download Debug Bundle'}
          </button>
        </div>

        {/* Profile Card */}
        <div className="bg-white shadow sm:rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg font-medium leading-6 text-gray-900 mb-4">Profile</h3>
            <dl className="grid grid-cols-1 gap-x-4 gap-y-4 sm:grid-cols-2">
              <div>
                <dt className="text-sm font-medium text-gray-500">User ID</dt>
                <dd className="mt-1 text-sm text-gray-900 font-mono">{userDetail.profile.id}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Email</dt>
                <dd className="mt-1 text-sm text-gray-900">{userDetail.profile.email}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Name</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  {userDetail.profile.first_name || userDetail.profile.last_name
                    ? `${userDetail.profile.first_name || ''} ${userDetail.profile.last_name || ''}`.trim()
                    : '-'}
                </dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Joined</dt>
                <dd className="mt-1 text-sm text-gray-900">{formatDate(userDetail.profile.created_at)}</dd>
              </div>
            </dl>
          </div>
        </div>

        {/* Contract Settings Card */}
        <div className="bg-white shadow sm:rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg font-medium leading-6 text-gray-900 mb-4">Contract Settings</h3>
            <dl className="grid grid-cols-1 gap-x-4 gap-y-4 sm:grid-cols-2">
              <div>
                <dt className="text-sm font-medium text-gray-500">Tracking Start Date</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  {userDetail.contract.tracking_start_date
                    ? formatDate(userDetail.contract.tracking_start_date)
                    : 'Not configured'}
                </dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Opening Balance</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  {formatMinutesToHours(userDetail.contract.opening_flex_minutes || 0)}
                </dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Weekly Hours</dt>
                <dd className="mt-1 text-sm text-gray-900">{userDetail.contract.full_time_hours || 40}h</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Contract Percent</dt>
                <dd className="mt-1 text-sm text-gray-900">{userDetail.contract.contract_percent || 100}%</dd>
              </div>
            </dl>
          </div>
        </div>

        {/* Balance Summary Card */}
        <div className="bg-white shadow sm:rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg font-medium leading-6 text-gray-900 mb-4">Balance Summary</h3>
            {userDetail.balances ? (
              <dl className="grid grid-cols-1 gap-x-4 gap-y-4 sm:grid-cols-3">
                <div>
                  <dt className="text-sm font-medium text-gray-500">Balance Today</dt>
                  <dd className={`mt-1 text-lg font-semibold ${userDetail.balances.balanceToday >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                    {formatMinutesToHours(userDetail.balances.balanceToday)}
                  </dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-gray-500">This Month Net</dt>
                  <dd className={`mt-1 text-lg font-semibold ${userDetail.balances.monthNet >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                    {formatMinutesToHours(userDetail.balances.monthNet)}
                  </dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-gray-500">This Year Net</dt>
                  <dd className={`mt-1 text-lg font-semibold ${userDetail.balances.yearNet >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                    {formatMinutesToHours(userDetail.balances.yearNet)}
                  </dd>
                </div>
              </dl>
            ) : (
              <div className="text-sm text-gray-500">
                Balance calculation not available (tracking not configured)
              </div>
            )}
          </div>
        </div>

        {/* Data Counts Card */}
        <div className="bg-white shadow sm:rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg font-medium leading-6 text-gray-900 mb-4">Data Summary</h3>
            <dl className="grid grid-cols-2 gap-x-4 gap-y-4 sm:grid-cols-4">
              <div>
                <dt className="text-sm font-medium text-gray-500">Entries</dt>
                <dd className="mt-1 text-2xl font-semibold text-gray-900">{userDetail.counts.entries}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Absences</dt>
                <dd className="mt-1 text-2xl font-semibold text-gray-900">{userDetail.counts.absences}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Adjustments</dt>
                <dd className="mt-1 text-2xl font-semibold text-gray-900">{userDetail.counts.adjustments}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Red Days</dt>
                <dd className="mt-1 text-2xl font-semibold text-gray-900">{userDetail.counts.redDays}</dd>
              </div>
            </dl>
          </div>
        </div>
      </div>
    </AdminLayout>
  );
}
