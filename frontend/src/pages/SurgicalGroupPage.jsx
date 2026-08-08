import React, { useState, useEffect } from 'react';
import surgicalGroupApi from '../services/surgicalGroupApi';
import Pagination from '../components/Pagination';

const SurgicalGroupPage = () => {
  const [groups, setGroups] = useState([]);
  const [filteredGroups, setFilteredGroups] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [editingGroup, setEditingGroup] = useState(null);

  const [lookupData, setLookupData] = useState({
    branches: []
  });

  const [formData, setFormData] = useState({
    name: '',
    subServiceId: '',
    description: ''
  });

  const [entriesPerPage, setEntriesPerPage] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchGroups();
    fetchLookupData();
  }, []);

  useEffect(() => {
    filterGroups();
  }, [groups, searchTerm]);

  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, entriesPerPage]);

  const fetchGroups = async () => {
    try {
      setLoading(true);
      const data = await surgicalGroupApi.getAll();
      setGroups(data);
      setFilteredGroups(data);
      setError(null);
    } catch (err) {
      console.error('Error fetching groups:', err);
      setError('Failed to fetch surgical groups. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const fetchLookupData = async () => {
    try {
      const data = await surgicalGroupApi.getLookupData();
      setLookupData(data);
    } catch (err) {
      console.error('Error fetching lookup data:', err);
    }
  };

  const filterGroups = () => {
    let filtered = [...groups];

    if (searchTerm) {
      filtered = filtered.filter(group =>
        group.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        group.subServiceId?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        group.description?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredGroups(filtered);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleAdd = () => {
    setEditingGroup(null);
    setFormData({
      name: '',
      subServiceId: '',
      description: ''
    });
    setShowForm(true);
  };

  const handleEdit = (group) => {
    setEditingGroup(group);
    setFormData({
      name: group.name || '',
      subServiceId: group.subServiceId || '',
      description: group.description || ''
    });
    setShowForm(true);
  };

  const handleCancel = () => {
    setShowForm(false);
    setEditingGroup(null);
    setFormData({
      name: '',
      subServiceId: '',
      description: ''
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    try {
      setLoading(true);
      
      const submitData = {
        name: formData.name,
        subServiceId: formData.subServiceId,
        description: formData.description,
        branchId: 1 // Default branch
      };

      if (editingGroup) {
        await surgicalGroupApi.update(editingGroup.id, submitData);
      } else {
        await surgicalGroupApi.create(submitData);
      }

      await fetchGroups();
      handleCancel();
      setError(null);
    } catch (err) {
      console.error('Error saving group:', err);
      setError('Failed to save surgical group. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this surgical group?')) {
      return;
    }

    try {
      setLoading(true);
      await surgicalGroupApi.delete(id);
      await fetchGroups();
      setError(null);
    } catch (err) {
      console.error('Error deleting group:', err);
      setError('Failed to delete surgical group. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  if (showForm) {
    return (
      <div className="p-6">
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-gray-800">
            {editingGroup ? 'Edit' : 'Add'} Multiple Surgical Group
          </h1>
        </div>

        {error && (
          <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-md">
            {error}
          </div>
        )}

        <div className="bg-white rounded-lg shadow p-6">
          <form onSubmit={handleSubmit}>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              {/* Name */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Name <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleInputChange}
                  required
                  placeholder="Enter Name"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              {/* Service */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Service <span className="text-red-500">*</span>
                </label>
                <select
                  name="subServiceId"
                  value={formData.subServiceId}
                  onChange={handleInputChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Select Service</option>
                  <option value="CT Scan Cardiac Angio">CT Scan Cardiac Angio</option>
                  <option value="Oscant Heart Rate Fusable with ZEROK Ig">Oscant Heart Rate Fusable with ZEROK Ig</option>
                  <option value="Cardiac Catheterization">Cardiac Catheterization</option>
                  <option value="Echocardiography">Echocardiography</option>
                  <option value="Stress Test">Stress Test</option>
                  <option value="Holter Monitoring">Holter Monitoring</option>
                  <option value="Angioplasty">Angioplasty</option>
                  <option value="Pacemaker Implantation">Pacemaker Implantation</option>
                  <option value="Cardiac Surgery">Cardiac Surgery</option>
                  <option value="Other">Other</option>
                </select>
              </div>
            </div>

            {/* Description */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Description
              </label>
              <textarea
                name="description"
                value={formData.description}
                onChange={handleInputChange}
                placeholder="Enter Description"
                rows="4"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* Action Buttons */}
            <div className="flex justify-end gap-2">
              <button
                type="button"
                onClick={handleCancel}
                className="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-gray-400"
              >
                {loading ? 'Saving...' : editingGroup ? 'Submit' : 'Submit'}
              </button>
            </div>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-800 flex items-center">
          <span className="mr-2">🏥</span>
          Multiple Surgical Group
          <span className="ml-2 text-blue-600 cursor-pointer">ⓘ</span>
        </h1>
        <button
          onClick={handleAdd}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 flex items-center gap-2"
        >
          <span className="text-xl">+</span>
          Add Surgical Group
        </button>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-md">
          {error}
        </div>
      )}

      {/* Table Controls */}
      <div className="mb-4 flex justify-end items-center">
        <div className="flex items-center gap-2">
          <span className="text-sm text-gray-700">Search:</span>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Service
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Description
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {loading ? (
                <tr>
                  <td colSpan="4" className="px-6 py-4 text-center text-sm text-gray-500">
                    Loading...
                  </td>
                </tr>
              ) : filteredGroups.length === 0 ? (
                <tr>
                  <td colSpan="4" className="px-6 py-4 text-center text-sm text-gray-500">
                    No data available in table
                  </td>
                </tr>
              ) : (
                filteredGroups.slice((currentPage - 1) * entriesPerPage, currentPage * entriesPerPage).map((group) => (
                  <tr key={group.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-900">
                      {group.name || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {group.subServiceId || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {group.description || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm">
                      <button
                        onClick={() => handleDelete(group.id)}
                        className="text-red-600 hover:text-red-800"
                        title="Delete"
                      >
                        🗑️
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Pagination
        currentPage={currentPage}
        pageSize={entriesPerPage}
        totalCount={filteredGroups.length}
        onPageChange={setCurrentPage}
        onPageSizeChange={setEntriesPerPage}
      />
    </div>
  );
};

export default SurgicalGroupPage;
