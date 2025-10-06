import React, { useState, useEffect } from 'react';
import itemTypeSaleLevelApi from '../services/itemTypeSaleLevelApi';

const ItemTypeSaleLevelPage = () => {
  const [levels, setLevels] = useState([]);
  const [filteredLevels, setFilteredLevels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [editingLevel, setEditingLevel] = useState(null);

  const [lookupData, setLookupData] = useState({
    itemTypes: [],
    branches: []
  });

  const [formData, setFormData] = useState({
    itemTypeId: '',
    fastRunningLevel: '',
    slowMovingLevel: '',
    deadLevel: ''
  });

  const [entriesPerPage, setEntriesPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchLevels();
    fetchLookupData();
  }, []);

  useEffect(() => {
    filterLevels();
  }, [levels, searchTerm]);

  const fetchLevels = async () => {
    try {
      setLoading(true);
      const data = await itemTypeSaleLevelApi.getAll();
      setLevels(data);
      setFilteredLevels(data);
      setError(null);
    } catch (err) {
      console.error('Error fetching levels:', err);
      setError('Failed to fetch item type sale levels. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const fetchLookupData = async () => {
    try {
      const data = await itemTypeSaleLevelApi.getLookupData();
      setLookupData(data);
    } catch (err) {
      console.error('Error fetching lookup data:', err);
    }
  };

  const filterLevels = () => {
    let filtered = [...levels];

    if (searchTerm) {
      filtered = filtered.filter(level =>
        level.itemTypeName?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredLevels(filtered);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleAdd = () => {
    setEditingLevel(null);
    setFormData({
      itemTypeId: '',
      fastRunningLevel: '',
      slowMovingLevel: '',
      deadLevel: ''
    });
    setShowForm(true);
  };

  const handleEdit = (level) => {
    setEditingLevel(level);
    setFormData({
      itemTypeId: level.itemTypeId.toString(),
      fastRunningLevel: level.fastRunningLevel.toString(),
      slowMovingLevel: level.slowMovingLevel.toString(),
      deadLevel: level.deadLevel.toString()
    });
    setShowForm(true);
  };

  const handleCancel = () => {
    setShowForm(false);
    setEditingLevel(null);
    setFormData({
      itemTypeId: '',
      fastRunningLevel: '',
      slowMovingLevel: '',
      deadLevel: ''
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    try {
      setLoading(true);
      
      const submitData = {
        itemTypeId: parseInt(formData.itemTypeId),
        fastRunningLevel: parseInt(formData.fastRunningLevel),
        slowMovingLevel: parseInt(formData.slowMovingLevel),
        deadLevel: parseInt(formData.deadLevel),
        branchId: 1 // Default branch
      };

      if (editingLevel) {
        await itemTypeSaleLevelApi.update(editingLevel.id, submitData);
      } else {
        await itemTypeSaleLevelApi.create(submitData);
      }

      await fetchLevels();
      handleCancel();
      setError(null);
    } catch (err) {
      console.error('Error saving level:', err);
      setError('Failed to save item type sale level. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this item type sale level?')) {
      return;
    }

    try {
      setLoading(true);
      await itemTypeSaleLevelApi.delete(id);
      await fetchLevels();
      setError(null);
    } catch (err) {
      console.error('Error deleting level:', err);
      setError('Failed to delete item type sale level. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  if (showForm) {
    return (
      <div className="p-6">
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-gray-800">
            {editingLevel ? 'Edit' : 'Add'} Item Type Sale Level
          </h1>
        </div>

        {error && (
          <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-md">
            {error}
          </div>
        )}

        <div className="bg-white rounded-lg shadow p-6">
          <form onSubmit={handleSubmit}>
            {/* Item Type */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                <span className="text-blue-600">📦</span> Item Type <span className="text-red-500">*</span>
              </label>
              <select
                name="itemTypeId"
                value={formData.itemTypeId}
                onChange={handleInputChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Please select item type</option>
                {lookupData.itemTypes.map((type) => (
                  <option key={type.id} value={type.id}>
                    {type.name}
                  </option>
                ))}
              </select>
            </div>

            {/* Fast Running Level */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Fast Running Level <span className="text-red-500">*</span>
              </label>
              <input
                type="number"
                name="fastRunningLevel"
                value={formData.fastRunningLevel}
                onChange={handleInputChange}
                required
                min="0"
                placeholder="Enter Fast Running level"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* Slow Moving Level */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Slow Moving level <span className="text-red-500">*</span>
              </label>
              <input
                type="number"
                name="slowMovingLevel"
                value={formData.slowMovingLevel}
                onChange={handleInputChange}
                required
                min="0"
                placeholder="Enter Slow Moving level"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* Dead Level */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Dead level <span className="text-red-500">*</span>
              </label>
              <input
                type="number"
                name="deadLevel"
                value={formData.deadLevel}
                onChange={handleInputChange}
                required
                min="0"
                placeholder="Enter Dead level"
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
                {loading ? 'Saving...' : 'Submit'}
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
          <span className="mr-2">⚖️</span>
          Item Type Sale level
          <span className="ml-2 text-blue-600 cursor-pointer">ⓘ</span>
        </h1>
        <button
          onClick={handleAdd}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 flex items-center gap-2"
        >
          <span className="text-xl">+</span>
          Add Item Type Sale Level
        </button>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-md">
          {error}
        </div>
      )}

      {/* Table Controls */}
      <div className="mb-4 flex justify-between items-center">
        <div className="flex items-center gap-2">
          <span className="text-sm text-gray-700">Show</span>
          <select
            value={entriesPerPage}
            onChange={(e) => setEntriesPerPage(parseInt(e.target.value))}
            className="px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value={10}>10</option>
            <option value={25}>25</option>
            <option value={50}>50</option>
            <option value={100}>100</option>
          </select>
          <span className="text-sm text-gray-700">entries</span>
        </div>

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
                  Item Type Name
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Fast Running Level
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Slow Moving Level
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Dead Level
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {loading ? (
                <tr>
                  <td colSpan="5" className="px-6 py-4 text-center text-sm text-gray-500">
                    Loading...
                  </td>
                </tr>
              ) : filteredLevels.length === 0 ? (
                <tr>
                  <td colSpan="5" className="px-6 py-8 text-center">
                    <div className="text-blue-500 mb-2">No data available in table</div>
                  </td>
                </tr>
              ) : (
                filteredLevels.slice(0, entriesPerPage).map((level) => (
                  <tr key={level.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-900">
                      {level.itemTypeName || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {level.fastRunningLevel}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {level.slowMovingLevel}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {level.deadLevel}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm">
                      <button
                        onClick={() => handleDelete(level.id)}
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

      {/* Pagination info */}
      <div className="mt-4 text-sm text-gray-700">
        Showing {filteredLevels.length > 0 ? '0' : '0'} to {filteredLevels.length > 0 ? '0' : '0'} of {filteredLevels.length > 0 ? '0' : '0'} entries
      </div>
    </div>
  );
};

export default ItemTypeSaleLevelPage;
