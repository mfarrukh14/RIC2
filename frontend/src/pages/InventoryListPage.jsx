import React, { useState, useEffect } from 'react';
import { FiPlus, FiEdit2, FiTrash2, FiSearch } from 'react-icons/fi';
import inventoryApi from '../services/inventoryApi';
import InventoryFormPage from '../components/InventoryFormPage';

const InventoryListPage = () => {
  const [inventories, setInventories] = useState([]);
  const [filteredInventories, setFilteredInventories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [vendors, setVendors] = useState([]);
  
  // Filters
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [selectedVendor, setSelectedVendor] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [entriesPerPage, setEntriesPerPage] = useState(10);
  const [showForm, setShowForm] = useState(false);
  const [selectedInventory, setSelectedInventory] = useState(null);

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    filterInventories();
  }, [inventories, dateFrom, dateTo, selectedVendor, searchTerm]);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [inventoriesData, lookupData] = await Promise.all([
        inventoryApi.getAll(),
        inventoryApi.getLookupData()
      ]);
      
      setInventories(inventoriesData);
      setFilteredInventories(inventoriesData);
      setVendors(lookupData.vendors);
      setError(null);
    } catch (err) {
      console.error('Error fetching data:', err);
      setError('Failed to fetch inventories. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const filterInventories = () => {
    let filtered = [...inventories];

    // Date range filter
    if (dateFrom) {
      filtered = filtered.filter(inv => {
        const invDate = new Date(inv.createdOn);
        return invDate >= new Date(dateFrom);
      });
    }
    if (dateTo) {
      filtered = filtered.filter(inv => {
        const invDate = new Date(inv.createdOn);
        return invDate <= new Date(dateTo);
      });
    }

    // Vendor filter
    if (selectedVendor) {
      filtered = filtered.filter(inv => inv.vendorId === parseInt(selectedVendor));
    }

    // Search filter
    if (searchTerm) {
      filtered = filtered.filter(inv =>
        inv.vendorInvoiceNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        inv.vendorName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        inv.stockTypeName?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredInventories(filtered);
  };

  const handleAddNew = () => {
    setSelectedInventory(null);
    setShowForm(true);
  };

  const handleEdit = (inventory) => {
    setSelectedInventory(inventory);
    setShowForm(true);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this inventory?')) {
      return;
    }

    try {
      await inventoryApi.delete(id);
      await fetchData();
    } catch (err) {
      console.error('Error deleting inventory:', err);
      alert('Failed to delete inventory. Please try again.');
    }
  };

  const handleCancelForm = () => {
    setShowForm(false);
    setSelectedInventory(null);
  };

  const handleSaveForm = async () => {
    setShowForm(false);
    setSelectedInventory(null);
    await fetchData();
  };

  const formatDate = (dateString) => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleString();
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
        <InventoryFormPage 
          inventory={selectedInventory}
          onSave={handleSaveForm}
          onCancel={handleCancelForm}
        />
      ) : (
        <>
          {/* Header */}
          <div className="mb-6 flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-800">Add Inventory</h1>
        <button
          onClick={handleAddNew}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          <FiPlus className="h-5 w-5" />
          Add Inventory
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-4 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Date Range
            </label>
            <div className="flex gap-2">
              <input
                type="date"
                value={dateFrom}
                onChange={(e) => setDateFrom(e.target.value)}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <span className="flex items-center">-</span>
              <input
                type="date"
                value={dateTo}
                onChange={(e) => setDateTo(e.target.value)}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Vendor
            </label>
            <select
              value={selectedVendor}
              onChange={(e) => setSelectedVendor(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Vendor</option>
              {vendors.map((vendor) => (
                <option key={vendor.id} value={vendor.id}>
                  {vendor.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Search
            </label>
            <div className="relative">
              <FiSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Search..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>
        </div>
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
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Invoice Number
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Stock Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Vendor
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Store
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Items (Quantity)
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date &amp; Time
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredInventories.length === 0 ? (
                <tr>
                  <td colSpan="7" className="px-6 py-4 text-center text-sm text-gray-500">
                    No data available in table
                  </td>
                </tr>
              ) : (
                filteredInventories.slice(0, entriesPerPage).map((inventory) => (
                  <tr key={inventory.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {inventory.vendorInvoiceNumber || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {inventory.stockTypeName || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {inventory.vendorName || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {inventory.storeName || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {inventory.totalQuantity || 0}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(inventory.createdOn)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button
                        onClick={() => handleEdit(inventory)}
                        className="text-indigo-600 hover:text-indigo-900 mr-4"
                        title="Edit"
                      >
                        <FiEdit2 className="h-5 w-5" />
                      </button>
                      <button
                        onClick={() => handleDelete(inventory.id)}
                        className="text-red-600 hover:text-red-900"
                        title="Delete"
                      >
                        <FiTrash2 className="h-5 w-5" />
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
        Showing 0 to {Math.min(entriesPerPage, filteredInventories.length)} of {filteredInventories.length} entries
      </div>
        </>
      )}
    </div>
  );
};

export default InventoryListPage;
