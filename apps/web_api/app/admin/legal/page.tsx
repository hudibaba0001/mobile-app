'use client';

import { useEffect, useState } from 'react';
import AdminLayout from '@/components/AdminLayout';

interface LegalDocument {
  id: string;
  type: 'terms' | 'privacy';
  title: string;
  content: string;
  version: string;
  is_current: boolean;
  created_at: string;
}

type DocType = 'terms' | 'privacy';

export default function AdminLegalPage() {
  const [documents, setDocuments] = useState<LegalDocument[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [activeTab, setActiveTab] = useState<DocType>('terms');
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving] = useState(false);
  const [editingDoc, setEditingDoc] = useState<LegalDocument | null>(null);

  // Form fields
  const [formTitle, setFormTitle] = useState('');
  const [formContent, setFormContent] = useState('');
  const [formVersion, setFormVersion] = useState('');
  const [formIsCurrent, setFormIsCurrent] = useState(false);

  useEffect(() => {
    fetchDocuments();
  }, []);

  const fetchDocuments = async () => {
    try {
      setLoading(true);
      const response = await fetch('/api/admin/legal');
      if (!response.ok) throw new Error('Failed to fetch');
      const data = await response.json();
      setDocuments(data.documents || []);
      setError('');
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to load documents');
    } finally {
      setLoading(false);
    }
  };

  const filteredDocs = documents.filter((d) => d.type === activeTab);

  const openCreateForm = () => {
    setEditingDoc(null);
    setFormTitle('');
    setFormContent('');
    setFormVersion('');
    setFormIsCurrent(false);
    setShowForm(true);
  };

  const openEditForm = (doc: LegalDocument) => {
    setEditingDoc(doc);
    setFormTitle(doc.title);
    setFormContent(doc.content);
    setFormVersion(doc.version);
    setFormIsCurrent(doc.is_current);
    setShowForm(true);
  };

  const handleSave = async () => {
    if (!formTitle.trim() || !formContent.trim()) {
      setError('Title and content are required');
      return;
    }
    setSaving(true);
    setError('');

    try {
      if (editingDoc) {
        // Update
        const response = await fetch('/api/admin/legal', {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            id: editingDoc.id,
            title: formTitle,
            content: formContent,
            version: formVersion,
            is_current: formIsCurrent,
          }),
        });
        if (!response.ok) throw new Error('Failed to update');
      } else {
        // Create
        const response = await fetch('/api/admin/legal', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            type: activeTab,
            title: formTitle,
            content: formContent,
            version: formVersion,
            is_current: formIsCurrent,
          }),
        });
        if (!response.ok) throw new Error('Failed to create');
      }

      setShowForm(false);
      fetchDocuments();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to save');
    } finally {
      setSaving(false);
    }
  };

  const handleSetCurrent = async (doc: LegalDocument) => {
    try {
      const response = await fetch('/api/admin/legal', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: doc.id, is_current: true }),
      });
      if (!response.ok) throw new Error('Failed to update');
      fetchDocuments();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to set as current');
    }
  };

  const handleDelete = async (doc: LegalDocument) => {
    if (!confirm(`Delete "${doc.title}"? This cannot be undone.`)) return;
    try {
      const response = await fetch(`/api/admin/legal?id=${doc.id}`, {
        method: 'DELETE',
      });
      if (!response.ok) throw new Error('Failed to delete');
      fetchDocuments();
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
            <h1 className="text-2xl font-bold text-gray-900">Legal Documents</h1>
            <p className="mt-1 text-sm text-gray-500">
              Manage Terms of Service and Privacy Policy
            </p>
          </div>
          <button
            onClick={openCreateForm}
            className="rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500"
          >
            New Document
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

        {/* Tabs */}
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex space-x-8">
            {(['terms', 'privacy'] as DocType[]).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium ${
                  activeTab === tab
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
                }`}
              >
                {tab === 'terms' ? 'Terms of Service' : 'Privacy Policy'}
              </button>
            ))}
          </nav>
        </div>

        {loading ? (
          <div className="flex justify-center py-12">
            <div className="text-gray-500">Loading...</div>
          </div>
        ) : filteredDocs.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-500">
              No {activeTab === 'terms' ? 'Terms of Service' : 'Privacy Policy'} documents yet.
            </p>
            <button
              onClick={openCreateForm}
              className="mt-4 text-sm text-blue-600 hover:text-blue-500"
            >
              Create the first one
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
                    Version
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                    Created
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium uppercase tracking-wide text-gray-500">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 bg-white">
                {filteredDocs.map((doc) => (
                  <tr key={doc.id}>
                    <td className="px-6 py-4 text-sm font-medium text-gray-900">
                      {doc.title}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">{doc.version}</td>
                    <td className="px-6 py-4 text-sm">
                      {doc.is_current ? (
                        <span className="inline-flex rounded-full bg-green-100 px-2 text-xs font-semibold leading-5 text-green-800">
                          Current
                        </span>
                      ) : (
                        <span className="inline-flex rounded-full bg-gray-100 px-2 text-xs font-semibold leading-5 text-gray-600">
                          Archived
                        </span>
                      )}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-500">
                      {formatDate(doc.created_at)}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-right text-sm space-x-2">
                      {!doc.is_current && (
                        <button
                          onClick={() => handleSetCurrent(doc)}
                          className="text-green-600 hover:text-green-800 font-medium"
                        >
                          Set Current
                        </button>
                      )}
                      <button
                        onClick={() => openEditForm(doc)}
                        className="text-blue-600 hover:text-blue-800 font-medium"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => handleDelete(doc)}
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
                {editingDoc ? 'Edit Document' : `New ${activeTab === 'terms' ? 'Terms of Service' : 'Privacy Policy'}`}
              </h2>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Title
                  </label>
                  <input
                    type="text"
                    value={formTitle}
                    onChange={(e) => setFormTitle(e.target.value)}
                    className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500"
                    placeholder="e.g. Terms of Service v2.0"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Version
                  </label>
                  <input
                    type="text"
                    value={formVersion}
                    onChange={(e) => setFormVersion(e.target.value)}
                    className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500"
                    placeholder="e.g. 2.0"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Content (Markdown)
                  </label>
                  <textarea
                    value={formContent}
                    onChange={(e) => setFormContent(e.target.value)}
                    rows={12}
                    className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm font-mono focus:border-blue-500 focus:ring-blue-500"
                    placeholder="Write the document content in Markdown..."
                  />
                </div>

                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="is_current"
                    checked={formIsCurrent}
                    onChange={(e) => setFormIsCurrent(e.target.checked)}
                    className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <label htmlFor="is_current" className="text-sm text-gray-700">
                    Set as current version (shown to users in the app)
                  </label>
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
                  {saving ? 'Saving...' : editingDoc ? 'Update' : 'Create'}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
