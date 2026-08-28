import React,{ useCallback, useState, useEffect } from 'react';
import { ArrowDownTrayIcon } from '@heroicons/react/24/outline';
import { getExpiredStock } from '../services/expiredStockApi';
import { getAllStores } from '../services/storeApi';
import itemApi from '../services/itemApi';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';

const toDateInput = (date) => date.toISOString().split('T')[0];

// Expired stock is inherently backward-looking (the report already hard-filters to
// ExpiryDate < today), so the sensible default is "the last several years up to
// today" rather than a stale hardcoded 2025 range.
const getDefaultDateRange = () => {
  const end = new Date();
  const start = new Date();
  start.setFullYear(start.getFullYear() - 5);
  return {
    startDate: toDateInput(start),
    endDate: toDateInput(end)
  };
};

const ExpiredStockPage = () => {
  const [stores, setStores] = useState([]);
  const [items, setItems] = useState([]);

  const [filters, setFilters] = useState({
    storeName: '',
    ...getDefaultDateRange(),
    item: ''
  });

  const [searchTerm, setSearchTerm] = useState('');

  const fetchPage = useCallback(async (params) => {
    const data = await getExpiredStock(params);
    return { items: data.items || [], totalCount: data.totalCount || 0 };
  }, []);

  const {
    items: expiredStocks,
    totalCount,
    currentPage,
    pageSize: entriesPerPage,
    setPageSize: setEntriesPerPage,
    goToPage,
    search: runSearch,
    loading,
    error,
  } = usePagedList(fetchPage, { ...filters, searchTerm }, { autoLoad: false, initialPageSize: 10 });

  useEffect(() => {
    loadLookupData();
    runSearch({ ...filters, searchTerm });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const loadLookupData = async () => {
    try {
      const storesData = await getAllStores();
      setStores(storesData);
    } catch (err) {
      console.error('Error loading stores:', err);
    }

    try {
      const itemsData = await itemApi.getAllUnpaginated();
      setItems((itemsData || []).filter(i => i.isActive));
    } catch (err) {
      console.error('Error loading items:', err);
    }
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setFilters(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSearch = () => {
    runSearch({ ...filters, searchTerm });
  };

  const handleSearchTermChange = (value) => {
    setSearchTerm(value);
    runSearch({ ...filters, searchTerm: value });
  };

  // Exports only the currently-loaded page, not the whole filtered result set -
  // results are now paged server-side, same tradeoff as StockPage's export.
  const handleExport = () => {
    const headers = ['Name', 'Stock Type', 'Batch No.', 'Mfg. Date', 'Exp. Date', 'Total Items'];

    const csvContent = [
      headers.join(','),
      ...expiredStocks.map(row => [
        row.name,
        row.stockType,
        row.batchNo || '',
        row.mfgDate ? new Date(row.mfgDate).toLocaleDateString() : '',
        row.expDate ? new Date(row.expDate).toLocaleDateString() : '',
        row.totalItems
      ].join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `expired-stock-${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
  };

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center gap-2">
          <h1 className="text-2xl font-bold text-gray-800">Expired Stock</h1>
          <div className="w-5 h-5 bg-blue-600 rounded-full flex items-center justify-center text-white text-xs">
            i
          </div>
        </div>
        <button
          onClick={handleExport}
          disabled={expiredStocks.length === 0}
          className="bg-white border border-gray-300 text-gray-700 px-4 py-2 rounded hover:bg-gray-50 flex items-center gap-2 disabled:opacity-50"
        >
          <ArrowDownTrayIcon className="h-5 w-5" />
          Export
        </button>
      </div>

      {/* Filters Section */}
      <div className="bg-white rounded-lg shadow-md p-6 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Store Name
            </label>
            <select
              name="storeName"
              value={filters.storeName}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-blue-400 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Stores</option>
              {stores.map(store => (
                <option key={store.storeId} value={store.storeName}>
                  {store.storeName}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Date Range <span className="text-red-500">*</span>
            </label>
            <div className="flex gap-2 items-center">
              <input
                type="date"
                name="startDate"
                value={filters.startDate}
                onChange={handleFilterChange}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <span>-</span>
              <input
                type="date"
                name="endDate"
                value={filters.endDate}
                onChange={handleFilterChange}
                min={filters.startDate}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Item
            </label>
            <select
              name="item"
              value={filters.item}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Items</option>
              {items.map(item => (
                <option key={item.id} value={item.name}>
                  {item.name}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="mt-4 flex justify-end">
          <button
            onClick={handleSearch}
            disabled={loading}
            className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors disabled:bg-blue-300"
          >
            {loading ? 'Searching...' : 'Search'}
          </button>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
          Failed to load expired stock data{error.message ? `: ${error.message}` : ''}
        </div>
      )}

      {/* Table Section */}
      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="p-4 border-b border-gray-200 flex items-center justify-end">
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-600">Search:</span>
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => handleSearchTermChange(e.target.value)}
              className="px-2 py-1 border border-gray-300 rounded text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

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
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {loading ? (
                <tr>
                  <td colSpan="7" className="px-6 py-4 text-center text-gray-500">
                    Loading...
                  </td>
                </tr>
              ) : expiredStocks.length === 0 ? (
                <tr>
                  <td colSpan="7" className="px-6 py-4 text-center text-gray-500">
                    No data available in table
                  </td>
                </tr>
              ) : (
                expiredStocks.map((stock, index) => (
                  <tr key={index} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {stock.name}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {stock.stockType}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {stock.batchNo || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {stock.mfgDate ? new Date(stock.mfgDate).toLocaleDateString() : '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {stock.expDate ? new Date(stock.expDate).toLocaleDateString() : '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {stock.totalItems}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {/* Action buttons if needed */}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <Pagination
          currentPage={currentPage}
          pageSize={entriesPerPage}
          totalCount={totalCount}
          onPageChange={goToPage}
          onPageSizeChange={setEntriesPerPage}
        />
      </div>
    </div>
  );
};

export default ExpiredStockPage;
