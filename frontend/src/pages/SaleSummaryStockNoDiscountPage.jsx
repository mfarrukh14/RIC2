import React, { useState, useEffect } from 'react';
import { getSaleSummaryStockNoDiscount, getSaleSummaryStockNoDiscountTotals } from '../services/saleSummaryStockNoDiscountApi';
import { getAllStores } from '../services/storeApi';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';

const DEFAULT_TOTALS = {
  unitPurchaseRate: 0,
  unitSaleRate: 0,
  quantity: 0,
  sale: 0,
  purchaseRate: 0,
  profit: 0,
  discountAmount: 0
};

const SaleSummaryStockNoDiscountPage = () => {
  const [stores, setStores] = useState([]);
  const [selectedStore, setSelectedStore] = useState('');
  // No default date pre-fill - defaulting to "today" guarantees zero results against
  // historical data (the exact bug already fixed this session on the Purchase Summary
  // pages). Leaving these blank means the backend applies no date filter until the user
  // picks one.
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  // The filters actually sent to the server - only updated when "Generate Report" is
  // clicked (or on first load), so editing a dropdown mid-form doesn't re-trigger a search.
  const [submittedFilters, setSubmittedFilters] = useState({ store: '', startDate: '', endDate: '' });

  const [totals, setTotals] = useState(null);
  const [totalsLoading, setTotalsLoading] = useState(false);

  const {
    items: summaries,
    totalCount,
    currentPage,
    pageSize: itemsPerPage,
    setPageSize: setItemsPerPage,
    goToPage,
    search: runSearch,
    loading,
    error,
  } = usePagedList(getSaleSummaryStockNoDiscount, submittedFilters, { autoLoad: false, initialPageSize: 10 });

  useEffect(() => {
    fetchStores();
    fetchTotals(submittedFilters);
    runSearch(submittedFilters);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const fetchStores = async () => {
    try {
      const response = await getAllStores();
      setStores(response);
    } catch (error) {
      console.error('Error fetching stores:', error);
    }
  };

  // Totals reflect the full filtered result server-side (see
  // GetSaleSummaryStockNoDiscountTotalsAsync), independent of which page of the list is
  // currently loaded - fetched alongside the paged list, not derived from it.
  const fetchTotals = async (filters) => {
    setTotalsLoading(true);
    try {
      const totalsData = await getSaleSummaryStockNoDiscountTotals(filters.store, filters.startDate, filters.endDate);
      setTotals(totalsData || DEFAULT_TOTALS);
    } catch (err) {
      console.error('Error fetching sale summary stock no discount totals:', err);
      setTotals(DEFAULT_TOTALS);
    } finally {
      setTotalsLoading(false);
    }
  };

  const handleSearch = () => {
    const filters = { store: selectedStore, startDate, endDate };
    setSubmittedFilters(filters);
    runSearch(filters);
    fetchTotals(filters);
  };

  const formatNumber = (num) => {
    return Number(num ?? 0).toFixed(2);
  };

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="max-w-full mx-auto bg-white rounded-lg shadow-md p-6">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-blue-600">Sale Summary Wrt Stock WO Discount</h1>
          <button
            onClick={handleSearch}
            disabled={loading || totalsLoading}
            className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:bg-gray-400"
          >
            {loading || totalsLoading ? 'Generating...' : 'Generate Report'}
          </button>
        </div>

        {/* Filters */}
        <div className="grid grid-cols-2 gap-4 mb-6">
          <div>
            <label className="block text-sm font-medium mb-2">Store</label>
            <select
              value={selectedStore}
              onChange={(e) => setSelectedStore(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded"
            >
              <option value="">All Stores</option>
              {stores.map((store) => (
                <option key={store.storeId} value={store.storeName}>
                  {store.storeName}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Date Range:</label>
            <div className="flex gap-2 items-center">
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="flex-1 px-3 py-2 border border-gray-300 rounded"
              />
              <span>-</span>
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className="flex-1 px-3 py-2 border border-gray-300 rounded"
              />
            </div>
          </div>
        </div>

        {/* Section Title */}
        <div className="mb-4">
          <h2 className="text-lg font-semibold text-gray-700">Item Wise Profit & Loss</h2>
        </div>

        {error && (
          <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
            Failed to load sale summary{error.message ? `: ${error.message}` : ''}
          </div>
        )}

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full border-collapse">
            <thead>
              <tr className="bg-blue-100 border-b">
                <th className="px-4 py-2 text-left text-sm font-semibold">Name</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Unit Purchase Rate</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Unit Sale Rate</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Quantity</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Sale</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Total Purchase Rate</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Profit</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="7" className="px-4 py-8 text-center text-gray-500">
                    Loading...
                  </td>
                </tr>
              ) : summaries.length > 0 ? (
                <>
                  {summaries.map((summary, index) => (
                    <tr key={index} className="border-b hover:bg-gray-50">
                      <td className="px-4 py-2 text-sm">{summary.name}</td>
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.unitPurchaseRate)}</td>
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.unitSaleRate)}</td>
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.quantity)}</td>
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.sale)}</td>
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.totalPurchaseRate)}</td>
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.profit)}</td>
                    </tr>
                  ))}
                  {totals && (
                    <tr className="bg-gray-100 font-semibold border-t-2">
                      <td className="px-4 py-2 text-sm">Name</td>
                      <td className="px-4 py-2 text-sm">Unit Purchase Rate : {formatNumber(totals.unitPurchaseRate)}</td>
                      <td className="px-4 py-2 text-sm">Unit Sale Rate : {formatNumber(totals.unitSaleRate)}</td>
                      <td className="px-4 py-2 text-sm">Quantity : {formatNumber(totals.quantity)}</td>
                      <td className="px-4 py-2 text-sm">Sale : {formatNumber(totals.sale)}</td>
                      <td className="px-4 py-2 text-sm">PurchaseRate : {formatNumber(totals.purchaseRate)}</td>
                      <td className="px-4 py-2 text-sm">Profit : {formatNumber(totals.profit)}</td>
                    </tr>
                  )}
                </>
              ) : (
                <tr>
                  <td colSpan="7" className="px-4 py-8 text-center text-gray-500">
                    No data available in table
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Additional Totals Section */}
        {totals && (
          <div className="mt-6 p-4 bg-gray-50 rounded">
            <div className="text-sm text-gray-700">
              <span className="font-semibold">Discount Amount : </span>
              {formatNumber(totals.discountAmount)}
            </div>
          </div>
        )}

        <Pagination
          currentPage={currentPage}
          pageSize={itemsPerPage}
          totalCount={totalCount}
          onPageChange={goToPage}
          onPageSizeChange={setItemsPerPage}
        />
      </div>
    </div>
  );
};

export default SaleSummaryStockNoDiscountPage;
