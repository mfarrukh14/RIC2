import React, { useState, useEffect } from 'react';
import { rackRowApi } from '../services/rackRowApi';
import { getAllStores } from '../services/storeApi';
import racksApi from '../services/racksApi';

const RackRowsPage = () => {
  const [rackRows, setRackRows] = useState([]);
  const [stores, setStores] = useState([]);
  const [racks, setRacks] = useState([]);
  const [loading, setLoading] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  
  const [formData, setFormData] = useState({
    id: '',
    name: '',
    description: '',
    storeId: '',
    rackId: '',
    branchId: null,
    isActive: true,
  });

  useEffect(() => {
    fetchRackRows();
    fetchStores();
  }, []);

  const fetchRackRows = async () => {
    setLoading(true);
    try {
      const data = await rackRowApi.getAll();
      setRackRows(data);
    } catch (error) {
      console.error('Error fetching rack rows:', error);
      alert('Failed to fetch rack rows');
    } finally {
      setLoading(false);
    }
  };

  const fetchStores = async () => {
    try {
      const data = await getAllStores();
      setStores(data);
    } catch (error) {
      console.error('Error fetching stores:', error);
    }
  };

  const fetchRacksByStore = async (storeId) => {
    try {
      const allRacks = await racksApi.getAllRacks();
      console.log('All racks:', allRacks);
      console.log('Selected storeId:', storeId, 'type:', typeof storeId);
      
      const storeIdGuid = String(storeId).padStart(8, '0') + '-0000-0000-0000-000000000000';
      console.log('Converted to GUID:', storeIdGuid);
      
      const filteredRacks = allRacks.filter(rack => {
        console.log('Comparing rack.storeId:', rack.storeId, 'with:', storeIdGuid);
        return rack.storeId.toLowerCase() === storeIdGuid.toLowerCase();
      });
      
      console.log('Filtered racks:', filteredRacks);
      setRacks(filteredRacks);
    } catch (error) {
      console.error('Error fetching racks for store:', error);
    }
  };

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    
    // If store is changed, fetch racks for that store and reset rack selection
    if (name === 'storeId') {
      setFormData(prev => ({
        ...prev,
        [name]: type === 'checkbox' ? checked : value,
        rackId: '', // Reset rack selection when store changes
      }));
      
      // Fetch racks for the selected store
      if (value) {
        fetchRacksByStore(parseInt(value));
      } else {
        setRacks([]);
      }
    } else {
      setFormData(prev => ({
        ...prev,
        [name]: type === 'checkbox' ? checked : value
      }));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!formData.name || !formData.storeId || !formData.rackId) {
      alert('Please fill in all required fields');
      return;
    }

    try {
      const submitData = {
        ...formData,
        storeId: parseInt(formData.storeId),
        rackId: parseInt(formData.rackId),
      };

      if (editMode) {
        await rackRowApi.update(formData.id, submitData);
        alert('Rack row updated successfully');
      } else {
        await rackRowApi.create(submitData);
        alert('Rack row created successfully');
      }

      handleCancel();
      fetchRackRows();
    } catch (error) {
      console.error('Error saving rack row:', error);
      const errorMessage = error.response?.data?.message || 'Failed to save rack row';
      alert(errorMessage);
    }
  };

  const handleEdit = (row) => {
    setFormData({
      id: row.id,
      name: row.name,
      description: row.description || '',
      storeId: row.storeId.toString(),
      rackId: row.rackId.toString(),
      branchId: row.branchId,
      isActive: row.isActive,
    });
    setEditMode(true);
    setShowForm(true);
    
    // Fetch racks for the selected store
    if (row.storeId) {
      fetchRacksByStore(row.storeId);
    }
  };

  const handleDelete = async (id) => {
    if (!confirm('Are you sure you want to delete this rack row?')) {
      return;
    }

    try {
      await rackRowApi.delete(id);
      alert('Rack row deleted successfully');
      fetchRackRows();
    } catch (error) {
      console.error('Error deleting rack row:', error);
      const errorMessage = error.response?.data?.message || 'Failed to delete rack row';
      alert(errorMessage);
    }
  };

  const handleCancel = () => {
    setFormData({
      id: '',
      name: '',
      description: '',
      storeId: '',
      rackId: '',
      branchId: null,
      isActive: true,
    });
    setEditMode(false);
    setShowForm(false);
  };

  const handleAddNew = () => {
    setEditMode(false);
    setFormData({
      id: '',
      name: '',
      description: '',
      storeId: '',
      rackId: '',
      branchId: null,
      isActive: true,
    });
    setShowForm(true);
  };

  // Pagination
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = rackRows.slice(indexOfFirstItem, indexOfLastItem);
  const totalPages = Math.ceil(rackRows.length / itemsPerPage);

  const paginate = (pageNumber) => setCurrentPage(pageNumber);

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-gray-800 flex items-center gap-2">
          <span className="text-blue-600">🗂️</span> Rack Rows
        </h1>
        <button
          onClick={handleAddNew}
          className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2"
        >
          <span>+</span> Add Rack Row
        </button>
      </div>

      {showForm && (
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">
            {editMode ? 'Edit Rack Row' : 'Add Rack Row'}
          </h2>
          <form onSubmit={handleSubmit}>
            <div className="mb-4">
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  name="isActive"
                  checked={formData.isActive}
                  onChange={handleInputChange}
                  className="w-4 h-4"
                />
                <span className="font-medium">Active</span>
              </label>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Store*
                </label>
                <select
                  name="storeId"
                  value={formData.storeId}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                >
                  <option value="">Select Store</option>
                  {stores.map(store => (
                    <option key={store.storeId} value={store.storeId}>
                      {store.storeName}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Rack*
                </label>
                <select
                  name="rackId"
                  value={formData.rackId}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                >
                  <option value="">Select Rack</option>
                  {racks.map(rack => (
                    <option key={rack.id} value={rack.id}>
                      {rack.rackName}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Name*
                </label>
                <input
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleInputChange}
                  placeholder="RackRow Name"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Description
                </label>
                <input
                  type="text"
                  name="description"
                  value={formData.description}
                  onChange={handleInputChange}
                  placeholder="Description"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>

            <div className="flex gap-2 justify-end">
              <button
                type="button"
                onClick={handleCancel}
                className="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
              >
                Submit
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Table */}
      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="p-4 border-b flex justify-between items-center">
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-600">Show</span>
            <select
              value={itemsPerPage}
              onChange={(e) => {
                setItemsPerPage(Number(e.target.value));
                setCurrentPage(1);
              }}
              className="px-2 py-1 border border-gray-300 rounded"
            >
              <option value={10}>10</option>
              <option value={25}>25</option>
              <option value={50}>50</option>
              <option value={100}>100</option>
            </select>
            <span className="text-sm text-gray-600">entries</span>
          </div>
          <div>
            <input
              type="text"
              placeholder="Search..."
              className="px-3 py-1 border border-gray-300 rounded"
            />
          </div>
        </div>

        {loading ? (
          <div className="p-8 text-center">Loading...</div>
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Store
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Rack
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Row Name
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Description
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {currentItems.map((row) => (
                    <tr key={row.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {row.storeName}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {row.rackName}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {row.name}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-500">
                        {row.description || '-'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {row.isActive ? (
                          <span className="text-green-600">✓</span>
                        ) : (
                          <span className="text-red-600">✗</span>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <div className="flex gap-2">
                          <button
                            onClick={() => handleEdit(row)}
                            className="text-blue-600 hover:text-blue-900"
                          >
                            ✏️
                          </button>
                          <button
                            onClick={() => handleDelete(row.id)}
                            className="text-red-600 hover:text-red-900"
                          >
                            🗑️
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="p-4 border-t flex justify-between items-center">
              <div className="text-sm text-gray-600">
                Showing {indexOfFirstItem + 1} to {Math.min(indexOfLastItem, rackRows.length)} of {rackRows.length} entries
              </div>
              <div className="flex gap-1">
                <button
                  onClick={() => paginate(currentPage - 1)}
                  disabled={currentPage === 1}
                  className="px-3 py-1 border rounded disabled:opacity-50"
                >
                  Previous
                </button>
                {[...Array(totalPages)].map((_, i) => (
                  <button
                    key={i + 1}
                    onClick={() => paginate(i + 1)}
                    className={`px-3 py-1 border rounded ${
                      currentPage === i + 1 ? 'bg-blue-600 text-white' : 'bg-white'
                    }`}
                  >
                    {i + 1}
                  </button>
                ))}
                <button
                  onClick={() => paginate(currentPage + 1)}
                  disabled={currentPage === totalPages}
                  className="px-3 py-1 border rounded disabled:opacity-50"
                >
                  Next
                </button>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default RackRowsPage;
