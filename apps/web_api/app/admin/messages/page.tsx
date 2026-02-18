'use client';

import { useEffect, useState } from 'react';
import AdminLayout from '@/components/AdminLayout';

interface AppMessage {
  id: string;
  title: string;
  body: string;
  type: string;
  is_active: boolean;
  starts_at: string;
  expires_at: string | null;
  min_app_version: string | null;
  max_app_version: string | null;
  action_url: string | null;
  action_label: string | null;
  is_dismissible: boolean;
  created_at: string;
}

const MESSAGE_TYPES = ['info', 'warning', 'update', 'maintenance'] as const;

const typeBadgeClasses: Record<string, string> = {
  info: 'bg-blue-100 text-blue-800',
  warning: 'bg-yellow-100 text-yellow-800',
  update: 'bg-purple-100 text-purple-800',
  maintenance: 'bg-orange-100 text-orange-800',
};

export default function AdminMessagesPage() {
  const [messages, setMessages] = useState<AppMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving] = useState(false);
  const [editingMsg, setEditingMsg] = useState<AppMessage | null>(null);

  // Form fields
  const [formTitle, setFormTitle] = useState('');
  const [formBody, setFormBody] = useState('');
  const [formType, setFormType] = useState('info');
  const [formIsActive, setFormIsActive] = useState(true);
  const [formStartsAt, setFormStartsAt] = useState('');
  const [formExpiresAt, setFormExpiresAt] = useState('');
  const [formMinVersion, setFormMinVersion] = useState('');
  const [formMaxVersion, setFormMaxVersion] = useState('');
  const [formActionUrl, setFormActionUrl] = useState('');
  const [formActionLabel, setFormActionLabel] = useState('');
  const [formIsDismissible, setFormIsDismissible] = useState(true);

  useEffect(() => {
    fetchMessages();
  }, []);

  const fetchMessages = async () => {
    try {
      setLoading(true);
      const response = await fetch('/api/admin/messages');
      if (!response.ok) throw new Error('Failed to fetch');
      const data = await response.json();
      setMessages(data.messages || []);
      setError('');
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to load messages');
    } finally {
      setLoading(false);
    }
  };

  const openCreateForm = () => {
    setEditingMsg(null);
    setFormTitle('');
    setFormBody('');
    setFormType('info');
    setFormIsActive(true);
    setFormStartsAt(toLocalDatetime(new Date().toISOString()));
    setFormExpiresAt('');
    setFormMinVersion('');
    setFormMaxVersion('');
    setFormActionUrl('');
    setFormActionLabel('');
    setFormIsDismissible(true);
    setShowForm(true);
  };

  const openEditForm = (msg: AppMessage) => {
    setEditingMsg(msg);
    setFormTitle(msg.title);
    setFormBody(msg.body);
    setFormType(msg.type);
    setFormIsActive(msg.is_active);
    setFormStartsAt(toLocalDatetime(msg.starts_at));
    setFormExpiresAt(msg.expires_at ? toLocalDatetime(msg.expires_at) : '');
    setFormMinVersion(msg.min_app_version || '');
    setFormMaxVersion(msg.max_app_version || '');
    setFormActionUrl(msg.action_url || '');
    setFormActionLabel(msg.action_label || '');
    setFormIsDismissible(msg.is_dismissible);
    setShowForm(true);
  };

  const toLocalDatetime = (iso: string) => {
    try {
      const d = new Date(iso);
      return d.toISOString().slice(0, 16);
    } catch {
      return '';
    }
  };

  const handleSave = async () => {
    if (!formTitle.trim() || !formBody.trim()) {
      setError('Title and body are required');
      return;
    }
    setSaving(true);
    setError('');

    const payload = {
      title: formTitle,
      messageBody: formBody,
      type: formType,
      is_active: formIsActive,
      starts_at: formStartsAt ? new Date(formStartsAt).toISOString() : new Date().toISOString(),
      expires_at: formExpiresAt ? new Date(formExpiresAt).toISOString() : null,
      min_app_version: formMinVersion || null,
      max_app_version: formMaxVersion || null,
      action_url: formActionUrl || null,
      action_label: formActionLabel || null,
      is_dismissible: formIsDismissible,
    };

    try {
      if (editingMsg) {
        const response = await fetch('/api/admin/messages', {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ id: editingMsg.id, ...payload }),
        });
        if (!response.ok) throw new Error('Failed to update');
      } else {
        // For create, use 'body' directly
        const createPayload = { ...payload, body: formBody };
        delete (createPayload as Record<string, unknown>).messageBody;
        const response = await fetch('/api/admin/messages', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(createPayload),
        });
        if (!response.ok) throw new Error('Failed to create');
      }

      setShowForm(false);
      fetchMessages();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to save');
    } finally {
      setSaving(false);
    }
  };

  const handleToggleActive = async (msg: AppMessage) => {
    try {
      const response = await fetch('/api/admin/messages', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: msg.id, is_active: !msg.is_active }),
      });
      if (!response.ok) throw new Error('Failed to update');
      fetchMessages();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to toggle');
    }
  };

  const handleDelete = async (msg: AppMessage) => {
    if (!confirm(`Delete message "${msg.title}"? This cannot be undone.`)) return;
    try {
      const response = await fetch(`/api/admin/messages?id=${msg.id}`, {
        method: 'DELETE',
      });
      if (!response.ok) throw new Error('Failed to delete');
      fetchMessages();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to delete');
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">App Messages</h1>
            <p className="mt-1 text-sm text-gray-500">
              In-app announcements shown to users (info, warnings, updates, maintenance)
            </p>
          </div>
          <button
            onClick={openCreateForm}
            className="rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500"
          >
            New Message
          </button>
        </div>

        {error && (
          <div className="rounded-md bg-red-50 p-4">
            <div className="flex justify-between items-center">
              <span className="text-sm text-red-800">{error}</span>
              <button onClick={() => setError('')} className="text-red-600 text-sm">
                Dismiss
              </button>
            </div>
          </div>
        )}

        {loading ? (
          <div className="flex justify-center py-12">
            <div className="text-gray-500">Loading...</div>
          </div>
        ) : messages.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-500">No app messages yet.</p>
            <button
              onClick={openCreateForm}
              className="mt-4 text-sm text-blue-600 hover:text-blue-500"
            >
              Create the first message
            </button>
          </div>
        ) : (
          <div className="overflow-hidden bg-white shadow sm:rounded-lg">
            <table className="min-w-full divide-y divide-gray-300">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                    Title
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                    Type
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                    Starts
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                    Expires
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium uppercase tracking-wide text-gray-500">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 bg-white">
                {messages.map((msg) => (
                  <tr key={msg.id}>
                    <td className="px-6 py-4 text-sm font-medium text-gray-900">
                      <div>{msg.title}</div>
                      <div className="text-xs text-gray-400 mt-0.5 truncate max-w-xs">
                        {msg.body}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm">
                      <span
                        className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${
                          typeBadgeClasses[msg.type] || 'bg-gray-100 text-gray-800'
                        }`}
                      >
                        {msg.type}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm">
                      {msg.is_active ? (
                        <span className="inline-flex rounded-full bg-green-100 px-2 text-xs font-semibold leading-5 text-green-800">
                          Active
                        </span>
                      ) : (
                        <span className="inline-flex rounded-full bg-gray-100 px-2 text-xs font-semibold leading-5 text-gray-600">
                          Inactive
                        </span>
                      )}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-500">
                      {formatDate(msg.starts_at)}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-500">
                      {msg.expires_at ? formatDate(msg.expires_at) : '-'}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-right text-sm space-x-2">
                      <button
                        onClick={() => handleToggleActive(msg)}
                        className={`font-medium ${
                          msg.is_active
                            ? 'text-yellow-600 hover:text-yellow-800'
                            : 'text-green-600 hover:text-green-800'
                        }`}
                      >
                        {msg.is_active ? 'Deactivate' : 'Activate'}
                      </button>
                      <button
                        onClick={() => openEditForm(msg)}
                        className="text-blue-600 hover:text-blue-800 font-medium"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => handleDelete(msg)}
                        className="text-red-600 hover:text-red-800 font-medium"
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Create/Edit Modal */}
        {showForm && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
            <div className="w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-lg bg-white p-6 shadow-xl">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">
                {editingMsg ? 'Edit Message' : 'New App Message'}
              </h2>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Title</label>
                  <input
                    type="text"
                    value={formTitle}
                    onChange={(e) => setFormTitle(e.target.value)}
                    className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500"
                    placeholder="Message title"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Body</label>
                  <textarea
                    value={formBody}
                    onChange={(e) => setFormBody(e.target.value)}
                    rows={4}
                    className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500"
                    placeholder="Message body text"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
                    <select
                      value={formType}
                      onChange={(e) => setFormType(e.target.value)}
                      className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500"
                    >
                      {MESSAGE_TYPES.map((t) => (
                        <option key={t} value={t}>
                          {t.charAt(0).toUpperCase() + t.slice(1)}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="flex items-end gap-4">
                    <label className="flex items-center gap-2 text-sm text-gray-700">
                      <input
                        type="checkbox"
                        checked={formIsActive}
                        onChange={(e) => setFormIsActive(e.target.checked)}
                        className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                      />
                      Active
                    </label>
                    <label className="flex items-center gap-2 text-sm text-gray-700">
                      <input
                        type="checkbox"
                        checked={formIsDismissible}
                        onChange={(e) => setFormIsDismissible(e.target.checked)}
                        className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                      />
                      Dismissible
                    </label>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Starts at</label>
                    <input
                      type="datetime-local"
                      value={formStartsAt}
                      onChange={(e) => setFormStartsAt(e.target.value)}
                      className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Expires at <span className="text-gray-400">(optional)</span>
                    </label>
                    <input
                      type="datetime-local"
                      value={formExpiresAt}
                      onChange={(e) => setFormExpiresAt(e.target.value)}
                      className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Min App Version <span className="text-gray-400">(optional)</span>
                    </label>
                    <input
                      type="text"
                      value={formMinVersion}
                      onChange={(e) => setFormMinVersion(e.target.value)}
                      className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500"
                      placeholder="e.g. 1.0.0"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Max App Version <span className="text-gray-400">(optional)</span>
                    </label>
                    <input
                      type="text"
                      value={formMaxVersion}
                      onChange={(e) => setFormMaxVersion(e.target.value)}
                      className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500"
                      placeholder="e.g. 2.0.0"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Action URL <span className="text-gray-400">(optional)</span>
                    </label>
                    <input
                      type="text"
                      value={formActionUrl}
                      onChange={(e) => setFormActionUrl(e.target.value)}
                      className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500"
                      placeholder="https://..."
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Action Label <span className="text-gray-400">(optional)</span>
                    </label>
                    <input
                      type="text"
                      value={formActionLabel}
                      onChange={(e) => setFormActionLabel(e.target.value)}
                      className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500"
                      placeholder="e.g. Update Now"
                    />
                  </div>
                </div>
              </div>

              <div className="mt-6 flex justify-end gap-3">
                <button
                  onClick={() => setShowForm(false)}
                  className="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-700 border border-gray-300 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSave}
                  disabled={saving}
                  className="rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 disabled:opacity-50"
                >
                  {saving ? 'Saving...' : editingMsg ? 'Update' : 'Create'}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
