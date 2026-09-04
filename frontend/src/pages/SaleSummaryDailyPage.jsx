import React, { useState, useEffect } from 'react';
import { getSaleSummary, getSaleSummarySummary } from '../services/saleSummaryDailyApi';
import { getAllStores } from '../services/storeApi';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';

const SaleSummaryDailyPage = () => {
  const [stores, setStores] = useState([]);
  const [selectedStore, setSelectedStore] = useState('');
  // No default date pre-fill - defaulting to "today" guarantees zero results against
  // historical data (the exact bug already fixed this session on the Purchase Summary and
  // Sale Summary Wrt Stock WO Discount pages). Blank means the backend applies no date
  // filter until the user picks one.
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [selectedType, setSelectedType] = useState('Daily');
  const [totals, setTotals] = useState(null);

  // The filters actually sent to the server - only updated when a search runs, same
  // pattern as StockPage/StockStatsPage.
  const [submittedFilters, setSubmittedFilters] = useState(null);

  const {
    items: summaries,
    totalCount,
    currentPage,
    pageSize: itemsPerPage,
    setPageSize: setItemsPerPage,
    goToPage,
    search: runSearch,
    loading,
  } = usePagedList(getSaleSummary, submittedFilters || {}, { autoLoad: false, initialPageSize: 10 });

  const emptyTotals = {
    totalCount: 0,
    grossSales: 0,
    discounts: 0,
    totalSales: 0,
    totalSReturn: 0,
    netSale: 0,
    costOfSales: 0,
    gpAmount: 0,
    gpPercentage: 0
  };

  useEffect(() => {
    fetchStores();
    handleSearch();
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

  // Grand totals reflect the *entire* filtered range, not just the page on screen, so
  // they're fetched from the dedicated (unpaged) /summary endpoint rather than derived
  // from `summaries`.
  const fetchTotals = async (filters) => {
    try {
      const totalsData = await getSaleSummarySummary(filters.store, filters.startDate, filters.endDate, filters.type);
      setTotals(totalsData || emptyTotals);
    } catch (error) {
      console.error('Error fetching sale summary totals:', error);
      setTotals(emptyTotals);
    }
  };

  const handleSearch = () => {
    const filters = { store: selectedStore, startDate, endDate, type: selectedType };
    setSubmittedFilters(filters);
    runSearch(filters);
    fetchTotals(filters);
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-GB', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  const formatNumber = (num) => {
    return num.toFixed(2);
  };

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="max-w-full mx-auto bg-white rounded-lg shadow-md p-6">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-blue-600">Sale Summary Daily</h1>
          <button
            onClick={handleSearch}
            className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
          >
            Generate Report
          </button>
        </div>

        {/* Filters */}
        <div className="grid grid-cols-4 gap-4 mb-6">
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

          <div>
            <label className="block text-sm font-medium mb-2">Type</label>
            <div className="flex items-center gap-4 mt-3">
              <label className="flex items-center">
                <input
                  type="radio"
                  value="Daily"
                  checked={selectedType === 'Daily'}
                  onChange={(e) => setSelectedType(e.target.value)}
                  className="mr-2"
                />
                Daily
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  value="Monthly"
                  checked={selectedType === 'Monthly'}
                  onChange={(e) => setSelectedType(e.target.value)}
                  className="mr-2"
                />
                Monthly
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  value="Yearly"
                  checked={selectedType === 'Yearly'}
                  onChange={(e) => setSelectedType(e.target.value)}
                  className="mr-2"
                />
                Yearly
              </label>
            </div>
          </div>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full border-collapse">
            <thead>
              <tr className="bg-blue-100 border-b">
                <th className="px-4 py-2 text-left text-sm font-semibold">Date</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Count</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Gross Sales</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Discounts</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Total Sales</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Total S/Return</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Net Sale</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Cost of Sales</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">G/P Amount</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">G/P (%)</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="10" className="px-4 py-8 text-center text-gray-500">
                    Loading...
                  </td>
                </tr>
              ) : summaries.length > 0 ? (
                <>
                  {summaries.map((summary, index) => (
                    <tr key={index} className="border-b hover:bg-gray-50">
                      <td className="px-4 py-2 text-sm">{formatDate(summary.date)}</td>
                      <td className="px-4 py-2 text-sm">{summary.count}</td>
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.grossSales)}</td>
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.discounts)}</td>
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.totalSales)}</td>
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.totalSReturn)}</td>
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.netSale)}</td>
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.costOfSales)}</td>
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.gpAmount)}</td>
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.gpPercentage)}</td>
                    </tr>
                  ))}
                  {totals && (
                    <tr className="bg-gray-100 font-semibold border-t-2">
                      <td className="px-4 py-2 text-sm">Date</td>
                      <td className="px-4 py-2 text-sm">Total Count : {totals.totalCount}</td>
                      <td className="px-4 py-2 text-sm">Gross Sales : {formatNumber(totals.grossSales)}</td>
                      <td className="px-4 py-2 text-sm">Discounts : {formatNumber(totals.discounts)}</td>
                      <td className="px-4 py-2 text-sm">Total Sales : {formatNumber(totals.totalSales)}</td>
                      <td className="px-4 py-2 text-sm">Total S/Return : {formatNumber(totals.totalSReturn)}</td>
                      <td className="px-4 py-2 text-sm">Net Sale : {formatNumber(totals.netSale)}</td>
                      <td className="px-4 py-2 text-sm">Cost of Sales : {formatNumber(totals.costOfSales)}</td>
                      <td className="px-4 py-2 text-sm">G/P Amount : {formatNumber(totals.gpAmount)}</td>
                      <td className="px-4 py-2 text-sm">G/P (%) : {formatNumber(totals.gpPercentage)}</td>
                    </tr>
                  )}
                </>
              ) : (
                <tr>
                  <td colSpan="10" className="px-4 py-8 text-center text-gray-500">
                    No data available in table
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

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

export default SaleSummaryDailyPage;
