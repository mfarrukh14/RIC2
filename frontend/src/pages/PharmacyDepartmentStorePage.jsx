import React, { useEffect, useState } from 'react';
import { InformationCircleIcon, PencilSquareIcon, TrashIcon } from '@heroicons/react/24/outline';
import pharmacyApi from '../services/pharmacyApi';

function formatDateTime(value) {
  if (!value) return '-';
  return new Date(value).toLocaleString('en-US', {
    month: 'short', day: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false
  });
}

const PharmacyDepartmentStorePage = () => {
  const [mappings, setMappings] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [stores, setStores] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [editingId, setEditingId] = useState(null);
  const [branchDepartmentId, setBranchDepartmentId] = useState('');
  const [pharmacyStoreId, setPharmacyStoreId] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    loadAll();
  }, []);

  const loadAll = async () => {
    setLoading(true);
    setError('');
    try {
      const [mappingData, departmentData, lookupData] = await Promise.all([
        pharmacyApi.getDepartmentStoreMappings(),
        pharmacyApi.getBranchDepartments(),
        pharmacyApi.getLookups()
      ]);
      setMappings(mappingData);
      setDepartments(departmentData);
      setStores(lookupData.stores || []);
    } catch (loadError) {
      console.error('Error loading department store mappings:', loadError);
      setError('Failed to load department store mappings.');
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setEditingId(null);
    setBranchDepartmentId('');
    setPharmacyStoreId('');
  };

  const handleEdit = (mapping) => {
    setEditingId(mapping.id);
    setBranchDepartmentId(String(mapping.branchDepartmentId));
    setPharmacyStoreId(String(mapping.pharmacyStoreId));
  };

  const handleSubmit = async () => {
    if (!branchDepartmentId || !pharmacyStoreId) {
      setError('Select both a department and a pharmacy store.');
      return;
    }

    setSubmitting(true);
    setError('');

    try {
      const payload = { branchDepartmentId: Number(branchDepartmentId), pharmacyStoreId: Number(pharmacyStoreId) };
      if (editingId) {
        await pharmacyApi.updateDepartmentStoreMapping(editingId, payload);
      } else {
        await pharmacyApi.createDepartmentStoreMapping(payload);
      }
      resetForm();
      await loadAll();
    } catch (submitError) {
      console.error('Error saving department store mapping:', submitError);
      setError(submitError.response?.data?.message || 'Failed to save the mapping.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this department store mapping?')) return;

    try {
      await pharmacyApi.deleteDepartmentStoreMapping(id);
      await loadAll();
    } catch (deleteError) {
      console.error('Error deleting mapping:', deleteError);
      setError('Failed to delete the mapping.');
    }
  };

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-6 py-3">
            <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
              Pharmacy Department Store
              <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
            </h1>
          </div>

          {error && <div className="px-6 pt-4 text-sm text-rose-600">{error}</div>}

          <div className="grid grid-cols-1 gap-4 px-6 py-5 lg:grid-cols-[1fr_1fr_auto]">
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Department</label>
              <select
                value={branchDepartmentId}
                onChange={(event) => setBranchDepartmentId(event.target.value)}
                className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              >
                <option value="">Select Department</option>
                {departments.map((department) => (
                  <option key={department.id} value={department.id}>{department.name}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Pharmacy Store</label>
              <select
                value={pharmacyStoreId}
                onChange={(event) => setPharmacyStoreId(event.target.value)}
                className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              >
                <option value="">Select Store</option>
                {stores.map((store) => (
                  <option key={store.id} value={store.id}>{store.name}</option>
                ))}
              </select>
            </div>

            <div className="flex items-end gap-2">
              <button
                type="button"
                onClick={handleSubmit}
                disabled={submitting}
                className="rounded-md bg-indigo-600 px-6 py-3 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-50"
              >
                {submitting ? 'Saving...' : editingId ? 'Update' : 'Submit'}
              </button>
              {editingId && (
                <button type="button" onClick={resetForm} className="rounded-md border border-slate-200 px-4 py-3 text-sm text-slate-600 hover:bg-slate-50">
                  Cancel
                </button>
              )}
            </div>
          </div>

          <div className="overflow-x-auto border-t border-slate-100 px-6 py-4">
            <table className="min-w-full border-separate border-spacing-0 text-sm">
              <thead>
                <tr className="text-left text-slate-700">
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Department</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Pharmacy Store</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Modified On</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Action</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan="4" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">Loading...</td></tr>
                ) : mappings.length === 0 ? (
                  <tr><td colSpan="4" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">No mappings configured yet.</td></tr>
                ) : (
                  mappings.map((mapping) => (
                    <tr key={mapping.id} className="text-slate-700">
                      <td className="border-b border-slate-200 px-4 py-3">{mapping.departmentName}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{mapping.storeName}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{formatDateTime(mapping.modifiedOn)}</td>
                      <td className="border-b border-slate-200 px-4 py-3">
                        <div className="flex items-center gap-3 text-indigo-500">
                          <button type="button" onClick={() => handleEdit(mapping)} className="hover:text-indigo-700">
                            <PencilSquareIcon className="h-4 w-4" />
                          </button>
                          <button type="button" onClick={() => handleDelete(mapping.id)} className="text-rose-500 hover:text-rose-700">
                            <TrashIcon className="h-4 w-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </div>
  );
};

export default PharmacyDepartmentStorePage;
