import React, { useState, useEffect } from 'react';
import { FiPlus, FiEdit2, FiPrinter, FiSearch } from 'react-icons/fi';
import transferInventoryApi from '../services/transferInventoryApi';

const TransferInventoryPage = () => {
  const [transfers, setTransfers] = useState([]);
  const [filteredTransfers, setFilteredTransfers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  const [lookupData, setLookupData] = useState({
    stores: [],
    stockTypes: [],
    items: []
  });

  // Form state
  const [showForm, setShowForm] = useState(false);
  const [editingTransfer, setEditingTransfer] = useState(null);
  const [formData, setFormData] = useState({
    fromStoreId: '',
    toStoreId: '',
    stockTypeId: '',
    itemId: '',
    quantity: '',
    notes: ''
  });

  // Filters
  const [entriesPerPage, setEntriesPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    filterTransfers();
  }, [transfers, searchTerm]);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [transfersData, lookup] = await Promise.all([
        transferInventoryApi.getAll(),
        transferInventoryApi.getLookupData()
      ]);
      
      setTransfers(transfersData);
      setFilteredTransfers(transfersData);
      setLookupData(lookup);
      setError(null);
    } catch (err) {
      console.error('Error fetching data:', err);
      setError('Failed to fetch transfer inventories. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const filterTransfers = () => {
    let filtered = [...transfers];

    if (searchTerm) {
      filtered = filtered.filter(transfer =>
        transfer.drNo?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        transfer.fromStoreName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        transfer.toStoreName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        transfer.itemName?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredTransfers(filtered);
  };

  const handleAddNew = () => {
    setEditingTransfer(null);
    setFormData({
      fromStoreId: '',
      toStoreId: '',
      stockTypeId: '',
      itemId: '',
      quantity: '',
      notes: ''
    });
    setShowForm(true);
  };

  const handleEdit = (transfer) => {
    setEditingTransfer(transfer);
    setFormData({
      fromStoreId: transfer.fromStoreId,
      toStoreId: transfer.toStoreId,
      stockTypeId: transfer.stockTypeId,
      itemId: transfer.itemId,
      quantity: transfer.quantity,
      notes: transfer.notes || ''
    });
    setShowForm(true);
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Validation
    if (!formData.fromStoreId || !formData.toStoreId || !formData.stockTypeId || 
        !formData.itemId || !formData.quantity) {
      alert('Please fill in all required fields');
      return;
    }

    if (formData.fromStoreId === formData.toStoreId) {
      alert('From Store and To Store cannot be the same');
      return;
    }

    try {
      const selectedItem = lookupData.items.find(i => i.id === parseInt(formData.itemId));
      
      const requestData = {
        fromStoreId: parseInt(formData.fromStoreId),
        toStoreId: parseInt(formData.toStoreId),
        stockTypeId: parseInt(formData.stockTypeId),
        itemId: parseInt(formData.itemId),
        itemName: selectedItem?.name || '',
        quantity: parseInt(formData.quantity),
        status: 'Received',
        notes: formData.notes || null
      };

      if (editingTransfer) {
        await transferInventoryApi.update(editingTransfer.id, requestData);
      } else {
        await transferInventoryApi.create(requestData);
      }

      setShowForm(false);
      setEditingTransfer(null);
      await fetchData();
    } catch (err) {
      console.error('Error saving transfer:', err);
      alert('Failed to save transfer. Please try again.');
    }
  };

  const handleCancel = () => {
    setShowForm(false);
    setEditingTransfer(null);
  };

  const handlePrint = (transfer) => {
    // TODO: Implement print functionality
    console.log('Print transfer:', transfer);
    alert('Print functionality coming soon');
  };

  const formatDate = (dateString) => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleString('en-US', {
      month: 'short',
      day: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-screen">
        <div className="text-gray-600">Loading...</div>
      </div>
    );
  }

  return (
    <div className="p-6">
      {showForm ? (
        <div className="bg-white rounded-lg shadow-lg p-6">
          <h2 className="text-2xl font-bold text-gray-800 mb-6">
            {editingTransfer ? 'Edit Transfer Inventory' : 'Add Transfer Inventory'}
          </h2>

          <form onSubmit={handleSubmit}>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  From Store<span className="text-red-500">*</span>
                </label>
                <select
                  name="fromStoreId"
                  value={formData.fromStoreId}
                  onChange={handleChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Select From Store</option>
                  {lookupData.stores.map((store) => (
                    <option key={store.id} value={store.id}>
                      {store.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  To Store<span className="text-red-500">*</span>
                </label>
                <select
                  name="toStoreId"
                  value={formData.toStoreId}
                  onChange={handleChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Select Store</option>
                  {lookupData.stores.map((store) => (
                    <option key={store.id} value={store.id}>
                      {store.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Stock Type<span className="text-red-500">*</span>
                </label>
                <select
                  name="stockTypeId"
                  value={formData.stockTypeId}
                  onChange={handleChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Select Stock Type</option>
                  {lookupData.stockTypes.map((type) => (
                    <option key={type.id} value={type.id}>
                      {type.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Item<span className="text-red-500">*</span>
                </label>
                <select
                  name="itemId"
                  value={formData.itemId}
                  onChange={handleChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Search Item</option>
                  {lookupData.items.map((item) => (
                    <option key={item.id} value={item.id}>
                      {item.name}
                    </option>
                  ))}
                </select>
                {!formData.itemId && (
                  <p className="text-xs text-red-500 mt-1">Please Select</p>
                )}
              </div>
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Quantity<span className="text-red-500">*</span>
              </label>
              <input
                type="number"
                name="quantity"
                value={formData.quantity}
                onChange={handleChange}
                required
                min="1"
                placeholder="Quantity"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Notes
              </label>
              <textarea
                name="notes"
                value={formData.notes}
                onChange={handleChange}
                rows="3"
                placeholder="Add any additional notes..."
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div className="flex justify-end gap-3">
              <button
                type="submit"
                className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                {editingTransfer ? 'Update' : 'Add'}
              </button>
              <button
                type="button"
                onClick={handleCancel}
                className="px-6 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* Header */}
          <div className="mb-6 flex justify-between items-center">
            <h1 className="text-2xl font-bold text-gray-800 flex items-center">
              <span className="mr-2">🔄</span>
              Transfer Inventory
              <span className="ml-2 text-blue-600 cursor-pointer">ⓘ</span>
            </h1>
            <button
              onClick={handleAddNew}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <FiPlus className="h-5 w-5" />
              Add Transfer Inventory
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
                      DR-No
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Stock Type
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      To Store
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      From Store
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Items
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Date & Time
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
                  {filteredTransfers.length === 0 ? (
                    <tr>
                      <td colSpan="8" className="px-6 py-4 text-center text-sm text-gray-500">
                        Showing 0 to 0 of 0 entries
                      </td>
                    </tr>
                  ) : (
                    filteredTransfers.slice(0, entriesPerPage).map((transfer) => (
                      <tr key={transfer.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {transfer.drNo}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {transfer.stockTypeName || 'Regular'}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {transfer.toStoreName}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {transfer.fromStoreName}
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-500">
                          {transfer.itemName}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {formatDate(transfer.transferDate)}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm">
                          <span className="px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">
                            {transfer.status}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                          <button
                            onClick={() => handleEdit(transfer)}
                            className="text-blue-600 hover:text-blue-900 mr-3"
                            title="Edit"
                          >
                            <FiEdit2 className="h-5 w-5 inline" />
                          </button>
                          <button
                            onClick={() => handlePrint(transfer)}
                            className="text-green-600 hover:text-green-900"
                            title="Print"
                          >
                            <FiPrinter className="h-5 w-5 inline" />
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
            Showing {filteredTransfers.length > 0 ? 1 : 0} to {Math.min(entriesPerPage, filteredTransfers.length)} of {filteredTransfers.length} entries
          </div>
        </>
      )}
    </div>
  );
};

export default TransferInventoryPage;
