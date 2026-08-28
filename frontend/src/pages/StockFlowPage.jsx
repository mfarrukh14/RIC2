import React,{ useCallback, useState, useEffect } from 'react';
import { MagnifyingGlassIcon, ArrowDownTrayIcon } from '@heroicons/react/24/outline';
import { getStockFlow } from '../services/stockFlowApi';
import { getAllStores } from '../services/storeApi';
import itemApi from '../services/itemApi';
import grnApi from '../services/grnApi';
import demandRequestApi from '../services/demandRequestApi';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';

// Default to the last 30 days up to now, instead of a zero-width "right now to right
// now" window that can never match any historical row.
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

// Distinct, non-empty values from a list of records for a dropdown - used for the
// filter fields that don't have their own lookup endpoint (GRN/demand request numbers).
const distinctValues = (records, key) =>
  Array.from(new Set((records || []).map(r => r[key]).filter(Boolean))).sort();

const StockFlowPage = () => {
  const [stores, setStores] = useState([]);
  const [items, setItems] = useState([]);
  const [poNumbers, setPoNumbers] = useState([]);
  const [invoiceNumbers, setInvoiceNumbers] = useState([]);
  const [demandRequestNumbers, setDemandRequestNumbers] = useState([]);

  const [filters, setFilters] = useState({
    ...getDefaultDateRange(),
    store: '',
    item: '',
    inventoryNo: '',
    challanNo: '',
    invoiceNo: '',
    demandRequestNo: ''
  });

  const fetchPage = useCallback(async (params) => {
    const data = await getStockFlow(params);
    return { items: data.items || [], totalCount: data.totalCount || 0 };
  }, []);

  const {
    items: stockFlows,
    totalCount,
    currentPage,
    pageSize: entriesPerPage,
    setPageSize: setEntriesPerPage,
    goToPage,
    search: runSearch,
    loading,
    error,
  } = usePagedList(fetchPage, filters, { autoLoad: false, initialPageSize: 10 });

  useEffect(() => {
    loadFilterLookups();
  }, []);

  const loadFilterLookups = async () => {
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

    try {
      const grnData = await grnApi.getAll();
      setPoNumbers(distinctValues(grnData, 'poNumber'));
      setInvoiceNumbers(distinctValues(grnData, 'invoiceNo'));
    } catch (err) {
      console.error('Error loading GRN reference numbers:', err);
    }

    try {
      const demandRequestsData = await demandRequestApi.getAll();
      setDemandRequestNumbers(distinctValues(demandRequestsData, 'drNo'));
    } catch (err) {
      console.error('Error loading demand request numbers:', err);
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
    runSearch(filters);
  };

  // Exports only the currently-loaded page, not the whole filtered result set -
  // results are now paged server-side, same tradeoff as StockPage's export.
  const handleExport = () => {
    // Export functionality - convert to CSV
    const headers = ['Date & Time', 'Transaction Type', 'Ref Number', 'Item Name', 'Demand Requested Store', 
                     'Stock Type', 'Opening Quantity', 'Received Quantity', 'Issued Quantity', 'Balance Quantity', 
                     'Batch No', 'Action By'];
    
    const csvContent = [
      headers.join(','),
      ...stockFlows.map(row => [
        new Date(row.dateTime).toLocaleString(),
        row.transactionType,
        row.refNumber,
        row.itemName,
        row.demandRequestedStore,
        row.stockType,
        row.openingQuantity,
        row.receivedQuantity,
        row.issuedQuantity,
        row.balanceQuantity,
        row.batchNo || '',
        row.actionBy
      ].join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `stock-flow-${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
  };

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center gap-2">
          <h1 className="text-2xl font-bold text-gray-800">Stock Flow</h1>
          <div className="w-5 h-5 bg-blue-600 rounded-full flex items-center justify-center text-white text-xs">
            i
          </div>
        </div>
        <button
          onClick={handleExport}
          disabled={stockFlows.length === 0}
          className="bg-white border border-gray-300 text-gray-700 px-4 py-2 rounded hover:bg-gray-50 flex items-center gap-2 disabled:opacity-50"
        >
          <ArrowDownTrayIcon className="h-5 w-5" />
          Export
        </button>
      </div>

      {/* Filters Section */}
      <div className="bg-white rounded-lg shadow-md p-6 mb-6">
        {/* Auto-fit columns reflow (stagger) fields onto new rows as space shrinks,
            instead of squeezing every field into a fixed column count and overlapping
            at in-between "laptop" widths. */}
        <div className="grid gap-4 mb-4" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))' }}>
          <div className="min-w-0">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Date Range <span className="text-red-500">*</span>
            </label>
            <div className="flex flex-wrap gap-2">
              <input
                type="datetime-local"
                name="startDate"
                value={filters.startDate}
                onChange={handleFilterChange}
                className="flex-1 min-w-[180px] px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
              />
              <span className="self-center">-</span>
              <input
                type="datetime-local"
                name="endDate"
                value={filters.endDate}
                onChange={handleFilterChange}
                min={filters.startDate}
                className="flex-1 min-w-[180px] px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
              />
            </div>
          </div>

          <div className="min-w-0">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Store
            </label>
            <select
              name="store"
              value={filters.store}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Stores</option>
              {stores.map(store => (
                <option key={store.storeId} value={store.storeId}>
                  {store.storeName}
                </option>
              ))}
            </select>
          </div>

          <div className="min-w-0">
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

          <div className="min-w-0">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Inventory No.
            </label>
            <select
              name="inventoryNo"
              value={filters.inventoryNo}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All</option>
              {poNumbers.map(no => (
                <option key={no} value={no}>{no}</option>
              ))}
            </select>
          </div>

          <div className="min-w-0">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Challan No.
            </label>
            <input
              type="text"
              name="challanNo"
              value={filters.challanNo}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div className="min-w-0">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Invoice No.
            </label>
            <select
              name="invoiceNo"
              value={filters.invoiceNo}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All</option>
              {invoiceNumbers.map(no => (
                <option key={no} value={no}>{no}</option>
              ))}
            </select>
          </div>

          <div className="min-w-0">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Demand Request No.
            </label>
            <select
              name="demandRequestNo"
              value={filters.demandRequestNo}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All</option>
              {demandRequestNumbers.map(no => (
                <option key={no} value={no}>{no}</option>
              ))}
            </select>
          </div>
        </div>

        <div className="flex justify-end">
          <button
            onClick={handleSearch}
            className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2"
          >
            <MagnifyingGlassIcon className="h-5 w-5" />
            Search
          </button>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
          Failed to load stock flow data{error.message ? `: ${error.message}` : ''}
        </div>
      )}

      {/* Stock Flow Table */}
      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date & Time
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Transaction Type
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Ref Number
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Item Name
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Demand Requested Store
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Stock Type
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Opening Quantity
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Received Quantity
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Issued Quantity
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Balance Quantity
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Batch No
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action By
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {loading ? (
                <tr>
                  <td colSpan="12" className="px-6 py-4 text-center text-gray-500">
                    Loading...
                  </td>
                </tr>
              ) : stockFlows.length === 0 ? (
                <tr>
                  <td colSpan="12" className="px-6 py-4 text-center text-gray-500">
                    No data available in table
                  </td>
                </tr>
              ) : (
                stockFlows.map((flow, index) => (
                  <tr key={index} className="hover:bg-gray-50">
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                      {new Date(flow.dateTime).toLocaleString()}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                      {flow.transactionType}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                      {flow.refNumber}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                      {flow.itemName}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                      {flow.demandRequestedStore}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                      {flow.stockType}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                      {flow.openingQuantity}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                      {flow.receivedQuantity}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                      {flow.issuedQuantity}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                      {flow.balanceQuantity}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                      {flow.batchNo || '-'}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                      {flow.actionBy}
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

export default StockFlowPage;
