import React, { useState, useEffect } from 'react';
import { ArrowDownTrayIcon } from '@heroicons/react/24/outline';
import stockExpiringApi from '../services/stockExpiringApi';
import inventoryApi from '../services/inventoryApi';

// Default to today through 3 years out - expiry dates are inherently forward-looking,
// so (unlike a historical transaction log) the sensible default here is a wide
// look-ahead window rather than "the last N days".
const toDateInput = (date) => date.toISOString().split('T')[0];

const getDefaultDateRange = () => {
  const start = new Date();
  const end = new Date();
  end.setFullYear(end.getFullYear() + 3);
  return {
    startDate: toDateInput(start),
    endDate: toDateInput(end)
  };
};

const StockExpiringPage = () => {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const [loadingData, setLoadingData] = useState(true);
  const [error, setError] = useState(null);
  const [stores, setStores] = useState([]);
  const [allItems, setAllItems] = useState([]);
  const [selectedItems, setSelectedItems] = useState([]);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');

  const [filters, setFilters] = useState({
    storeId: '',
    ...getDefaultDateRange(),
  });

  useEffect(() => {
    loadLookupData();
  }, []);

  const loadLookupData = async () => {
    try {
      setLoadingData(true);
      const lookupData = await inventoryApi.getLookupData();
      setStores(lookupData.stores || []);
      setAllItems(lookupData.items || []);
      setError(null);
    } catch (err) {
      setError('Failed to load lookup data: ' + (err.response?.data || err.message));
      console.error('Error loading lookup data:', err);
    } finally {
      setLoadingData(false);
    }
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setFilters(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSearch = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const searchParams = {
        storeId: filters.storeId ? parseInt(filters.storeId) : null,
        startDate: filters.startDate || null,
        endDate: filters.endDate || null,
        itemIds: selectedItems.length > 0 ? selectedItems.join(',') : null
      };
      
      const data = await stockExpiringApi.searchExpiringStock(searchParams);
      setItems(data);
    } catch (err) {
      setError('Failed to search expiring stock: ' + (err.response?.data || err.message));
      console.error('Error searching expiring stock:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleExport = () => {
    const headers = ['Name', 'Stock Type', 'Batch No.', 'Mfg. Date', 'Exp. Date', 'Total Items'];
    const csvContent = [
      headers.join(','),
      ...filteredItems.map(item => [
        `"${item.itemName}"`,
        `"${item.stockType || ''}"`,
        `"${item.batchNo || ''}"`,
        item.mfgDate ? `"${new Date(item.mfgDate).toLocaleDateString()}"` : '""',
        item.expiryDate ? `"${new Date(item.expiryDate).toLocaleDateString()}"` : '""',
        item.totalItems,
      ].join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `expiring_stock_${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
  };

  const filteredItems = items.filter(item =>
    item.itemName.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (item.stockType && item.stockType.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (item.batchNo && item.batchNo.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  const currentItems = filteredItems.slice(0, itemsPerPage);

  if (loadingData) {
    return (
      <div className="p-6">
        <div className="flex justify-center items-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="bg-white shadow-sm rounded-lg">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200">
          <div className="flex justify-between items-center">
            <div>
              <h2 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
                <span className="text-blue-600">⏰</span>
                Expiring Stock
              </h2>
            </div>
            <button
              onClick={handleExport}
              className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 flex items-center gap-2 transition-colors"
              disabled={filteredItems.length === 0}
            >
              <ArrowDownTrayIcon className="w-5 h-5" />
              Export
            </button>
          </div>
        </div>

        {/* Filters */}
        <div className="px-6 py-4 border-b border-gray-200 bg-gray-50">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Store Name Dropdown */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Store Name
              </label>
              <select
                name="storeId"
                value={filters.storeId}
                onChange={handleFilterChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="">All Stores</option>
                {stores.map((store) => (
                  <option key={store.storeId} value={store.storeId}>
                    {store.storeName}
                  </option>
                ))}
              </select>
            </div>

            {/* Date Range - same two-input pattern as Stock Flow, instead of prompt() dialogs */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Date Range<span className="text-red-500">*</span>
              </label>
              <div className="flex items-center gap-2">
                <input
                  type="date"
                  name="startDate"
                  value={filters.startDate}
                  onChange={handleFilterChange}
                  className="flex-1 min-w-0 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
                />
                <span>-</span>
                <input
                  type="date"
                  name="endDate"
                  value={filters.endDate}
                  onChange={handleFilterChange}
                  min={filters.startDate}
                  className="flex-1 min-w-0 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
                />
              </div>
            </div>

            {/* Item - real dropdown of active items instead of free-text search */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Item
              </label>
              <select
                value={selectedItems[0] || ''}
                onChange={(e) => setSelectedItems(e.target.value ? [parseInt(e.target.value)] : [])}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="">All Items</option>
                {allItems.map((item) => (
                  <option key={item.id} value={item.id}>
                    {item.name}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Search Button */}
          <div className="mt-4">
            <button
              onClick={handleSearch}
              disabled={loading}
              className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors disabled:bg-blue-300"
            >
              {loading ? 'Searching...' : 'Search'}
            </button>
          </div>
        </div>

        {/* Error Message */}
        {error && (
          <div className="px-6 py-4 bg-red-50 border-b border-red-200">
            <p className="text-red-600">{error}</p>
          </div>
        )}

        {/* Controls */}
        <div className="px-6 py-4 flex justify-between items-center border-b border-gray-200">
          <div className="flex items-center gap-2">
            <label className="text-sm text-gray-700">Show</label>
            <select
              value={itemsPerPage}
              onChange={(e) => setItemsPerPage(parseInt(e.target.value))}
              className="px-3 py-1 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value={10}>10</option>
              <option value={25}>25</option>
              <option value={50}>50</option>
              <option value={100}>100</option>
            </select>
            <label className="text-sm text-gray-700">entries</label>
          </div>
          <div>
            <input
              type="text"
              placeholder="Search..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Stock Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Batch No.
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Mfg. Date
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Exp. Date
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Total Items
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {loading ? (
                <tr>
                  <td colSpan="6" className="px-6 py-8 text-center">
                    <div className="flex justify-center">
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
                    </div>
                  </td>
                </tr>
              ) : currentItems.length === 0 ? (
                <tr>
                  <td colSpan="6" className="px-6 py-8 text-center text-gray-500">
                    No data available in table
                  </td>
                </tr>
              ) : (
                currentItems.map((item, index) => (
                  <tr key={index} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">{item.itemName}</div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">{item.stockType || '-'}</div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">{item.batchNo || '-'}</div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">
                        {item.mfgDate ? new Date(item.mfgDate).toLocaleDateString() : '-'}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">
                        {item.expiryDate ? new Date(item.expiryDate).toLocaleDateString() : '-'}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">{item.totalItems}</div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-gray-200">
          <div className="text-sm text-gray-700">
            Showing {items.length > 0 ? 1 : 0} to {Math.min(itemsPerPage, filteredItems.length)} of {filteredItems.length} entries
          </div>
        </div>
      </div>
    </div>
  );
};

export default StockExpiringPage;
