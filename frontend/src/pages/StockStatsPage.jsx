import React, { useState, useEffect } from 'react';
import { stockStatsApi } from '../services/stockStatsApi';
import inventoryApi from '../services/inventoryApi';
import { itemTypeApi } from '../services/itemTypeApi';
import BranchField from '../components/BranchField';
import { useSession } from '../context/SessionContext';

// Default to the last 30 days up to now, instead of a hardcoded stale range,
// so the page shows recent activity out of the box.
const toLocalDateTimeInput = (date) => {
  const pad = (n) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
};

const getDefaultDateRange = () => {
  const end = new Date();
  const start = new Date();
  start.setDate(start.getDate() - 30);
  start.setHours(0, 0, 0, 0);
  return {
    startDate: toLocalDateTimeInput(start),
    endDate: toLocalDateTimeInput(end)
  };
};

const StockStatsPage = () => {
  const { session } = useSession();
  const [stats, setStats] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Filters
  const [filters, setFilters] = useState({
    branchId: null,
    storeId: null,
    ...getDefaultDateRange(),
    itemTypeId: null,
    itemIds: '',
    stockTypeId: null,
    saleType: 'OverAll'
  });

  // Lookup data
  const [stores, setStores] = useState([]);
  const [items, setItems] = useState([]);
  const [stockTypes, setStockTypes] = useState([]);
  const [itemTypes, setItemTypes] = useState([]);
  
  // Selected items for multi-select
  const [selectedItems, setSelectedItems] = useState([]);

  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [entriesPerPage, setEntriesPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    loadLookupData();
  }, []);

  // Stock stats are always scoped to the logged-in user's own branch.
  useEffect(() => {
    if (session?.branchId) {
      setFilters((prev) => ({ ...prev, branchId: session.branchId }));
    }
  }, [session?.branchId]);

  const loadLookupData = async () => {
    try {
      const data = await inventoryApi.getLookupData();
      setStores((data.stores || []).map((store, index) => ({
        id: store.storeId ?? store.id ?? index,
        name: store.storeName ?? store.name ?? `Store ${index + 1}`
      })));
      setItems((data.items || []).map((item, index) => ({
        id: item.id ?? item.itemId ?? index,
        name: item.name ?? item.itemName ?? `Item ${index + 1}`
      })));
      setStockTypes((data.stockTypes || []).map((type, index) => ({
        id: type.id ?? type.stockTypeId ?? index,
        name: type.name ?? type.stockTypeName ?? `Stock Type ${index + 1}`
      })));
    } catch (err) {
      console.error('Error loading lookup data:', err);
    }

    try {
      const allItemTypes = await itemTypeApi.getAll();
      setItemTypes((allItemTypes || []).filter((it) => it.isActive));
    } catch (err) {
      console.error('Error loading item types:', err);
    }
  };

  const handleSearch = async () => {
    setLoading(true);
    setError(null);
    try {
      const searchFilters = {
        ...filters,
        branchId: filters.branchId ? Number(filters.branchId) : null,
        storeId: filters.storeId ? Number(filters.storeId) : null,
        itemTypeId: filters.itemTypeId ? Number(filters.itemTypeId) : null,
        stockTypeId: filters.stockTypeId ? Number(filters.stockTypeId) : null,
        itemIds: selectedItems.join(',')
      };
      const data = await stockStatsApi.searchStats(searchFilters);
      setStats(data);
    } catch (err) {
      setError('Failed to search stock stats');
      console.error('Error searching stock stats:', err);
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

  const handleItemToggle = (itemId) => {
    setSelectedItems(prev => {
      if (prev.includes(itemId)) {
        return prev.filter(id => id !== itemId);
      } else {
        return [...prev, itemId];
      }
    });
  };

  const removeSelectedItem = (itemId) => {
    setSelectedItems(prev => prev.filter(id => id !== itemId));
  };

  // Filter items by search term
  const filteredStats = stats.filter(stat =>
    stat.itemName?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  // Pagination
  const indexOfLastEntry = currentPage * entriesPerPage;
  const indexOfFirstEntry = indexOfLastEntry - entriesPerPage;
  const currentStats = filteredStats.slice(indexOfFirstEntry, indexOfLastEntry);
  const totalPages = Math.ceil(filteredStats.length / entriesPerPage);

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-semibold text-gray-900">Stock Stats</h1>
        <button className="px-4 py-2 text-sm text-gray-700 border border-gray-300 rounded-md hover:bg-gray-50">
          Export ↓
        </button>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Filters Section */}
      <div className="bg-white shadow rounded-lg p-6 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
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
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">Select Store</option>
              {stores.map((store) => (
                <option key={store.id} value={store.id}>
                  {store.name}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Date Range Filter */}
        <div className="mb-4">
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Date Range Filter
          </label>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <input
              type="datetime-local"
              name="startDate"
              value={filters.startDate}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            />
            <input
              type="datetime-local"
              name="endDate"
              value={filters.endDate}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          {/* Item Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Item Type
            </label>
            <select
              name="itemTypeId"
              value={filters.itemTypeId || ''}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">All</option>
              {itemTypes.map((itemType) => (
                <option key={itemType.id} value={itemType.id}>
                  {itemType.name}
                </option>
              ))}
            </select>
          </div>

          {/* Stock Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Stock Type
            </label>
            <select
              name="stockTypeId"
              value={filters.stockTypeId || ''}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">All</option>
              {stockTypes.map((type) => (
                <option key={type.id} value={type.id}>
                  {type.name}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          {/* Item Multi-Select */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Item
            </label>
            <div className="border border-gray-300 rounded-md p-2 min-h-[42px]">
              {selectedItems.length > 0 && (
                <div className="flex flex-wrap gap-2 mb-2">
                  {selectedItems.map(itemId => {
                    const item = items.find(i => i.id === parseInt(itemId));
                    return item ? (
                      <span
                        key={itemId}
                        className="inline-flex items-center px-2 py-1 rounded-md text-sm bg-blue-100 text-blue-800"
                      >
                        {item.name}
                        <button
                          onClick={() => removeSelectedItem(itemId)}
                          className="ml-1 text-blue-600 hover:text-blue-800"
                        >
                          ×
                        </button>
                      </span>
                    ) : null;
                  })}
                </div>
              )}
              <select
                multiple
                onChange={(e) => {
                  const selected = Array.from(e.target.selectedOptions, option => option.value);
                  setSelectedItems(selected);
                }}
                className="w-full border-0 focus:ring-0 text-sm"
                size="1"
              >
                {items.map((item) => (
                  <option key={item.id} value={item.id}>
                    {item.name}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        {/* Sale Type Radio Buttons */}
        <div className="mb-4">
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Sale Type
          </label>
          <div className="flex items-center gap-4 mt-2">
            <label className="flex items-center">
              <input
                type="radio"
                name="saleType"
                value="OverAll"
                checked={filters.saleType === 'OverAll'}
                onChange={handleFilterChange}
                className="mr-1"
              />
              <span className="text-sm">Over All</span>
            </label>
            <label className="flex items-center">
              <input
                type="radio"
                name="saleType"
                value="OPD"
                checked={filters.saleType === 'OPD'}
                onChange={handleFilterChange}
                className="mr-1"
              />
              <span className="text-sm">OPD</span>
            </label>
            <label className="flex items-center">
              <input
                type="radio"
                name="saleType"
                value="Emergency"
                checked={filters.saleType === 'Emergency'}
                onChange={handleFilterChange}
                className="mr-1"
              />
              <span className="text-sm">Emergency</span>
            </label>
            <label className="flex items-center">
              <input
                type="radio"
                name="saleType"
                value="IPD"
                checked={filters.saleType === 'IPD'}
                onChange={handleFilterChange}
                className="mr-1"
              />
              <span className="text-sm">IPD</span>
            </label>
            <label className="flex items-center">
              <input
                type="radio"
                name="saleType"
                value="OutDoorPharmacy"
                checked={filters.saleType === 'OutDoorPharmacy'}
                onChange={handleFilterChange}
                className="mr-1"
              />
              <span className="text-sm">Out Door Pharmacy</span>
            </label>
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

      {/* Results Table */}
      <div className="bg-white shadow rounded-lg p-6">
        <div className="flex justify-between items-center mb-4">
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-700">Show</span>
            <select
              value={entriesPerPage}
              onChange={(e) => {
                setEntriesPerPage(Number(e.target.value));
                setCurrentPage(1);
              }}
              className="px-2 py-1 border border-gray-300 rounded-md text-sm"
            >
              <option value={10}>10</option>
              <option value={25}>25</option>
              <option value={50}>50</option>
              <option value={100}>100</option>
            </select>
            <span className="text-sm text-gray-700">entries</span>
          </div>
          <div>
            <input
              type="text"
              placeholder="Search:"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="px-3 py-1 border border-gray-300 rounded-md text-sm"
            />
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Sr.
                </th>
                <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Stock Type
                </th>
                <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Opening
                </th>
                <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Received
                </th>
                <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Issued
                </th>
                <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Balance
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {currentStats.length === 0 ? (
                <tr>
                  <td colSpan="7" className="px-3 py-8 text-center text-sm text-gray-500">
                    No data available in table
                  </td>
                </tr>
              ) : (
                currentStats.map((stat, index) => (
                  <tr key={stat.itemId} className="hover:bg-gray-50">
                    <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                      {indexOfFirstEntry + index + 1}
                    </td>
                    <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                      {stat.itemName}
                    </td>
                    <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                      {stat.stockType}
                    </td>
                    <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                      {stat.opening}
                    </td>
                    <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                      {stat.received}
                    </td>
                    <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                      {stat.issued}
                    </td>
                    <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                      {stat.balance}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="flex justify-between items-center mt-4">
          <div className="text-sm text-gray-700">
            Showing {filteredStats.length === 0 ? 0 : indexOfFirstEntry + 1} to {Math.min(indexOfLastEntry, filteredStats.length)} of {filteredStats.length} entries
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
              disabled={currentPage === 1}
              className="px-3 py-1 border border-gray-300 rounded-md text-sm disabled:opacity-50"
            >
              Previous
            </button>
            {[...Array(Math.min(totalPages, 5))].map((_, i) => {
              const pageNum = i + 1;
              return (
                <button
                  key={pageNum}
                  onClick={() => setCurrentPage(pageNum)}
                  className={`px-3 py-1 border rounded-md text-sm ${
                    currentPage === pageNum
                      ? 'bg-blue-600 text-white border-blue-600'
                      : 'border-gray-300 hover:bg-gray-50'
                  }`}
                >
                  {pageNum}
                </button>
              );
            })}
            <button
              onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
              disabled={currentPage === totalPages || totalPages === 0}
              className="px-3 py-1 border border-gray-300 rounded-md text-sm disabled:opacity-50"
            >
              Next
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default StockStatsPage;
