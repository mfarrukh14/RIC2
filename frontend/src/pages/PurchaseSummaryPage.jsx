import React, { useCallback, useState, useEffect } from 'react';
import purchaseSummaryApi from '../services/purchaseSummaryApi';
import BranchField from '../components/BranchField';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';
import { useSession } from '../context/SessionContext';

const PurchaseSummaryPage = () => {
  const { session } = useSession();
  const [totals, setTotals] = useState({
    totalQuantity: 0,
    totalAmount: 0,
    totalAdvanceTax: 0,
    totalDiscount: 0,
    totalPrice: 0
  });
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
    vendorId: '',
    invoiceNo: '',
    reportType: 'Both'
  });

  // The filters actually sent to the server - only updated on "Generate Report".
  const [submittedFilters, setSubmittedFilters] = useState(null);

  // Totals cover the full filtered scope, not just the current page - the
  // fetcher below stashes them into `totals` as a side effect of each fetch.
  const fetchPage = useCallback(async (params) => {
    const data = await purchaseSummaryApi.getAll(params);
    setTotals(data.totals || { totalQuantity: 0, totalAmount: 0, totalAdvanceTax: 0, totalDiscount: 0, totalPrice: 0 });
    return { items: data.records || [], totalCount: data.totalCount || 0 };
  }, []);

  const {
    items: records,
    totalCount,
    currentPage,
    pageSize: entriesPerPage,
    setPageSize: setEntriesPerPage,
    goToPage,
    search: runSearch,
    loading,
  } = usePagedList(fetchPage, submittedFilters || {}, { autoLoad: false, initialPageSize: 10 });

  useEffect(() => {
    initializePage();
  }, []);

  // Purchases are always scoped to the logged-in user's own branch.
  useEffect(() => {
    if (session?.branchId) {
      setFilters((prev) => ({ ...prev, branchId: session.branchId }));
    }
  }, [session?.branchId]);

  const initializePage = async () => {
    try {
      // Invoice Date Range is left blank by default - defaulting it to
      // "today" meant Generate Report showed nothing unless a GRN happened
      // to be dated the exact day the page was opened, hiding virtually all
      // real/migrated purchase history behind an empty-looking report.

      // Fetch lookup data
      const lookup = await purchaseSummaryApi.getLookupData();
      setLookupData(lookup);
    } catch (err) {
      console.error('Error initializing page:', err);
      setError('Failed to initialize page. Please try again.');
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

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setFilters(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleGenerateReport = () => {
    const filterParams = {
      branchId: filters.branchId || null,
      storeId: filters.storeId || null,
      itemType: filters.itemType !== 'All' ? filters.itemType : null,
      invoiceDateStart: filters.invoiceDateStart || null,
      invoiceDateEnd: filters.invoiceDateEnd || null,
      inventoryDateStart: filters.inventoryDateStart || null,
      inventoryDateEnd: filters.inventoryDateEnd || null,
      itemId: filters.itemId || null,
      vendorId: filters.vendorId || null,
      invoiceNo: filters.invoiceNo || null,
      reportType: filters.reportType
    };
    setError(null);
    setSubmittedFilters(filterParams);
    runSearch(filterParams);
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
              <option value="">All Stores</option>
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

        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">
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

          {/* Vendor */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Vendor
            </label>
            <select
              name="vendorId"
              value={filters.vendorId}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Vendors</option>
              {lookupData.vendors.map((vendor) => (
                <option key={vendor.id} value={vendor.id}>
                  {vendor.name}
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
              <option value="PurchaseOrder">On Purchase Order</option>
              <option value="Inventory">On Inventory</option>
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
              {records.length === 0 ? (
                <tr>
                  <td colSpan="13" className="px-4 py-4 text-center text-sm text-gray-500">
                    {loading ? 'Loading...' : 'No data available in table'}
                  </td>
                </tr>
              ) : (
                records.map((record, index) => (
                  <tr key={record.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">{(currentPage - 1) * entriesPerPage + index + 1}</td>
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
            {records.length > 0 && (
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

      <Pagination
        currentPage={currentPage}
        pageSize={entriesPerPage}
        totalCount={totalCount}
        onPageChange={goToPage}
        onPageSizeChange={setEntriesPerPage}
      />
    </div>
  );
};

export default PurchaseSummaryPage;
