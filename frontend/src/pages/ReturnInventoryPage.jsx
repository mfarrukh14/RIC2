import React, { useState, useEffect } from 'react';
import { FiSearch } from 'react-icons/fi';
import returnInventoryApi from '../services/returnInventoryApi';
import BranchField from '../components/BranchField';
import { useSession } from '../context/SessionContext';

const ReturnInventoryPage = () => {
  const { session } = useSession();
  const [returns, setReturns] = useState([]);
  const [filteredReturns, setFilteredReturns] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  const [lookupData, setLookupData] = useState({
    branches: [],
    stores: [],
    itemTypes: [],
    stockTypes: [],
    vendors: [],
    items: []
  });

  // Filters
  const [filters, setFilters] = useState({
    branchId: '',
    storeId: '',
    itemType: 'All',
    startDate: '',
    endDate: '',
    purchaseOrderNo: '',
    itemId: '',
    inventoryNo: ''
  });

  const [entriesPerPage, setEntriesPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchData();
  }, []);

  // Returns are always scoped to the logged-in user's own branch.
  useEffect(() => {
    if (session?.branchId) {
      setFilters((prev) => ({ ...prev, branchId: session.branchId }));
    }
  }, [session?.branchId]);

  useEffect(() => {
    filterReturns();
  }, [returns, searchTerm]);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [returnsData, lookup] = await Promise.all([
        returnInventoryApi.getAll(),
        returnInventoryApi.getLookupData()
      ]);
      
      setReturns(returnsData);
      setFilteredReturns(returnsData);
      setLookupData(lookup);
      setError(null);
    } catch (err) {
      console.error('Error fetching data:', err);
      setError('Failed to fetch return inventory data. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const filterReturns = () => {
    let filtered = [...returns];

    if (searchTerm) {
      filtered = filtered.filter(ret =>
        ret.inventoryNo?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        ret.purchaseOrderNo?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        ret.itemName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        ret.storeName?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredReturns(filtered);
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setFilters(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleGenerateReport = async () => {
    try {
      setLoading(true);
      
      // Build filter object
      const filterParams = {
        branchId: filters.branchId || null,
        storeId: filters.storeId || null,
        itemType: filters.itemType !== 'All' ? filters.itemType : null,
        startDate: filters.startDate || null,
        endDate: filters.endDate || null,
        purchaseOrderNo: filters.purchaseOrderNo || null,
        itemId: filters.itemId || null,
        inventoryNo: filters.inventoryNo || null
      };

      const data = await returnInventoryApi.getAll(filterParams);
      setReturns(data);
      setFilteredReturns(data);
      setError(null);
    } catch (err) {
      console.error('Error generating report:', err);
      setError('Failed to generate report. Please try again.');
    } finally {
      setLoading(false);
    }
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

  // Get current date range for default filter
  const getTodayDateRange = () => {
    const today = new Date();
    const start = new Date(today.setHours(0, 0, 0, 0));
    const end = new Date(today.setHours(23, 59, 59, 999));
    
    return {
      start: start.toISOString().slice(0, 16),
      end: end.toISOString().slice(0, 16)
    };
  };

  useEffect(() => {
    const dateRange = getTodayDateRange();
    setFilters(prev => ({
      ...prev,
      startDate: dateRange.start,
      endDate: dateRange.end
    }));
  }, []);

  if (loading && returns.length === 0) {
    return (
      <div className="flex justify-center items-center h-screen">
        <div className="text-gray-600">Loading...</div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-800 flex items-center">
          <span className="mr-2">↩️</span>
          Return Inventory Wrt Items
          <span className="ml-2 text-blue-600 cursor-pointer">ⓘ</span>
        </h1>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-md">
          {error}
        </div>
      )}

      {/* Filters Section */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
          {/* Branch - locked to the logged-in user's own branch */}
          <BranchField />

          {/* Store */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Store
            </label>
            <select
              name="storeId"
              value={filters.storeId}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">ED OPD Store</option>
              {lookupData.stores.map((store) => (
                <option key={store.id} value={store.id}>
                  {store.name}
                </option>
              ))}
            </select>
          </div>

          {/* Item Type Radio Buttons */}
          <div className="col-span-2">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Item Type
            </label>
            <div className="flex items-center gap-6">
              <label className="flex items-center">
                <input
                  type="radio"
                  name="itemType"
                  value="All"
                  checked={filters.itemType === 'All'}
                  onChange={handleFilterChange}
                  className="mr-2"
                />
                All
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="itemType"
                  value="Medicine"
                  checked={filters.itemType === 'Medicine'}
                  onChange={handleFilterChange}
                  className="mr-2"
                />
                Medicine(s)
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="itemType"
                  value="Disposable"
                  checked={filters.itemType === 'Disposable'}
                  onChange={handleFilterChange}
                  className="mr-2"
                />
                Disposable(s)
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="itemType"
                  value="Item"
                  checked={filters.itemType === 'Item'}
                  onChange={handleFilterChange}
                  className="mr-2"
                />
                Item(s)
              </label>
            </div>
          </div>

          {/* Date Range Filter */}
          <div className="col-span-2">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Date Range Filter
            </label>
            <div className="flex items-center gap-2">
              <input
                type="datetime-local"
                name="startDate"
                value={filters.startDate}
                onChange={handleFilterChange}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <span className="text-gray-500">-</span>
              <input
                type="datetime-local"
                name="endDate"
                value={filters.endDate}
                onChange={handleFilterChange}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          {/* Item */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Item
            </label>
            <select
              name="itemId"
              value={filters.itemId}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value=""></option>
              {lookupData.items.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.name}
                </option>
              ))}
            </select>
          </div>

          {/* Purchase Order No */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Purchase Order No.
            </label>
            <input
              type="text"
              name="purchaseOrderNo"
              value={filters.purchaseOrderNo}
              onChange={handleFilterChange}
              placeholder="Purchase Order No."
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Inventory No */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Inventory No.
            </label>
            <input
              type="text"
              name="inventoryNo"
              value={filters.inventoryNo}
              onChange={handleFilterChange}
              placeholder="Inventory No."
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        {/* Generate Report Button */}
        <div className="flex justify-end">
          <button
            onClick={handleGenerateReport}
            disabled={loading}
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-gray-400"
          >
            {loading ? 'Loading...' : 'Generate Report'}
          </button>
        </div>
      </div>

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
                  Serial
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Inventory No.
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  PO Number
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Items
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Return Quantity
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
                  Return Date
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredReturns.length === 0 ? (
                <tr>
                  <td colSpan="10" className="px-6 py-4 text-center text-sm text-gray-500">
                    No data available in table
                  </td>
                </tr>
              ) : (
                filteredReturns.slice(0, entriesPerPage).map((ret, index) => (
                  <tr key={ret.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {index + 1}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {ret.inventoryNo || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {ret.purchaseOrderNo || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {ret.itemName}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {ret.returnQuantity}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {ret.stockTypeName || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {ret.vendorName || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {ret.storeName || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(ret.returnDate)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button
                        className="text-blue-600 hover:text-blue-900"
                        title="View Details"
                      >
                        View
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
        Showing {filteredReturns.length > 0 ? 1 : 0} to {Math.min(entriesPerPage, filteredReturns.length)} of {filteredReturns.length} entries
      </div>
    </div>
  );
};

export default ReturnInventoryPage;
