import React, { useState, useEffect } from 'react';
import { getSaleSummaryItemDiscount, getSaleSummaryItemDiscountTotals } from '../services/saleSummaryItemDiscountApi';
import { getAllStores } from '../services/storeApi';
import itemApi from '../services/itemApi';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';

const emptyTotals = {
  unitPurchaseRate: 0,
  unitSaleRate: 0,
  quantity: 0,
  sale: 0,
  discountAmount: 0,
  purchaseRate: 0,
  profit: 0
};

const SaleSummaryItemDiscountPage = () => {
  const [stores, setStores] = useState([]);
  const [items, setItems] = useState([]);
  const [selectedStore, setSelectedStore] = useState('');
  // No default date pre-fill - defaulting to "today" guarantees zero results against
  // historical data (the exact bug already fixed this session on the Purchase Summary and
  // Sale Summary Wrt Stock WO Discount pages). Blank means the backend applies no date
  // filter until the user picks one.
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [selectedItem, setSelectedItem] = useState('');
  const [submittedFilters, setSubmittedFilters] = useState(null);
  const [totals, setTotals] = useState(null);
  const [totalsLoading, setTotalsLoading] = useState(false);

  const {
    items: currentItems,
    totalCount,
    currentPage,
    pageSize: itemsPerPage,
    setPageSize: setItemsPerPage,
    goToPage,
    search: runSearch,
    loading,
  } = usePagedList(getSaleSummaryItemDiscount, submittedFilters || {}, { autoLoad: false, initialPageSize: 10 });

  useEffect(() => {
    fetchStores();
    fetchItems();
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

  const fetchItems = async () => {
    try {
      const response = await itemApi.getAllUnpaginated();
      setItems(response);
    } catch (error) {
      console.error('Error fetching items:', error);
    }
  };

  // The totals row must reflect every matching item, not just the page on screen, so it's
  // fetched separately from the paged list (see the backend note on
  // GetSaleSummaryItemDiscountTotalsAsync - it deliberately re-runs the query unpaginated).
  const fetchTotals = async (filters) => {
    setTotalsLoading(true);
    try {
      const totalsData = await getSaleSummaryItemDiscountTotals(filters);
      setTotals(totalsData || emptyTotals);
    } catch (error) {
      console.error('Error fetching sale summary item discount totals:', error);
      setTotals(emptyTotals);
    } finally {
      setTotalsLoading(false);
    }
  };

  const handleSearch = () => {
    const filters = { store: selectedStore, startDate, endDate, item: selectedItem };
    setSubmittedFilters(filters);
    runSearch(filters);
    fetchTotals(filters);
  };

  const formatNumber = (num) => {
    return num.toFixed(2);
  };

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="max-w-full mx-auto bg-white rounded-lg shadow-md p-6">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-blue-600">Sale Summary Wrt Items Wise Discount</h1>
          <button
            onClick={handleSearch}
            disabled={loading || totalsLoading}
            className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading || totalsLoading ? 'Generating...' : 'Generate Report'}
          </button>
        </div>

        {/* Filters */}
        <div className="grid grid-cols-3 gap-4 mb-6">
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
            <label className="block text-sm font-medium mb-2">Item</label>
            <select
              value={selectedItem}
              onChange={(e) => setSelectedItem(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded"
            >
              <option value="">All Items</option>
              {items.map((item) => (
                <option key={item.id} value={item.name}>
                  {item.name}
                </option>
              ))}
            </select>
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
                <th className="px-4 py-2 text-left text-sm font-semibold">Discount Amount</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Total Purchase Rate</th>
                <th className="px-4 py-2 text-left text-sm font-semibold">Profit</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="8" className="px-4 py-8 text-center text-gray-500">
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
                      <td className="px-4 py-2 text-sm">{formatNumber(summary.discountAmount)}</td>
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
                      <td className="px-4 py-2 text-sm">Discount Amount : {formatNumber(totals.discountAmount)}</td>
                      <td className="px-4 py-2 text-sm">PurchaseRate : {formatNumber(totals.purchaseRate)}</td>
                      <td className="px-4 py-2 text-sm">Profit : {formatNumber(totals.profit)}</td>
                    </tr>
                  )}
                </>
              ) : (
                <tr>
                  <td colSpan="8" className="px-4 py-8 text-center text-gray-500">
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

export default SaleSummaryItemDiscountPage;
