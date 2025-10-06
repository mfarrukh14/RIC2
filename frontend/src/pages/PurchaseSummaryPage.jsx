import React, { useState, useEffect } from 'react';
import purchaseSummaryApi from '../services/purchaseSummaryApi';

const PurchaseSummaryPage = () => {
  const [records, setRecords] = useState([]);
  const [filteredRecords, setFilteredRecords] = useState([]);
  const [totals, setTotals] = useState({
    totalQuantity: 0,
    totalAmount: 0,
    totalAdvanceTax: 0,
    totalDiscount: 0,
    totalPrice: 0
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  const [lookupData, setLookupData] = useState({
    branches: [],
    stores: [],
    itemTypes: [],
    vendors: [],
    items: []
  });

  // Filters
  const [filters, setFilters] = useState({
    branchId: '',
    storeId: '',
    itemType: 'All',
    invoiceDateStart: '',
    invoiceDateEnd: '',
    inventoryDateStart: '',
    inventoryDateEnd: '',
    itemId: '',
    invoiceNo: '',
    reportType: 'Both'
  });

  const [entriesPerPage, setEntriesPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    initializePage();
  }, []);

  useEffect(() => {
    filterRecords();
  }, [records, searchTerm]);

  const initializePage = async () => {
    try {
      setLoading(true);
      const today = new Date();
      const start = new Date(today.setHours(0, 0, 0, 0));
      const end = new Date(today.setHours(23, 59, 59, 999));
      
      setFilters(prev => ({
        ...prev,
        invoiceDateStart: start.toISOString().slice(0, 16),
        invoiceDateEnd: end.toISOString().slice(0, 16)
      }));

      // Fetch lookup data
      const lookup = await purchaseSummaryApi.getLookupData();
      setLookupData(lookup);
      
      // Set loading to false after initialization
      setLoading(false);
    } catch (err) {
      console.error('Error initializing page:', err);
      setError('Failed to initialize page. Please try again.');
      setLoading(false);
    }
  };

  const initializeDates = () => {
    const today = new Date();
    const start = new Date(today.setHours(0, 0, 0, 0));
    const end = new Date(today.setHours(23, 59, 59, 999));
    
    setFilters(prev => ({
      ...prev,
      invoiceDateStart: start.toISOString().slice(0, 16),
      invoiceDateEnd: end.toISOString().slice(0, 16)
    }));
  };

  const fetchLookupData = async () => {
    try {
      const lookup = await purchaseSummaryApi.getLookupData();
      setLookupData(lookup);
    } catch (err) {
      console.error('Error fetching lookup data:', err);
    }
  };

  const filterRecords = () => {
    let filtered = [...records];

    if (searchTerm) {
      filtered = filtered.filter(record =>
        record.invoiceNo?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        record.batchNo?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        record.itemName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        record.vendorName?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredRecords(filtered);
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
        invoiceDateStart: filters.invoiceDateStart || null,
        invoiceDateEnd: filters.invoiceDateEnd || null,
        inventoryDateStart: filters.inventoryDateStart || null,
        inventoryDateEnd: filters.inventoryDateEnd || null,
        itemId: filters.itemId || null,
        invoiceNo: filters.invoiceNo || null,
        reportType: filters.reportType
      };

      const data = await purchaseSummaryApi.getAll(filterParams);
      setRecords(data.records || []);
      setFilteredRecords(data.records || []);
      setTotals(data.totals || {
        totalQuantity: 0,
        totalAmount: 0,
        totalAdvanceTax: 0,
        totalDiscount: 0,
        totalPrice: 0
      });
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
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: '2-digit',
      year: 'numeric'
    });
  };

  const formatCurrency = (value) => {
    if (value === null || value === undefined) return '0.00';
    return parseFloat(value).toFixed(2);
  };

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-800 flex items-center">
          <span className="mr-2">🛒</span>
          Purchase Summary
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
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          {/* Branch */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Branch
            </label>
            <select
              name="branchId"
              value={filters.branchId}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Rawalpindi Institute of Cardiology</option>
              {lookupData.branches.map((branch) => (
                <option key={branch.id} value={branch.id}>
                  {branch.name}
                </option>
              ))}
            </select>
          </div>

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
        </div>

        {/* Item Type Radio Buttons */}
        <div className="mb-4">
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

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          {/* Invoice Date Range */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Invoice Date Range
            </label>
            <div className="flex items-center gap-2">
              <input
                type="datetime-local"
                name="invoiceDateStart"
                value={filters.invoiceDateStart}
                onChange={handleFilterChange}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <span className="text-gray-500">-</span>
              <input
                type="datetime-local"
                name="invoiceDateEnd"
                value={filters.invoiceDateEnd}
                onChange={handleFilterChange}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          {/* Inventory Data Range */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Inventory Data Range
            </label>
            <div className="flex items-center gap-2">
              <input
                type="datetime-local"
                name="inventoryDateStart"
                value={filters.inventoryDateStart}
                onChange={handleFilterChange}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <span className="text-gray-500">-</span>
              <input
                type="datetime-local"
                name="inventoryDateEnd"
                value={filters.inventoryDateEnd}
                onChange={handleFilterChange}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
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

          {/* Invoice No */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Invoice No.
            </label>
            <input
              type="text"
              name="invoiceNo"
              value={filters.invoiceNo}
              onChange={handleFilterChange}
              placeholder="Invoice No."
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Report Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Report Type
            </label>
            <select
              name="reportType"
              value={filters.reportType}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="Both">Both</option>
              <option value="Purchase">Purchase</option>
              <option value="Return">Return</option>
            </select>
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
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Sr.</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Batch No.</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Item Name</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Store Name</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Vendor</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Invoice No.</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Invoice Date</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Qty</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Advance Tax</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Discount</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Total</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredRecords.length === 0 ? (
                <tr>
                  <td colSpan="13" className="px-4 py-4 text-center text-sm text-gray-500">
                    No data available in table
                  </td>
                </tr>
              ) : (
                filteredRecords.slice(0, entriesPerPage).map((record, index) => (
                  <tr key={record.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">{index + 1}</td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">{formatDate(record.purchaseDate)}</td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">{record.batchNo || '-'}</td>
                    <td className="px-4 py-3 text-sm text-gray-500">{record.itemName}</td>
                    <td className="px-4 py-3 text-sm text-gray-500">{record.storeName || '-'}</td>
                    <td className="px-4 py-3 text-sm text-gray-500">{record.vendorName || '-'}</td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">{record.invoiceNo || '-'}</td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">{formatDate(record.invoiceDate)}</td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">{record.quantity}</td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">{formatCurrency(record.amount)}</td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">{formatCurrency(record.advanceTax)}</td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">{formatCurrency(record.discount)}</td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">{formatCurrency(record.totalPrice)}</td>
                  </tr>
                ))
              )}
            </tbody>
            {/* Totals Footer */}
            {filteredRecords.length > 0 && (
              <tfoot className="bg-gray-100">
                <tr className="font-semibold">
                  <td className="px-4 py-3 text-sm text-gray-900" colSpan="5">Sr.</td>
                  <td className="px-4 py-3 text-sm text-gray-900">Date</td>
                  <td className="px-4 py-3 text-sm text-gray-900">Batch No.</td>
                  <td className="px-4 py-3 text-sm text-gray-900">Item Name</td>
                  <td className="px-4 py-3 text-sm text-gray-900">Total Qty: {totals.totalQuantity}</td>
                  <td className="px-4 py-3 text-sm text-gray-900">Total Amount: {formatCurrency(totals.totalAmount)}</td>
                  <td className="px-4 py-3 text-sm text-gray-900">Advance Tax: {formatCurrency(totals.totalAdvanceTax)}</td>
                  <td className="px-4 py-3 text-sm text-gray-900">Total Discount: {formatCurrency(totals.totalDiscount)}</td>
                  <td className="px-4 py-3 text-sm text-gray-900">Total Price: {formatCurrency(totals.totalPrice)}</td>
                </tr>
              </tfoot>
            )}
          </table>
        </div>
      </div>

      {/* Pagination info */}
      <div className="mt-4 text-sm text-gray-700">
        Showing {filteredRecords.length > 0 ? 1 : 0} to {Math.min(entriesPerPage, filteredRecords.length)} of {filteredRecords.length} entries
      </div>
    </div>
  );
};

export default PurchaseSummaryPage;
