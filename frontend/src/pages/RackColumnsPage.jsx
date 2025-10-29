import React, { useState, useEffect } from 'react';
import rackColumnApi from '../services/rackColumnApi';
import { getAllStores } from '../services/storeApi';
import racksApi from '../services/racksApi';

const RackColumnsPage = () => {
  const [rackColumns, setRackColumns] = useState([]);
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
    fetchRackColumns();
    fetchStores();
    fetchRacks();
  }, []);

  const fetchRackColumns = async () => {
    setLoading(true);
    try {
      const data = await rackColumnApi.getAll();
      setRackColumns(data);
    } catch (error) {
      console.error('Error fetching rack columns:', error);
      alert('Failed to fetch rack columns');
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

  const fetchRacks = async () => {
    try {
      const data = await racksApi.getAllRacks();
      setRacks(data);
    } catch (error) {
      console.error('Error fetching racks:', error);
    }
  };

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
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
        await rackColumnApi.update(formData.id, submitData);
        alert('Rack column updated successfully');
      } else {
        await rackColumnApi.create(submitData);
        alert('Rack column created successfully');
      }

      handleCancel();
      fetchRackColumns();
    } catch (error) {
      console.error('Error saving rack column:', error);
      alert('Failed to save rack column');
    }
  };

  const handleEdit = (rackColumn) => {
    setFormData({
      id: rackColumn.id,
      name: rackColumn.name,
      description: rackColumn.description || '',
      storeId: rackColumn.storeId || '',
      rackId: rackColumn.rackId || '',
      branchId: rackColumn.branchId || null,
      isActive: rackColumn.isActive,
    });
    setEditMode(true);
    setShowForm(true);
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this rack column?')) {
      try {
        await rackColumnApi.delete(id);
        alert('Rack column deleted successfully');
        fetchRackColumns();
      } catch (error) {
        console.error('Error deleting rack column:', error);
        alert('Failed to delete rack column');
      }
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
    handleCancel();
    setShowForm(true);
  };

  // Pagination
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = rackColumns.slice(indexOfFirstItem, indexOfLastItem);
  const totalPages = Math.ceil(rackColumns.length / itemsPerPage);

  const paginate = (pageNumber) => setCurrentPage(pageNumber);

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Rack Columns</h1>
        <button
          onClick={handleAddNew}
          className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded flex items-center"
        >
          <span className="mr-2">+</span> Add Rack Column
        </button>
      </div>

      {showForm && (
        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">
            {editMode ? 'Edit Rack Column' : 'Add Rack Column'}
          </h2>
          <form onSubmit={handleSubmit}>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <label className="flex items-center space-x-2 mb-2">
                  <input
                    type="checkbox"
                    name="isActive"
                    checked={formData.isActive}
                    onChange={handleInputChange}
                    className="rounded"
                  />
                  <span className="text-sm font-medium">Active</span>
                </label>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium mb-2">
                  Store*
                </label>
                <select
                  name="storeId"
                  value={formData.storeId}
                  onChange={handleInputChange}
                  className="w-full border rounded px-3 py-2"
                  required
                >
                  <option value="">Select Store</option>
                  {stores.map((store) => (
                    <option key={store.storeId} value={store.storeId}>
                      {store.storeName}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">
                  Rack*
                </label>
                <select
                  name="rackId"
                  value={formData.rackId}
                  onChange={handleInputChange}
                  className="w-full border rounded px-3 py-2"
                  required
                >
                  <option value="">Select Rack</option>
                  {racks.map((rack) => (
                    <option key={rack.id} value={rack.id}>
                      {rack.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium mb-2">
                Name*
              </label>
              <input
                type="text"
                name="name"
                value={formData.name}
                onChange={handleInputChange}
                className="w-full border rounded px-3 py-2"
                placeholder="RackColumn Name"
                required
              />
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium mb-2">
                Description
              </label>
              <textarea
                name="description"
                value={formData.description}
                onChange={handleInputChange}
                className="w-full border rounded px-3 py-2"
                rows="3"
              />
            </div>

            <div className="flex justify-end space-x-2">
              <button
                type="button"
                onClick={handleCancel}
                className="px-4 py-2 border rounded hover:bg-gray-100"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
              >
                Submit
              </button>
            </div>
          </form>
        </div>
      )}

      {/* List View */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-4 border-b">
          <div className="flex justify-between items-center">
            <div className="flex items-center space-x-2">
              <span>Show</span>
              <select
                value={itemsPerPage}
                onChange={(e) => {
                  setItemsPerPage(Number(e.target.value));
                  setCurrentPage(1);
                }}
                className="border rounded px-2 py-1"
              >
                <option value={10}>10</option>
                <option value={25}>25</option>
                <option value={50}>50</option>
                <option value={100}>100</option>
              </select>
              <span>entries</span>
            </div>
            <div>
              <input
                type="text"
                placeholder="Search"
                className="border rounded px-3 py-1"
              />
            </div>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="px-4 py-3 text-left text-sm font-medium">Store</th>
                <th className="px-4 py-3 text-left text-sm font-medium">Rack</th>
                <th className="px-4 py-3 text-left text-sm font-medium">Column Name</th>
                <th className="px-4 py-3 text-left text-sm font-medium">Description</th>
                <th className="px-4 py-3 text-left text-sm font-medium">Status</th>
                <th className="px-4 py-3 text-left text-sm font-medium">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="6" className="px-4 py-8 text-center">
                    Loading...
                  </td>
                </tr>
              ) : currentItems.length === 0 ? (
                <tr>
                  <td colSpan="6" className="px-4 py-8 text-center">
                    No rack columns found
                  </td>
                </tr>
              ) : (
                currentItems.map((column) => (
                  <tr key={column.id} className="border-b hover:bg-gray-50">
                    <td className="px-4 py-3 text-sm">{column.storeName || '-'}</td>
                    <td className="px-4 py-3 text-sm">{column.rackName || '-'}</td>
                    <td className="px-4 py-3 text-sm">{column.name}</td>
                    <td className="px-4 py-3 text-sm">{column.description || '-'}</td>
                    <td className="px-4 py-3 text-sm">
                      {column.isActive ? '✓' : '✗'}
                    </td>
                    <td className="px-4 py-3 text-sm">
                      <div className="flex space-x-2">
                        <button
                          onClick={() => handleEdit(column)}
                          className="text-blue-600 hover:text-blue-800"
                          title="Edit"
                        >
                          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                          </svg>
                        </button>
                        <button
                          onClick={() => handleDelete(column.id)}
                          className="text-red-600 hover:text-red-800"
                          title="Delete"
                        >
                          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="p-4 border-t flex justify-between items-center">
          <div className="text-sm text-gray-600">
            Showing {indexOfFirstItem + 1} to {Math.min(indexOfLastItem, rackColumns.length)} of {rackColumns.length} entries
          </div>
          <div className="flex space-x-1">
            <button
              onClick={() => paginate(currentPage - 1)}
              disabled={currentPage === 1}
              className="px-3 py-1 border rounded hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Previous
            </button>
            {[...Array(totalPages)].map((_, i) => (
              <button
                key={i + 1}
                onClick={() => paginate(i + 1)}
                className={`px-3 py-1 border rounded ${
                  currentPage === i + 1
                    ? 'bg-blue-500 text-white'
                    : 'hover:bg-gray-100'
                }`}
              >
                {i + 1}
              </button>
            ))}
            <button
              onClick={() => paginate(currentPage + 1)}
              disabled={currentPage === totalPages}
              className="px-3 py-1 border rounded hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Next
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RackColumnsPage;
