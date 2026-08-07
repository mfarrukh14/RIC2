import React, { useState, useEffect } from 'react';
import { getSaleSummaryStockNoDiscount, getSaleSummaryStockNoDiscountTotals } from '../services/saleSummaryStockNoDiscountApi';
import { getAllStores } from '../services/storeApi';

const SaleSummaryStockNoDiscountPage = () => {
  const [stores, setStores] = useState([]);
  const [selectedStore, setSelectedStore] = useState('');
  // No default date pre-fill - defaulting to "today" guarantees zero results against
  // historical data (the exact bug already fixed this session on the Purchase Summary
  // pages). Leaving these blank means the backend applies no date filter until the user
  // picks one.
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [summaries, setSummaries] = useState([]);
  const [totals, setTotals] = useState(null);
  const [loading, setLoading] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchStores();
    fetchSummary();
  }, []);

  const fetchStores = async () => {
    try {
      const response = await getAllStores();
      setStores(response);
    } catch (error) {
      console.error('Error fetching stores:', error);
    }
  };

  const fetchSummary = async () => {
    setLoading(true);
    try {
      const [summaryData, totalsData] = await Promise.all([
        getSaleSummaryStockNoDiscount(selectedStore, startDate, endDate),
        getSaleSummaryStockNoDiscountTotals(selectedStore, startDate, endDate)
      ]);
      
      setSummaries(summaryData || []);
      setTotals(totalsData || {
        unitPurchaseRate: 0,
        unitSaleRate: 0,
        quantity: 0,
        sale: 0,
        purchaseRate: 0,
        profit: 0,
        discountAmount: 0
      });
    } catch (error) {
      console.error('Error fetching sale summary stock no discount:', error);
      setSummaries([]);
      setTotals({
        unitPurchaseRate: 0,
        unitSaleRate: 0,
        quantity: 0,
        sale: 0,
        purchaseRate: 0,
        profit: 0,
        discountAmount: 0
      });
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    setCurrentPage(1);
    fetchSummary();
  };

  const formatNumber = (num) => {
    return num.toFixed(2);
  };

  // Pagination
  const filteredSummaries = summaries.filter((summary) =>
    summary.name?.toLowerCase().includes(searchTerm.toLowerCase())
  );
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = filteredSummaries.slice(indexOfFirstItem, indexOfLastItem);
  const totalPages = Math.ceil(filteredSummaries.length / itemsPerPage);

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="max-w-full mx-auto bg-white rounded-lg shadow-md p-6">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-blue-600">Sale Summary Wrt Stock WO Discount</h1>
          <button
            onClick={handleSearch}
            className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
          >
            Generate Report
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

        {/* Table Header Info */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <span className="text-sm">Show</span>
            <select
              value={itemsPerPage}
              onChange={(e) => {
                setItemsPerPage(Number(e.target.value));
                setCurrentPage(1);
              }}
              className="px-2 py-1 border border-gray-300 rounded"
            >
              <option value={10}>10</option>
              <option value={25}>25</option>
              <option value={50}>50</option>
              <option value={100}>100</option>
            </select>
            <span className="text-sm">entries</span>
          </div>
          <div className="text-sm">
            Search: <input type="text" className="px-2 py-1 border border-gray-300 rounded" />
          </div>
        </div>

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
              ) : currentItems.length > 0 ? (
                <>
                  {currentItems.map((summary, index) => (
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

        {/* Footer */}
        <div className="flex items-center justify-between mt-4">
          <div className="text-sm text-gray-600">
            Showing {indexOfFirstItem + 1} to {Math.min(indexOfLastItem, summaries.length)} of {summaries.length} entries
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
              disabled={currentPage === 1}
              className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50"
            >
              Previous
            </button>
            {[...Array(totalPages)].map((_, i) => (
              <button
                key={i + 1}
                onClick={() => setCurrentPage(i + 1)}
                className={`px-3 py-1 border rounded ${
                  currentPage === i + 1
                    ? 'bg-blue-600 text-white border-blue-600'
                    : 'border-gray-300 hover:bg-gray-50'
                }`}
              >
                {i + 1}
              </button>
            ))}
            <button
              onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
              disabled={currentPage === totalPages}
              className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50"
            >
              Next
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SaleSummaryStockNoDiscountPage;
