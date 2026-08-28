import React, { useState, useEffect } from 'react';
import { spaceAllocationApi } from '../services/spaceAllocationApi';
import { getAllStores } from '../services/storeApi';
import racksApi from '../services/racksApi';
import { rackRowApi } from '../services/rackRowApi';
import rackColumnApi from '../services/rackColumnApi';
import { rackDrawerApi } from '../services/rackDrawerApi';
import itemApi from '../services/itemApi';
import Pagination from '../components/Pagination';

const normalizeItems = (items) =>
  (items || [])
    .map((item, index) => {
      const id = item?.id ?? item?.itemId;
      if (id === null || id === undefined || id === '') {
        return null;
      }

      return {
        id,
        name: item?.name ?? item?.itemName ?? `Item ${index + 1}`,
        model: item?.model ?? item?.modelNo ?? item?.itemModel ?? null,
      };
    })
    .filter(Boolean);

const SpaceAllocationsPage = () => {
  const [allocations, setAllocations] = useState([]);
  const [stores, setStores] = useState([]);
  const [items, setItems] = useState([]);
  const [racks, setRacks] = useState([]);
  const [rows, setRows] = useState([]);
  const [columns, setColumns] = useState([]);
  const [drawers, setDrawers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  
  const [formData, setFormData] = useState({
    id: '',
    storeId: '',
    itemId: '',
    feeId: '',
    rackId: '',
    rackRowId: '',
    rackColumnId: '',
    rackDrawerId: '',
    medicineId: '',
    isActive: true,
  });

  useEffect(() => {
    fetchAllocations();
    fetchStores();
    fetchItems();
  }, []);

  const fetchAllocations = async () => {
    setLoading(true);
    try {
      const data = await spaceAllocationApi.getAll();
      setAllocations(data);
    } catch (error) {
      console.error('Error fetching space allocations:', error);
      alert('Failed to fetch space allocations');
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

  const fetchItems = async () => {
    try {
      const data = await itemApi.getAllUnpaginated();
      setItems(normalizeItems(data));
    } catch (error) {
      console.error('Error fetching items:', error);
    }
  };

  const fetchRacksByStore = async (storeId) => {
    try {
      const allRacks = await racksApi.getAllRacks();
      const filteredRacks = allRacks.filter(rack => Number(rack.storeId) === Number(storeId));
      setRacks(filteredRacks);
    } catch (error) {
      console.error('Error fetching racks:', error);
    }
  };

  const fetchRowsByRack = async (rackId) => {
    try {
      const data = await rackRowApi.getByRackId(rackId);
      setRows(data);
    } catch (error) {
      console.error('Error fetching rows:', error);
    }
  };

  const fetchColumnsByRack = async (rackId) => {
    try {
      const data = await rackColumnApi.getByRackId(rackId);
      setColumns(data);
    } catch (error) {
      console.error('Error fetching columns:', error);
    }
  };

  const fetchDrawers = async () => {
    try {
      const data = await rackDrawerApi.getAll();
      setDrawers(data);
    } catch (error) {
      console.error('Error fetching drawers:', error);
    }
  };

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    
    if (name === 'storeId') {
      setFormData(prev => ({
        ...prev,
        [name]: value,
        rackId: '',
        rackRowId: '',
        rackColumnId: '',
        rackDrawerId: '',
      }));
      
      if (value) {
        fetchRacksByStore(parseInt(value));
      } else {
        setRacks([]);
        setRows([]);
        setColumns([]);
      }
    } else if (name === 'rackId') {
      setFormData(prev => ({
        ...prev,
        [name]: value,
        rackRowId: '',
        rackColumnId: '',
      }));
      
      if (value) {
        fetchRowsByRack(parseInt(value));
        fetchColumnsByRack(parseInt(value));
        fetchDrawers();
      } else {
        setRows([]);
        setColumns([]);
        setDrawers([]);
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

    if (!formData.storeId || !formData.itemId || !formData.rackId) {
      alert('Please fill in all required fields (Store, Item, Rack)');
      return;
    }

    try {
      const submitData = {
        storeId: parseInt(formData.storeId),
        itemId: parseInt(formData.itemId, 10),
        feeId: formData.feeId ? parseInt(formData.feeId, 10) : null,
        rackId: parseInt(formData.rackId),
        rackRowId: formData.rackRowId ? parseInt(formData.rackRowId, 10) : null,
        rackColumnId: formData.rackColumnId ? parseInt(formData.rackColumnId, 10) : null,
        rackDrawerId: formData.rackDrawerId ? parseInt(formData.rackDrawerId, 10) : null,
        medicineId: formData.medicineId ? parseInt(formData.medicineId, 10) : null,
        isActive: formData.isActive,
      };

      if (editMode) {
        await spaceAllocationApi.update(formData.id, submitData);
        alert('Space allocation updated successfully');
      } else {
        await spaceAllocationApi.create(submitData);
        alert('Space allocation created successfully');
      }

      handleCancel();
      fetchAllocations();
    } catch (error) {
      console.error('Error saving space allocation:', error);
      console.error('Error response:', error.response?.data);
      const errorMessage = error.response?.data?.message || error.message || 'Failed to save space allocation';
      alert('Failed to save: ' + errorMessage);
    }
  };

  const handleEdit = (allocation) => {
    setFormData({
      id: allocation.id,
      storeId: allocation.storeId.toString(),
      itemId: allocation.itemId?.toString() || '',
      feeId: allocation.feeId?.toString() || '',
      rackId: allocation.rackId.toString(),
      rackRowId: allocation.rackRowId?.toString() || '',
      rackColumnId: allocation.rackColumnId?.toString() || '',
      rackDrawerId: allocation.rackDrawerId?.toString() || '',
      medicineId: allocation.medicineId?.toString() || '',
      isActive: allocation.isActive,
    });
    setEditMode(true);
    setShowForm(true);
    
    // Fetch related data
    if (allocation.storeId) {
      fetchRacksByStore(allocation.storeId);
    }
    if (allocation.rackId) {
      fetchRowsByRack(allocation.rackId);
      fetchColumnsByRack(allocation.rackId);
      fetchDrawers();
    }
  };

  const handleDelete = async (id) => {
    if (!confirm('Are you sure you want to delete this space allocation?')) {
      return;
    }

    try {
      await spaceAllocationApi.delete(id);
      alert('Space allocation deleted successfully');
      fetchAllocations();
    } catch (error) {
      console.error('Error deleting space allocation:', error);
      const errorMessage = error.response?.data?.message || 'Failed to delete space allocation';
      alert(errorMessage);
    }
  };

  const handleCancel = () => {
    setFormData({
      id: '',
      storeId: '',
      itemId: '',
      feeId: '',
      rackId: '',
      rackRowId: '',
      rackColumnId: '',
      rackDrawerId: '',
      medicineId: '',
      isActive: true,
    });
    setEditMode(false);
    setShowForm(false);
    setRacks([]);
    setRows([]);
    setColumns([]);
    setDrawers([]);
  };

  const handleAddNew = () => {
    setEditMode(false);
    setFormData({
      id: '',
      storeId: '',
      itemId: '',
      feeId: '',
      rackId: '',
      rackRowId: '',
      rackColumnId: '',
      rackDrawerId: '',
      medicineId: '',
      isActive: true,
    });
    setShowForm(true);
  };

  // Pagination
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = allocations.slice(indexOfFirstItem, indexOfLastItem);

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-gray-800 flex items-center gap-2">
          <span className="text-blue-600">📍</span> Space Allocations
        </h1>
        <button
          onClick={handleAddNew}
          className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2"
        >
          <span>+</span> Add Space Allocation
        </button>
      </div>

      {showForm && (
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">
            {editMode ? 'Edit Space Allocation' : 'Add Space Allocation'}
          </h2>
          <form onSubmit={handleSubmit}>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
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
                  Item*
                </label>
                <select
                  name="itemId"
                  value={formData.itemId}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                >
                  <option value="">Select Item</option>
                  {items.map(item => (
                    <option key={item.id} value={item.id}>
                      {item.name} {item.model ? `- ${item.model}` : ''}
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
                  disabled={!formData.storeId}
                >
                  <option value="">{formData.storeId ? 'Select Rack' : 'Select Store First'}</option>
                  {racks.map(rack => (
                    <option key={rack.id} value={rack.id}>
                      {rack.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Rows*
                </label>
                <select
                  name="rackRowId"
                  value={formData.rackRowId}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  disabled={!formData.rackId}
                >
                  <option value="">{formData.rackId ? 'Select Rack First' : 'Select Rack First'}</option>
                  {rows.map(row => (
                    <option key={row.id} value={row.id}>
                      {row.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Column*
                </label>
                <select
                  name="rackColumnId"
                  value={formData.rackColumnId}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  disabled={!formData.rackId}
                >
                  <option value="">{formData.rackId ? 'Select Rack First' : 'Select Rack First'}</option>
                  {columns.map(column => (
                    <option key={column.id} value={column.id}>
                      {column.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Drawer
                </label>
                <select
                  name="rackDrawerId"
                  value={formData.rackDrawerId}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  disabled={!formData.rackId}
                >
                  <option value="">{formData.rackId ? 'Select Row & Col First' : 'Select Rack First'}</option>
                  {drawers.map(drawer => (
                    <option key={drawer.id} value={drawer.id}>
                      {drawer.name}
                    </option>
                  ))}
                </select>
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
                Assign
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Table */}
      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="p-4 border-b flex justify-end items-center">
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
        ) : allocations.length === 0 ? (
          <div className="p-8 text-center text-gray-500">No data available in table</div>
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
                      Item
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Rack
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Row
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Column
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Drawer
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Action
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {currentItems.map((allocation) => (
                    <tr key={allocation.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {allocation.storeName || '-'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {allocation.itemName || '-'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {allocation.rackName || '-'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {allocation.rowName || '-'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {allocation.columnName || '-'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {allocation.drawerName || '-'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {allocation.isActive ? (
                          <span className="text-green-600">✓</span>
                        ) : (
                          <span className="text-red-600">✗</span>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <div className="flex gap-2">
                          <button
                            onClick={() => handleEdit(allocation)}
                            className="text-blue-600 hover:text-blue-900"
                          >
                            ✏️
                          </button>
                          <button
                            onClick={() => handleDelete(allocation.id)}
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

            <Pagination
              currentPage={currentPage}
              pageSize={itemsPerPage}
              totalCount={allocations.length}
              onPageChange={setCurrentPage}
              onPageSizeChange={setItemsPerPage}
            />
          </>
        )}
      </div>
    </div>
  );
};

export default SpaceAllocationsPage;
