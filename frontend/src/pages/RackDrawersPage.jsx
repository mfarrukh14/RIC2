import React, { useState, useEffect } from 'react';
import rackDrawerApi from '../services/rackDrawerApi';
import { getAllStores } from '../services/storeApi';
import racksApi from '../services/racksApi';
import { rackRowApi } from '../services/rackRowColumnApi';
import rackColumnApi from '../services/rackColumnApi';

const RackDrawersPage = () => {
  const [rackDrawers, setRackDrawers] = useState([]);
  const [stores, setStores] = useState([]);
  const [racks, setRacks] = useState([]);
  const [rows, setRows] = useState([]);
  const [columns, setColumns] = useState([]);
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
    rackRowId: '',
    rackColumnId: '',
    branchId: '',
    isActive: true,
  });

  const availableRacks = racks.filter(
    (rack) => !formData.storeId || Number(rack.storeId) === Number(formData.storeId)
  );

  useEffect(() => {
    fetchRackDrawers();
    fetchStores();
    fetchRacks();
    fetchRows();
    fetchColumns();
  }, []);

  const fetchRackDrawers = async () => {
    setLoading(true);
    try {
      const data = await rackDrawerApi.getAll();
      setRackDrawers(data);
    } catch (error) {
      console.error('Error fetching rack drawers:', error);
      alert('Failed to fetch rack drawers');
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

  const fetchRows = async () => {
    try {
      const data = await rackRowApi.getAll();
      setRows(data);
    } catch (error) {
      console.error('Error fetching rack rows:', error);
      setRows([]);
    }
  };

  const fetchColumns = async () => {
    try {
      const data = await rackColumnApi.getAll();
      setColumns(data);
    } catch (error) {
      console.error('Error fetching rack columns:', error);
      setColumns([]);
    }
  };

  const handleInputChange = async (e) => {
    const { name, value, type, checked } = e.target;
    if (name === 'storeId') {
      setFormData(prev => ({
        ...prev,
        storeId: value,
        rackId: '',
        rackRowId: '',
        rackColumnId: '',
      }));
      setRows([]);
      setColumns([]);
      return;
    }

    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));

    // When rack is changed, fetch rows and columns for that rack
    if (name === 'rackId' && value) {
      try {
        const [rowsData, columnsData] = await Promise.all([
          rackRowApi.getByRackId(value),
          rackColumnApi.getByRackId(value)
        ]);
        setRows(rowsData);
        setColumns(columnsData);
        // Reset row and column selections
        setFormData(prev => ({
          ...prev,
          rackRowId: '',
          rackColumnId: ''
        }));
      } catch (error) {
        console.error('Error fetching rows/columns for rack:', error);
        setRows([]);
        setColumns([]);
      }
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
        rackRowId: formData.rackRowId ? parseInt(formData.rackRowId, 10) : null,
        rackColumnId: formData.rackColumnId ? parseInt(formData.rackColumnId, 10) : null,
        branchId: formData.branchId ? parseInt(formData.branchId, 10) : null,
      };

      if (editMode) {
        await rackDrawerApi.update(submitData.id, submitData);
        alert('Rack drawer updated successfully');
      } else {
        await rackDrawerApi.create(submitData);
        alert('Rack drawer created successfully');
      }
      
      resetForm();
      fetchRackDrawers();
      setShowForm(false);
    } catch (error) {
      console.error('Error saving rack drawer:', error);
      console.error('Error response:', error.response?.data);
      alert('Failed to save rack drawer: ' + (error.response?.data?.message || error.message));
    }
  };

  const handleEdit = (rackDrawer) => {
    setFormData({
      id: rackDrawer.id,
      name: rackDrawer.name,
      description: rackDrawer.description || '',
      storeId: rackDrawer.storeId?.toString() || '',
      rackId: rackDrawer.rackId?.toString() || '',
      rackRowId: rackDrawer.rackRowId?.toString() || '',
      rackColumnId: rackDrawer.rackColumnId?.toString() || '',
      branchId: rackDrawer.branchId?.toString() || '',
      isActive: rackDrawer.isActive,
    });
    setEditMode(true);
    setShowForm(true);
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this rack drawer?')) {
      try {
        await rackDrawerApi.delete(id);
        alert('Rack drawer deleted successfully');
        fetchRackDrawers();
      } catch (error) {
        console.error('Error deleting rack drawer:', error);
        alert('Failed to delete rack drawer');
      }
    }
  };

  const resetForm = () => {
    setFormData({
      id: '',
      name: '',
      description: '',
      storeId: '',
      rackId: '',
      rackRowId: '',
      rackColumnId: '',
      branchId: '',
      isActive: true,
    });
    setEditMode(false);
  };

  const handleCancel = () => {
    resetForm();
    setShowForm(false);
  };

  // Pagination
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = rackDrawers.slice(indexOfFirstItem, indexOfLastItem);
  const totalPages = Math.ceil(rackDrawers.length / itemsPerPage);

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="max-w-full mx-auto bg-white rounded-lg shadow-md p-6">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-blue-600">Rack Drawers</h1>
          <button
            onClick={() => setShowForm(!showForm)}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            {showForm ? 'View List' : 'Add Rack Drawers'}
          </button>
        </div>

        {showForm ? (
          /* Form Section */
          <div className="bg-gray-50 p-6 rounded-lg">
            <h2 className="text-xl font-semibold mb-4">
              {editMode ? 'Edit Rack Drawer' : 'Add Rack Drawers'}
            </h2>
            <form onSubmit={handleSubmit}>
              {/* Active Checkbox */}
              <div className="mb-4">
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    name="isActive"
                    checked={formData.isActive}
                    onChange={handleInputChange}
                    className="mr-2 h-4 w-4"
                  />
                  <span className="text-sm font-medium">Active</span>
                </label>
              </div>

              <div className="grid grid-cols-2 gap-4">
                {/* Store */}
                <div>
                  <label className="block text-sm font-medium mb-2">
                    Store<span className="text-red-500">*</span>
                  </label>
                  <select
                    name="storeId"
                    value={formData.storeId}
                    onChange={handleInputChange}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded"
                  >
                    <option value="">Select Store</option>
                    {stores.map((store) => (
                      <option key={store.storeId} value={store.storeId}>
                        {store.storeName}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Rack */}
                <div>
                  <label className="block text-sm font-medium mb-2">
                    Rack<span className="text-red-500">*</span>
                  </label>
                  <select
                    name="rackId"
                    value={formData.rackId}
                    onChange={handleInputChange}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded"
                  >
                    <option value="">Select Store First</option>
                    {availableRacks.map((rack) => (
                      <option key={rack.id} value={rack.id}>
                        {rack.name}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Rows */}
                <div>
                  <label className="block text-sm font-medium mb-2">
                    Rows<span className="text-red-500">*</span>
                  </label>
                  <select
                    name="rackRowId"
                    value={formData.rackRowId}
                    onChange={handleInputChange}
                    required
                    disabled={!formData.rackId}
                    className="w-full px-3 py-2 border border-gray-300 rounded disabled:bg-gray-100"
                  >
                    <option value="">{formData.rackId ? 'Select Row' : 'Select Rack First'}</option>
                    {rows.map((row) => (
                      <option key={row.id} value={row.id}>
                        {row.name}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Column */}
                <div>
                  <label className="block text-sm font-medium mb-2">
                    Column<span className="text-red-500">*</span>
                  </label>
                  <select
                    name="rackColumnId"
                    value={formData.rackColumnId}
                    onChange={handleInputChange}
                    required
                    disabled={!formData.rackId}
                    className="w-full px-3 py-2 border border-gray-300 rounded disabled:bg-gray-100"
                  >
                    <option value="">{formData.rackId ? 'Select Column' : 'Select Rack First'}</option>
                    {columns.map((column) => (
                      <option key={column.id} value={column.id}>
                        {column.name}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Name */}
                <div className="col-span-2">
                  <label className="block text-sm font-medium mb-2">
                    Name<span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="name"
                    value={formData.name}
                    onChange={handleInputChange}
                    required
                    placeholder="RackDrawer Name"
                    className="w-full px-3 py-2 border border-gray-300 rounded"
                  />
                </div>

                {/* Description */}
                <div className="col-span-2">
                  <label className="block text-sm font-medium mb-2">Description</label>
                  <textarea
                    name="description"
                    value={formData.description}
                    onChange={handleInputChange}
                    rows={3}
                    className="w-full px-3 py-2 border border-gray-300 rounded"
                  />
                </div>
              </div>

              {/* Form Buttons */}
              <div className="flex justify-end gap-2 mt-6">
                <button
                  type="button"
                  onClick={handleCancel}
                  className="px-4 py-2 border border-gray-300 rounded hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  Submit
                </button>
              </div>
            </form>
          </div>
        ) : (
          /* Table Section */
          <>
            {/* Table Header Info */}
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <span className="text-sm">Show</span>
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
                <span className="text-sm">entries</span>
              </div>
              <div className="text-sm">
                Search: <input type="text" className="px-2 py-1 border border-gray-300 rounded" />
              </div>
            </div>

            {/* Table */}
            <div className="overflow-x-auto">
              <table className="w-full border-collapse">
                <thead>
                  <tr className="bg-blue-100 border-b">
                    <th className="px-4 py-2 text-left text-sm font-semibold">Store</th>
                    <th className="px-4 py-2 text-left text-sm font-semibold">Rack</th>
                    <th className="px-4 py-2 text-left text-sm font-semibold">Row</th>
                    <th className="px-4 py-2 text-left text-sm font-semibold">Column</th>
                    <th className="px-4 py-2 text-left text-sm font-semibold">Name</th>
                    <th className="px-4 py-2 text-left text-sm font-semibold">Description</th>
                    <th className="px-4 py-2 text-left text-sm font-semibold">Status</th>
                    <th className="px-4 py-2 text-left text-sm font-semibold">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {loading ? (
                    <tr>
                      <td colSpan="8" className="px-4 py-8 text-center text-gray-500">
                        Loading...
                      </td>
                    </tr>
                  ) : currentItems.length > 0 ? (
                    currentItems.map((rackDrawer) => (
                      <tr key={rackDrawer.id} className="border-b hover:bg-gray-50">
                        <td className="px-4 py-2 text-sm">{rackDrawer.storeName}</td>
                        <td className="px-4 py-2 text-sm">{rackDrawer.rackName}</td>
                        <td className="px-4 py-2 text-sm">{rackDrawer.rowName}</td>
                        <td className="px-4 py-2 text-sm">{rackDrawer.columnName}</td>
                        <td className="px-4 py-2 text-sm">{rackDrawer.name}</td>
                        <td className="px-4 py-2 text-sm">{rackDrawer.description}</td>
                        <td className="px-4 py-2 text-sm">
                          <span className={`px-2 py-1 rounded text-xs ${
                            rackDrawer.isActive 
                              ? 'bg-green-100 text-green-800' 
                              : 'bg-red-100 text-red-800'
                          }`}>
                            {rackDrawer.isActive ? 'Active' : 'Inactive'}
                          </span>
                        </td>
                        <td className="px-4 py-2 text-sm">
                          <button
                            onClick={() => handleEdit(rackDrawer)}
                            className="text-blue-600 hover:text-blue-800 mr-3"
                          >
                            Edit
                          </button>
                          <button
                            onClick={() => handleDelete(rackDrawer.id)}
                            className="text-red-600 hover:text-red-800"
                          >
                            Delete
                          </button>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan="8" className="px-4 py-8 text-center text-gray-500">
                        No data available in table
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            {/* Totals Row */}
            {!loading && rackDrawers.length > 0 && (
              <div className="border-t-2 bg-gray-100 px-4 py-2">
                <div className="grid grid-cols-8 gap-4">
                  <div className="text-sm font-semibold">Store</div>
                  <div className="text-sm font-semibold">Rack</div>
                  <div className="text-sm font-semibold">Row</div>
                  <div className="text-sm font-semibold">Column</div>
                  <div className="text-sm font-semibold">Name</div>
                  <div className="text-sm font-semibold">Description</div>
                  <div className="text-sm font-semibold">Status</div>
                  <div className="text-sm font-semibold">Actions</div>
                </div>
              </div>
            )}

            {/* Footer */}
            <div className="flex items-center justify-between mt-4">
              <div className="text-sm text-gray-600">
                Showing {indexOfFirstItem + 1} to {Math.min(indexOfLastItem, rackDrawers.length)} of {rackDrawers.length} entries
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
                  disabled={currentPage === 1}
                  className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50"
                >
                  Previous
                </button>
                {[...Array(totalPages)].map((_, i) => (
                  <button
                    key={i + 1}
                    onClick={() => setCurrentPage(i + 1)}
                    className={`px-3 py-1 border rounded ${
                      currentPage === i + 1
                        ? 'bg-blue-600 text-white border-blue-600'
                        : 'border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    {i + 1}
                  </button>
                ))}
                <button
                  onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
                  disabled={currentPage === totalPages}
                  className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50"
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

export default RackDrawersPage;
