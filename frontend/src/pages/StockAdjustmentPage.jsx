import React, { useState, useEffect } from 'react';
import { QuestionMarkCircleIcon } from '@heroicons/react/24/outline';
import stockAdjustmentApi from '../services/stockAdjustmentApi';
import inventoryApi from '../services/inventoryApi';
import StockAdjustmentModal from '../components/StockAdjustmentModal';
import BranchField from '../components/BranchField';
import { useSession } from '../context/SessionContext';

const normalizeLookupOptions = (items, idKeys, nameKeys, fallbackLabel) =>
  (items || [])
    .map((item, index) => {
      const id = idKeys.map((key) => item?.[key]).find((value) => value !== null && value !== undefined && value !== '');
      if (id === null || id === undefined || id === '') {
        return null;
      }

      const name = nameKeys.map((key) => item?.[key]).find((value) => value !== null && value !== undefined && value !== '');
      return {
        id,
        name: name ?? `${fallbackLabel} ${index + 1}`,
      };
    })
    .filter(Boolean);

const StockAdjustmentPage = () => {
  const { session } = useSession();
  const [stockAdjustments, setStockAdjustments] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [showModal, setShowModal] = useState(false);
  const [selectedAdjustment, setSelectedAdjustment] = useState(null);
  // Carries the last-used store forward across modal opens (the modal itself is
  // unmounted/remounted each time via `{showModal && ...}`, so its own internal
  // state can't survive that - this lives in the parent instead).
  const [lastStoreId, setLastStoreId] = useState('');
  
  // Filter states
  const [filters, setFilters] = useState({
    branchId: null,
    storeId: null,
    startDate: null,
    endDate: null
  });

  // Lookup data
  const [stores, setStores] = useState([]);
  const [branches, setBranches] = useState([]);
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [entriesPerPage, setEntriesPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    loadLookupData();
    loadStockAdjustments();
  }, []);

  // Stock adjustments are always scoped to the logged-in user's own branch.
  useEffect(() => {
    if (session?.branchId) {
      setFilters((prev) => ({ ...prev, branchId: session.branchId }));
    }
  }, [session?.branchId]);

  const loadLookupData = async () => {
    try {
      const data = await inventoryApi.getLookupData();
      setStores(normalizeLookupOptions(data.stores, ['id', 'storeId'], ['name', 'storeName'], 'Store'));
      setBranches(normalizeLookupOptions(data.branches, ['id', 'branchId'], ['name', 'branchName'], 'Branch'));
    } catch (err) {
      console.error('Error loading lookup data:', err);
    }
  };

  const loadStockAdjustments = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await stockAdjustmentApi.getAll(filters);
      setStockAdjustments(data);
    } catch (err) {
      setError('Failed to load stock adjustments');
      console.error('Error loading stock adjustments:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setFilters(prev => ({
      ...prev,
      [name]: value === '' ? null : value
    }));
  };

  const handleSearch = () => {
    loadStockAdjustments();
  };

  const handleAddNew = () => {
    setSelectedAdjustment(null);
    setShowModal(true);
  };

  const handleEdit = async (id) => {
    try {
      const adjustment = await stockAdjustmentApi.getById(id);
      setSelectedAdjustment(adjustment);
      setShowModal(true);
    } catch (err) {
      console.error('Error loading adjustment:', err);
      setError('Failed to load adjustment details');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this stock adjustment?')) {
      try {
        await stockAdjustmentApi.delete(id);
        loadStockAdjustments();
      } catch (err) {
        console.error('Error deleting adjustment:', err);
        setError('Failed to delete stock adjustment');
      }
    }
  };

  const handleModalClose = () => {
    setShowModal(false);
    setSelectedAdjustment(null);
  };

  const handleModalSubmit = async (storeId) => {
    if (storeId) {
      setLastStoreId(storeId);
    }
    setShowModal(false);
    setSelectedAdjustment(null);
    await loadStockAdjustments();
  };

  // Set default date range to today
  useEffect(() => {
    const today = new Date().toISOString().split('T')[0];
    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59);
    setFilters(prev => ({
      ...prev,
      startDate: `${today}T00:00`,
      endDate: todayEnd.toISOString().slice(0, 16)
    }));
  }, []);

  // Filter adjustments based on search term
  const filteredAdjustments = stockAdjustments.filter(adj =>
    adj.storeName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    adj.itemNames?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    adj.stockType?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    adj.actionBy?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  // Pagination logic
  const totalPages = Math.ceil(filteredAdjustments.length / entriesPerPage);
  const startIndex = (currentPage - 1) * entriesPerPage;
  const endIndex = startIndex + entriesPerPage;
  const currentAdjustments = filteredAdjustments.slice(startIndex, endIndex);

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <QuestionMarkCircleIcon className="h-6 w-6 text-blue-600" />
          <h1 className="text-2xl font-semibold text-gray-800">Stock Adjustment</h1>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white p-6 rounded-lg shadow space-y-4">
        <div className="grid grid-cols-2 gap-4">
          {/* Branch - locked to the logged-in user's own branch */}
          <BranchField />

          {/* Store */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Store
            </label>
            <select
              name="storeId"
              value={filters.storeId || ''}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Store</option>
              {stores.map(store => (
                <option key={store.id} value={store.id}>
                  {store.name}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="flex items-end space-x-4">
          {/* Date Range Filter */}
          <div className="flex-1">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Date Range Filter
            </label>
            <input
              type="datetime-local"
              name="startDate"
              value={filters.startDate || ''}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div className="flex-1">
            <input
              type="datetime-local"
              name="endDate"
              value={filters.endDate || ''}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        <div className="flex justify-end">
          <button
            onClick={handleSearch}
            disabled={loading}
            className="px-6 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 disabled:bg-gray-400"
          >
            {loading ? 'Generating...' : 'Generate'}
          </button>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Results Table */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-4 flex justify-between items-center border-b">
          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-2 text-blue-600">
              <span className="text-2xl">📋</span>
              <span className="font-semibold">Stock Adjustment</span>
            </div>
            <div className="flex items-center space-x-2">
              <label className="text-sm text-gray-600">Show</label>
              <select
                value={entriesPerPage}
                onChange={(e) => {
                  setEntriesPerPage(Number(e.target.value));
                  setCurrentPage(1);
                }}
                className="border border-gray-300 rounded px-2 py-1 text-sm"
              >
                <option value={10}>10</option>
                <option value={25}>25</option>
                <option value={50}>50</option>
                <option value={100}>100</option>
              </select>
              <label className="text-sm text-gray-600">entries</label>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            <button
              onClick={handleAddNew}
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 flex items-center space-x-2"
            >
              <span>+</span>
              <span>Add Stock Adjustment</span>
            </button>
            <div className="flex items-center space-x-2">
              <label className="text-sm text-gray-600">Search:</label>
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => {
                  setSearchTerm(e.target.value);
                  setCurrentPage(1);
                }}
                className="border border-gray-300 rounded px-3 py-1 text-sm"
                placeholder="Search..."
              />
            </div>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Store
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Item(s)
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Stock Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action By
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action On
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Quantity
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Purchase Value
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Sale Value
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {loading ? (
                <tr>
                  <td colSpan="9" className="px-6 py-4 text-center text-sm text-gray-500">
                    Loading...
                  </td>
                </tr>
              ) : currentAdjustments.length === 0 ? (
                <tr>
                  <td colSpan="9" className="px-6 py-4 text-center text-sm text-gray-500">
                    No data available in table
                  </td>
                </tr>
              ) : (
                currentAdjustments.map((adjustment) => (
                  <tr key={adjustment.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {adjustment.storeName || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-900">
                      {adjustment.itemNames || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {adjustment.stockType || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {adjustment.actionBy || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {adjustment.actionOn ? new Date(adjustment.actionOn).toLocaleString() : '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {adjustment.totalQuantity || 0}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {adjustment.totalPurchaseValue?.toFixed(2) || '0.00'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {adjustment.totalSaleValue?.toFixed(2) || '0.00'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <button
                        onClick={() => handleEdit(adjustment.id)}
                        className="text-blue-600 hover:text-blue-800 mr-2"
                        title="Edit"
                      >
                        ✏️
                      </button>
                      <button
                        onClick={() => handleDelete(adjustment.id)}
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

        {/* Pagination */}
        <div className="p-4 flex items-center justify-between border-t">
          <div className="text-sm text-gray-600">
            Showing {startIndex + 1} to {Math.min(endIndex, filteredAdjustments.length)} of {filteredAdjustments.length} entries
          </div>
          <div className="flex space-x-2">
            <button
              onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
              disabled={currentPage === 1}
              className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
            >
              &lt;
            </button>
            {[...Array(Math.min(totalPages, 5))].map((_, i) => {
              const pageNum = i + 1;
              return (
                <button
                  key={pageNum}
                  onClick={() => setCurrentPage(pageNum)}
                  className={`px-3 py-1 border border-gray-300 rounded ${
                    currentPage === pageNum ? 'bg-blue-600 text-white' : 'hover:bg-gray-50'
                  }`}
                >
                  {pageNum}
                </button>
              );
            })}
            <button
              onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
              disabled={currentPage === totalPages || totalPages === 0}
              className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
            >
              &gt;
            </button>
          </div>
        </div>
      </div>

      {/* Modal */}
      {showModal && (
        <StockAdjustmentModal
          isOpen={showModal}
          onClose={handleModalClose}
          onSubmit={handleModalSubmit}
          adjustment={selectedAdjustment}
          stores={stores}
          branches={branches}
          defaultStoreId={lastStoreId}
        />
      )}
    </div>
  );
};

export default StockAdjustmentPage;
