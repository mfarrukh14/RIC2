import React, { useEffect, useMemo, useState } from 'react';
import {
  CheckIcon,
  ClipboardDocumentListIcon,
  InformationCircleIcon,
  PencilSquareIcon,
  PlusIcon,
  Squares2X2Icon,
  XMarkIcon
} from '@heroicons/react/24/outline';
import demandRequestStatusApi from '../services/demandRequestStatusApi';

function emptyForm() {
  return {
    name: '',
    description: '',
    isActive: true
  };
}

const DemandRequestStatusPage = () => {
  const [statuses, setStatuses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [entriesPerPage, setEntriesPerPage] = useState(5);
  const [currentPage, setCurrentPage] = useState(1);
  const [showForm, setShowForm] = useState(false);
  const [editingStatus, setEditingStatus] = useState(null);
  const [form, setForm] = useState(emptyForm);

  useEffect(() => {
    loadStatuses();
  }, []);

  const loadStatuses = async () => {
    setLoading(true);
    setError('');

    try {
      const data = await demandRequestStatusApi.getAll();
      setStatuses(data);
    } catch (requestError) {
      console.error('Error loading demand request statuses:', requestError);
      setError('Failed to load demand request statuses.');
    } finally {
      setLoading(false);
    }
  };

  const filteredStatuses = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase();

    if (!normalizedSearch) {
      return statuses;
    }

    return statuses.filter((status) => [status.name, status.description]
      .some((value) => (value || '').toLowerCase().includes(normalizedSearch)));
  }, [searchTerm, statuses]);

  useEffect(() => {
    setCurrentPage(1);
  }, [entriesPerPage, searchTerm]);

  const totalPages = Math.max(1, Math.ceil(filteredStatuses.length / entriesPerPage));
  const startIndex = (currentPage - 1) * entriesPerPage;
  const pageItems = filteredStatuses.slice(startIndex, startIndex + entriesPerPage);
  const showingFrom = filteredStatuses.length === 0 ? 0 : startIndex + 1;
  const showingTo = Math.min(startIndex + entriesPerPage, filteredStatuses.length);

  const handleOpenCreate = () => {
    setEditingStatus(null);
    setForm(emptyForm());
    setShowForm(true);
    setError('');
  };

  const handleOpenEdit = (status) => {
    setEditingStatus(status);
    setForm({
      name: status.name || '',
      description: status.description || '',
      isActive: Boolean(status.isActive)
    });
    setShowForm(true);
    setError('');
  };

  const handleCancel = () => {
    setShowForm(false);
    setEditingStatus(null);
    setForm(emptyForm());
    setError('');
  };

  const handleChange = (event) => {
    const { name, value, type, checked } = event.target;
    setForm((current) => ({
      ...current,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!form.name.trim()) {
      setError('Name is required.');
      return;
    }

    setSaving(true);
    setError('');

    try {
      const payload = {
        name: form.name.trim(),
        description: form.description.trim() || null,
        isActive: form.isActive
      };

      if (editingStatus) {
        await demandRequestStatusApi.update(editingStatus.demandRequestStatusId, payload);
      } else {
        await demandRequestStatusApi.create(payload);
      }

      await loadStatuses();
      handleCancel();
    } catch (saveError) {
      console.error('Error saving demand request status:', saveError);
      setError('Failed to save demand request status.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        {!showForm ? (
          <section className="rounded-md border border-slate-200 bg-white shadow-sm">
            <div className="flex flex-col gap-4 border-b border-slate-100 px-4 py-3 lg:flex-row lg:items-center lg:justify-between">
              <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
                <ClipboardDocumentListIcon className="h-5 w-5 text-indigo-500" />
                Demand Request Status
                <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
              </h1>

              <button
                type="button"
                onClick={handleOpenCreate}
                className="inline-flex items-center gap-2 rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-indigo-700"
              >
                <PlusIcon className="h-4 w-4" />
                Add Demand Request Status
              </button>
            </div>

            <div className="flex flex-col gap-3 px-4 py-4 md:flex-row md:items-center md:justify-between">
              <div className="flex items-center gap-2 text-sm text-slate-600">
                <span>Show</span>
                <select
                  value={entriesPerPage}
                  onChange={(event) => setEntriesPerPage(Number(event.target.value))}
                  className="rounded-md border border-slate-200 px-2 py-1 text-sm"
                >
                  {[5, 10, 25, 50].map((size) => (
                    <option key={size} value={size}>{size}</option>
                  ))}
                </select>
                <span>entries</span>
              </div>

              <label className="flex items-center gap-2 text-sm text-slate-600">
                <span>Search:</span>
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(event) => setSearchTerm(event.target.value)}
                  className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400 md:w-60"
                />
              </label>
            </div>

            {error ? (
              <div className="px-4 pb-4 text-sm text-rose-600">{error}</div>
            ) : loading ? (
              <div className="px-4 pb-4 text-sm text-slate-500">Loading demand request statuses...</div>
            ) : (
              <>
                <div className="overflow-x-auto px-4">
                  <table className="min-w-full border-separate border-spacing-0 text-sm">
                    <thead>
                      <tr className="text-left text-slate-700">
                        <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Name</th>
                        <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Description</th>
                        <th className="border-y border-slate-200 bg-white px-6 py-4 text-center font-semibold">Status</th>
                        <th className="border-y border-slate-200 bg-white px-6 py-4 text-center font-semibold">Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      {pageItems.length === 0 ? (
                        <tr>
                          <td colSpan="4" className="border-b border-slate-200 px-4 py-12 text-center text-slate-500">
                            No data available in table
                          </td>
                        </tr>
                      ) : (
                        pageItems.map((status) => (
                          <tr key={status.demandRequestStatusId} className="text-slate-700">
                            <td className="border-b border-slate-200 px-6 py-6 align-middle">{status.name}</td>
                            <td className="border-b border-slate-200 px-6 py-6 align-middle">{status.description || '-'}</td>
                            <td className="border-b border-slate-200 px-6 py-6 text-center align-middle">
                              {status.isActive ? (
                                <CheckIcon className="mx-auto h-5 w-5 text-slate-900" />
                              ) : (
                                <XMarkIcon className="mx-auto h-5 w-5 text-slate-900" />
                              )}
                            </td>
                            <td className="border-b border-slate-200 px-6 py-6 align-middle">
                              <div className="flex items-center justify-center gap-3 text-indigo-400">
                                <button type="button" className="transition hover:text-indigo-600" title="View">
                                  <Squares2X2Icon className="h-5 w-5" />
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleOpenEdit(status)}
                                  className="transition hover:text-indigo-600"
                                  title="Edit"
                                >
                                  <PencilSquareIcon className="h-5 w-5" />
                                </button>
                              </div>
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                    <tfoot>
                      <tr className="text-left text-slate-700">
                        <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Name</th>
                        <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Description</th>
                        <th className="border-b border-slate-200 bg-white px-6 py-4 text-center font-semibold">Status</th>
                        <th className="border-b border-slate-200 bg-white px-6 py-4 text-center font-semibold">Action</th>
                      </tr>
                    </tfoot>
                  </table>
                </div>

                <div className="flex flex-col gap-3 px-4 py-4 text-sm text-slate-600 md:flex-row md:items-center md:justify-between">
                  <div>Showing {showingFrom} to {showingTo} of {filteredStatuses.length} entries</div>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => setCurrentPage((page) => Math.max(page - 1, 1))}
                      disabled={currentPage === 1}
                      className="rounded-md border border-slate-200 px-3 py-2 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                      ‹
                    </button>
                    <span className="rounded-md bg-indigo-600 px-3 py-2 text-white">{currentPage}</span>
                    <button
                      type="button"
                      onClick={() => setCurrentPage((page) => Math.min(page + 1, totalPages))}
                      disabled={currentPage === totalPages}
                      className="rounded-md border border-slate-200 px-3 py-2 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                      ›
                    </button>
                  </div>
                </div>
              </>
            )}
          </section>
        ) : (
          <section className="rounded-md border border-slate-200 bg-white shadow-sm">
            <div className="border-b border-slate-100 px-6 py-3">
              <h1 className="text-2xl font-semibold text-slate-900">{editingStatus ? 'Edit Demand Request Status' : 'Add Demand Request Status'}</h1>
            </div>

            <form onSubmit={handleSubmit} className="space-y-6 px-6 py-5">
              {error && <div className="text-sm text-rose-600">{error}</div>}

              <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1fr_1fr_140px] lg:items-start">
                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Name*</label>
                  <input
                    type="text"
                    name="name"
                    value={form.name}
                    onChange={handleChange}
                    placeholder="Demand Request Status"
                    className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                  />
                </div>

                <div className="lg:col-start-3">
                  <label className="mb-2 block text-sm font-medium text-slate-700">Active</label>
                  <label className="mt-3 inline-flex items-center">
                    <input
                      type="checkbox"
                      name="isActive"
                      checked={form.isActive}
                      onChange={handleChange}
                      className="h-5 w-5 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                    />
                  </label>
                </div>
              </div>

              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Description</label>
                <textarea
                  name="description"
                  value={form.description}
                  onChange={handleChange}
                  rows={4}
                  className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                />
              </div>

              <div className="flex items-center justify-end gap-3">
                <button
                  type="submit"
                  disabled={saving}
                  className="rounded-md bg-indigo-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  {saving ? 'Saving...' : 'Submit'}
                </button>
                <button
                  type="button"
                  onClick={handleCancel}
                  className="rounded-md border border-slate-200 px-5 py-2.5 text-sm font-medium text-slate-600 transition hover:bg-slate-50"
                >
                  Cancel
                </button>
              </div>
            </form>
          </section>
        )}
      </div>
    </div>
  );
};

export default DemandRequestStatusPage;