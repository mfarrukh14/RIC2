import React, { useState, useEffect } from 'react';
import { stockStatsApi } from '../services/stockStatsApi';
import inventoryApi from '../services/inventoryApi';
import { itemTypeApi } from '../services/itemTypeApi';
import stockApi from '../services/stockApi';
import BranchField from '../components/BranchField';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';
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

  // The filters actually sent to the server - only updated when "Generate" is
  // clicked, mirroring StockPage - so editing a dropdown mid-form doesn't
  // re-trigger a search.
  const [submittedFilters, setSubmittedFilters] = useState(null);

  // Lookup data
  const [stores, setStores] = useState([]);
  const [items, setItems] = useState([]);
  const [stockTypes, setStockTypes] = useState([]);
  const [itemTypes, setItemTypes] = useState([]);
  const [itemQuantities, setItemQuantities] = useState({});

  // Selected items for multi-select
  const [selectedItems, setSelectedItems] = useState([]);

  const {
    items: stats,
    totalCount,
    currentPage,
    pageSize: entriesPerPage,
    setPageSize: setEntriesPerPage,
    goToPage,
    search: runSearch,
    loading,
    error,
  } = usePagedList(stockStatsApi.searchStats, submittedFilters || {}, { autoLoad: false, initialPageSize: 10 });

  useEffect(() => {
    loadLookupData();
  }, []);

  // Stock stats are always scoped to the logged-in user's own branch.
  useEffect(() => {
    if (session?.branchId) {
      setFilters((prev) => ({ ...prev, branchId: session.branchId }));
    }
  }, [session?.branchId]);

  // Item multi-select narrows to what's actually on hand at the selected
  // store, with the live quantity shown inline (e.g. "Syringe 10ml - 8").
  useEffect(() => {
    if (!filters.storeId) {
      setItemQuantities({});
      return;
    }

    let cancelled = false;
    stockApi.getQuantitiesByStore(filters.storeId)
      .then((data) => {
        if (!cancelled) setItemQuantities(data || {});
      })
      .catch((err) => {
        console.error('Error loading item quantities for store:', err);
        if (!cancelled) setItemQuantities({});
      });

    return () => { cancelled = true; };
  }, [filters.storeId]);

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

  const handleSearch = () => {
    const searchFilters = {
      ...filters,
      branchId: filters.branchId ? Number(filters.branchId) : null,
      storeId: filters.storeId ? Number(filters.storeId) : null,
      itemTypeId: filters.itemTypeId ? Number(filters.itemTypeId) : null,
      stockTypeId: filters.stockTypeId ? Number(filters.stockTypeId) : null,
      itemIds: selectedItems.join(',')
    };
    setSubmittedFilters(searchFilters);
    runSearch(searchFilters);
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

  // Row numbering only - actual paging now happens server-side (see usePagedList above).
  const indexOfFirstEntry = (currentPage - 1) * entriesPerPage;

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
          Failed to search stock stats{error.message ? `: ${error.message}` : ''}
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
                {items
                  .filter((item) => !filters.storeId || (itemQuantities.items?.[item.id] ?? 0) > 0)
                  .map((item) => (
                    <option key={item.id} value={item.id}>
                      {filters.storeId ? `${item.name} - ${itemQuantities.items?.[item.id] ?? 0}` : item.name}
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
              {stats.length === 0 ? (
                <tr>
                  <td colSpan="7" className="px-3 py-8 text-center text-sm text-gray-500">
                    {loading ? 'Loading...' : 'No data available in table'}
                  </td>
                </tr>
              ) : (
                stats.map((stat, index) => (
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

export default StockStatsPage;
