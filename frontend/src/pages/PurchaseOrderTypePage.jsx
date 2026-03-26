import React, { useEffect, useMemo, useState } from 'react';
import {
  CheckIcon,
  ClipboardDocumentListIcon,
  InformationCircleIcon,
  PencilSquareIcon,
  PlusIcon,
  TrashIcon,
  XMarkIcon
} from '@heroicons/react/24/outline';
import purchaseOrderTypeApi from '../services/purchaseOrderTypeApi';

function emptyForm() {
  return {
    name: '',
    description: '',
    isActive: true
  };
}

const PurchaseOrderTypePage = () => {
  const [types, setTypes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [entriesPerPage, setEntriesPerPage] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [editingType, setEditingType] = useState(null);
  const [showEditModal, setShowEditModal] = useState(false);
  const [form, setForm] = useState(emptyForm);

  useEffect(() => {
    loadTypes();
  }, []);

  const loadTypes = async () => {
    setLoading(true);
    setError('');

    try {
      const data = await purchaseOrderTypeApi.getAll();
      setTypes(data);
    } catch (requestError) {
      console.error('Error loading purchase order types:', requestError);
      setError('Failed to load purchase order types.');
    } finally {
      setLoading(false);
    }
  };

  const filteredTypes = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase();

    if (!normalizedSearch) {
      return types;
    }

    return types.filter((type) => [type.name, type.description]
      .some((value) => (value || '').toLowerCase().includes(normalizedSearch)));
  }, [searchTerm, types]);

  useEffect(() => {
    setCurrentPage(1);
  }, [entriesPerPage, searchTerm]);

  const totalPages = Math.max(1, Math.ceil(filteredTypes.length / entriesPerPage));
  const startIndex = (currentPage - 1) * entriesPerPage;
  const pageItems = filteredTypes.slice(startIndex, startIndex + entriesPerPage);
  const showingFrom = filteredTypes.length === 0 ? 0 : startIndex + 1;
  const showingTo = Math.min(startIndex + entriesPerPage, filteredTypes.length);

  const handleOpenCreate = () => {
    setEditingType(null);
    setForm(emptyForm());
    setShowCreateForm(true);
    setShowEditModal(false);
    setError('');
  };

  const handleOpenEdit = (type) => {
    setEditingType(type);
    setForm({
      name: type.name || '',
      description: type.description || '',
      isActive: Boolean(type.isActive)
    });
    setShowEditModal(true);
    setShowCreateForm(false);
    setError('');
  };

  const handleCancelCreate = () => {
    setShowCreateForm(false);
    setEditingType(null);
    setForm(emptyForm());
    setError('');
  };

  const handleCancelEdit = () => {
    setShowEditModal(false);
    setEditingType(null);
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

      if (editingType) {
        await purchaseOrderTypeApi.update(editingType.purchaseOrderTypeId, payload);
        await loadTypes();
        handleCancelEdit();
      } else {
        await purchaseOrderTypeApi.create(payload);
        await loadTypes();
        handleCancelCreate();
      }
    } catch (saveError) {
      console.error('Error saving purchase order type:', saveError);
      setError(saveError?.response?.data?.message || 'Failed to save purchase order type.');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (type) => {
    if (!window.confirm(`Are you sure you want to delete purchase order type "${type.name}"?`)) {
      return;
    }

    setError('');

    try {
      await purchaseOrderTypeApi.delete(type.purchaseOrderTypeId);
      await loadTypes();
      if (editingType?.purchaseOrderTypeId === type.purchaseOrderTypeId) {
        handleCancelEdit();
      }
    } catch (deleteError) {
      console.error('Error deleting purchase order type:', deleteError);
      setError(deleteError?.response?.data?.message || 'Failed to delete purchase order type.');
    }
  };

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        {!showCreateForm ? (
          <section className="rounded-md border border-slate-200 bg-white shadow-sm">
            <div className="flex flex-col gap-4 border-b border-slate-100 px-4 py-3 lg:flex-row lg:items-center lg:justify-between">
              <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
                <ClipboardDocumentListIcon className="h-5 w-5 text-indigo-500" />
                Purchase Order Types
                <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
              </h1>

              <button
                type="button"
                onClick={handleOpenCreate}
                className="inline-flex items-center gap-2 rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-indigo-700"
              >
                <PlusIcon className="h-4 w-4" />
                Add Purchase Order Type
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
                  {[10, 25, 50].map((size) => (
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
              <div className="px-4 pb-4 text-sm text-slate-500">Loading purchase order types...</div>
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
                        pageItems.map((type) => (
                          <tr key={type.purchaseOrderTypeId} className="text-slate-700">
                            <td className="border-b border-slate-200 px-6 py-6 align-middle">{type.name}</td>
                            <td className="border-b border-slate-200 px-6 py-6 align-middle">{type.description || '-'}</td>
                            <td className="border-b border-slate-200 px-6 py-6 text-center align-middle">
                              {type.isActive ? (
                                <CheckIcon className="mx-auto h-5 w-5 text-slate-900" />
                              ) : (
                                <XMarkIcon className="mx-auto h-5 w-5 text-slate-900" />
                              )}
                            </td>
                            <td className="border-b border-slate-200 px-6 py-6 align-middle">
                              <div className="flex items-center justify-center gap-3">
                                <button
                                  type="button"
                                  onClick={() => handleOpenEdit(type)}
                                  className="text-indigo-400 transition hover:text-indigo-600"
                                  title="Edit"
                                >
                                  <PencilSquareIcon className="h-5 w-5" />
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleDelete(type)}
                                  className="text-rose-500 transition hover:text-rose-700"
                                  title="Delete"
                                >
                                  <TrashIcon className="h-5 w-5" />
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
                  <div>Showing {showingFrom} to {showingTo} of {filteredTypes.length} entries</div>
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
              <h1 className="text-2xl font-semibold text-slate-900">Add Purchase Order Type</h1>
            </div>

            <form onSubmit={handleSubmit} className="space-y-6 px-6 py-5">
              {error && <div className="text-sm text-rose-600">{error}</div>}

              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Active</label>
                <label className="mt-1 inline-flex items-center">
                  <input
                    type="checkbox"
                    name="isActive"
                    checked={form.isActive}
                    onChange={handleChange}
                    className="h-5 w-5 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                  />
                </label>
              </div>

              <div className="max-w-3xl">
                <label className="mb-2 block text-sm font-medium text-slate-700">Name*</label>
                <input
                  type="text"
                  name="name"
                  value={form.name}
                  onChange={handleChange}
                  placeholder="Enter Name"
                  className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                />
              </div>

              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Description</label>
                <textarea
                  name="description"
                  value={form.description}
                  onChange={handleChange}
                  rows={4}
                  placeholder="Enter Description"
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
                  onClick={handleCancelCreate}
                  className="rounded-md border border-slate-200 px-5 py-2.5 text-sm font-medium text-slate-600 transition hover:bg-slate-50"
                >
                  Cancel
                </button>
              </div>
            </form>
          </section>
        )}
      </div>

      {showEditModal && (
        <div className="fixed inset-0 z-50 flex items-start justify-center bg-slate-900/40 p-4 pt-6">
          <div className="w-full max-w-7xl overflow-hidden rounded-md border border-slate-200 bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
              <h3 className="text-[18px] font-medium text-slate-700">Edit Purchase Order Type</h3>
              <button type="button" onClick={handleCancelEdit} className="rounded-md p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600"><XMarkIcon className="h-5 w-5" /></button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-6 px-6 py-5">
              {error && <div className="text-sm text-rose-600">{error}</div>}

              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Active</label>
                <label className="mt-1 inline-flex items-center">
                  <input
                    type="checkbox"
                    name="isActive"
                    checked={form.isActive}
                    onChange={handleChange}
                    className="h-5 w-5 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                  />
                </label>
              </div>

              <div className="max-w-xl">
                <label className="mb-2 block text-sm font-medium text-slate-700">Name*</label>
                <input
                  type="text"
                  name="name"
                  value={form.name}
                  onChange={handleChange}
                  className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                />
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
                  {saving ? 'Saving...' : 'Update'}
                </button>
                <button
                  type="button"
                  onClick={handleCancelEdit}
                  className="rounded-md border border-slate-200 px-5 py-2.5 text-sm font-medium text-slate-600 transition hover:bg-slate-50"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default PurchaseOrderTypePage;