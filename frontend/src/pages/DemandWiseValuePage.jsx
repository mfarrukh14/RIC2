import React, { useEffect, useMemo, useState } from 'react';
import { ArrowDownTrayIcon, InformationCircleIcon } from '@heroicons/react/24/outline';
import { branchApi } from '../services/branchApi';
import demandWiseValueApi from '../services/demandWiseValueApi';
import { getAllStores } from '../services/storeApi';
import itemApi from '../services/itemApi';

function formatDateTime(value) {
  if (!value) {
    return '-';
  }

  return new Date(value).toLocaleString('en-GB', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true
  });
}

function toDateTimeLocalValue(date) {
  const adjusted = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
  return adjusted.toISOString().slice(0, 16);
}

function defaultDateRange() {
  const now = new Date();
  const start = new Date(now);
  start.setHours(0, 0, 0, 0);
  const end = new Date(now);
  end.setHours(23, 59, 0, 0);

  return {
    startDate: toDateTimeLocalValue(start),
    endDate: toDateTimeLocalValue(end)
  };
}

function formatCurrency(value) {
  return Number(value || 0).toFixed(2);
}

const itemTypes = ['All', 'Medicine(s)', 'Disposable(s)', 'Item(s)'];

const DemandWiseValuePage = () => {
  const [lookups, setLookups] = useState({ branches: [], stores: [], items: [] });
  const [filters, setFilters] = useState({
    branchId: '',
    storeId: '',
    itemType: 'All',
    itemId: '',
    ...defaultDateRange()
  });
  const [records, setRecords] = useState([]);
  const [totals, setTotals] = useState({ totalIssuedQty: 0, totalUnitBuyingPrice: 0, totalBuyingPrice: 0 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [entriesPerPage, setEntriesPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);

  useEffect(() => {
    const initialize = async () => {
      setLoading(true);
      try {
        const [branches, stores, items] = await Promise.all([
          branchApi.getAll(),
          getAllStores(),
          itemApi.getAll()
        ]);

        const defaultBranch = branches.find((branch) => branch.name === 'Rawalpindi Institute of Cardiology') || branches[0];
        const defaultStore = stores.find((store) => store.storeName === 'Academic Affair Store') || stores[0];

        setLookups({ branches, stores, items });

        const nextFilters = {
          ...defaultDateRange(),
          branchId: defaultBranch ? String(defaultBranch.id) : '',
          storeId: defaultStore ? String(defaultStore.storeId) : '',
          itemType: 'All',
          itemId: ''
        };

        setFilters(nextFilters);
        await loadReport(nextFilters, '');
      } catch (initializationError) {
        console.error('Error initializing demand wise value page:', initializationError);
        setError('Failed to initialize demand wise value page.');
      } finally {
        setLoading(false);
      }
    };

    initialize();
  }, []);

  const loadReport = async (activeFilters = filters, activeSearch = searchTerm) => {
    try {
      setError('');
      const response = await demandWiseValueApi.getAll({
        branchId: activeFilters.branchId || undefined,
        storeId: activeFilters.storeId || undefined,
        itemType: activeFilters.itemType === 'All' ? undefined : activeFilters.itemType,
        itemId: activeFilters.itemId || undefined,
        startDate: activeFilters.startDate ? new Date(activeFilters.startDate).toISOString() : undefined,
        endDate: activeFilters.endDate ? new Date(activeFilters.endDate).toISOString() : undefined,
        search: activeSearch?.trim() || undefined
      });

      setRecords(response.records || []);
      setTotals(response.totals || { totalIssuedQty: 0, totalUnitBuyingPrice: 0, totalBuyingPrice: 0 });
    } catch (reportError) {
      console.error('Error loading demand wise value report:', reportError);
      setRecords([]);
      setTotals({ totalIssuedQty: 0, totalUnitBuyingPrice: 0, totalBuyingPrice: 0 });
      setError('Failed to load demand wise value report.');
    }
  };

  const handleFilterChange = (event) => {
    const { name, value } = event.target;
    setFilters((current) => ({
      ...current,
      [name]: value
    }));
  };

  const handleApplyFilters = async () => {
    setLoading(true);
    setCurrentPage(1);
    await loadReport(filters, searchTerm);
    setLoading(false);
  };

  const handleExport = () => {
    const rows = records.map((record) => [
      record.sr,
      record.itemName,
      record.drNo,
      record.batchNo || '',
      formatDateTime(record.issuedDate),
      record.issuedQty,
      record.status,
      formatCurrency(record.unitBuyingPrice),
      formatCurrency(record.totalBuyingPrice)
    ]);

    const csv = [
      ['Sr.', 'Item Name', 'DR No.', 'Batch No.', 'Issued Date', 'Issued Qty', 'Status', 'Unit Buying Price', 'Total Buying Price'],
      ...rows
    ]
      .map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(','))
      .join('\n');

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'demand-wise-value.csv';
    link.click();
    URL.revokeObjectURL(url);
  };

  const pageItems = useMemo(() => {
    const startIndex = (currentPage - 1) * entriesPerPage;
    return records.slice(startIndex, startIndex + entriesPerPage);
  }, [currentPage, entriesPerPage, records]);

  useEffect(() => {
    setCurrentPage(1);
  }, [entriesPerPage, records]);

  const totalPages = Math.max(1, Math.ceil(records.length / entriesPerPage));
  const showingFrom = records.length === 0 ? 0 : (currentPage - 1) * entriesPerPage + 1;
  const showingTo = Math.min(currentPage * entriesPerPage, records.length);

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="flex items-center justify-between border-b border-slate-100 px-6 py-3">
            <h1 className="flex items-center gap-2 text-xl font-semibold text-slate-900">
              Demand Wise Value
              <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
            </h1>

            <button
              type="button"
              onClick={handleExport}
              className="inline-flex items-center gap-2 rounded-md border border-slate-200 px-3 py-2 text-sm text-slate-700 hover:bg-slate-50"
            >
              <ArrowDownTrayIcon className="h-4 w-4 text-indigo-500" />
              Export
            </button>
          </div>

          <div className="grid grid-cols-1 gap-x-4 gap-y-6 px-6 py-5 lg:grid-cols-2">
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Branch</label>
              <select
                name="branchId"
                value={filters.branchId}
                onChange={handleFilterChange}
                className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              >
                {lookups.branches.map((branch) => (
                  <option key={branch.id} value={branch.id}>{branch.name}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Store</label>
              <select
                name="storeId"
                value={filters.storeId}
                onChange={handleFilterChange}
                className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              >
                {lookups.stores.map((store) => (
                  <option key={store.storeId} value={store.storeId}>{store.storeName}</option>
                ))}
              </select>
            </div>

            <div className="lg:col-span-2">
              <label className="mb-2 block text-sm font-medium text-slate-700">Item Type</label>
              <div className="flex flex-wrap gap-4 pt-1 text-sm text-slate-700">
                {itemTypes.map((itemType) => (
                  <label key={itemType} className="inline-flex items-center gap-2">
                    <input
                      type="radio"
                      name="itemType"
                      value={itemType}
                      checked={filters.itemType === itemType}
                      onChange={handleFilterChange}
                      className="h-4 w-4 border-slate-300 text-indigo-600 focus:ring-indigo-500"
                    />
                    {itemType}
                  </label>
                ))}
              </div>
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Date Range Filter</label>
              <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
                <input
                  type="datetime-local"
                  name="startDate"
                  value={filters.startDate}
                  onChange={handleFilterChange}
                  className="rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                />
                <input
                  type="datetime-local"
                  name="endDate"
                  value={filters.endDate}
                  onChange={handleFilterChange}
                  className="rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                />
              </div>
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Item</label>
              <select
                name="itemId"
                value={filters.itemId}
                onChange={handleFilterChange}
                className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              >
                <option value="">All Items</option>
                {lookups.items.map((item) => (
                  <option key={item.id} value={item.id}>{item.name}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="flex justify-end px-6 pb-5">
            <button
              type="button"
              onClick={handleApplyFilters}
              className="rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
            >
              Apply Filters
            </button>
          </div>
        </section>

        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="flex flex-col gap-4 border-b border-slate-100 px-5 py-4 lg:flex-row lg:items-center lg:justify-between">
            <div className="flex items-center gap-2 text-sm text-slate-700">
              <span>Show</span>
              <select
                value={entriesPerPage}
                onChange={(event) => setEntriesPerPage(Number(event.target.value))}
                className="rounded-md border border-slate-200 px-2 py-1 text-sm outline-none focus:border-indigo-400"
              >
                <option value={10}>10</option>
                <option value={25}>25</option>
                <option value={50}>50</option>
              </select>
              <span>entries</span>
            </div>

            <div className="flex items-center gap-2 text-sm text-slate-700">
              <label htmlFor="demand-wise-value-search">Search:</label>
              <input
                id="demand-wise-value-search"
                type="text"
                value={searchTerm}
                onChange={(event) => setSearchTerm(event.target.value)}
                onKeyDown={async (event) => {
                  if (event.key === 'Enter') {
                    setLoading(true);
                    await loadReport(filters, event.currentTarget.value);
                    setLoading(false);
                  }
                }}
                className="rounded-md border border-slate-200 px-3 py-2 text-sm outline-none focus:border-indigo-400"
              />
            </div>
          </div>

          {error ? <div className="px-5 py-3 text-sm text-rose-600">{error}</div> : null}

          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-200 text-sm">
              <thead className="bg-white text-slate-700">
                <tr>
                  <th className="px-4 py-4 text-center font-semibold">Sr.</th>
                  <th className="px-4 py-4 text-center font-semibold">Item Name</th>
                  <th className="px-4 py-4 text-center font-semibold">DR No.</th>
                  <th className="px-4 py-4 text-center font-semibold">Batch No.</th>
                  <th className="px-4 py-4 text-center font-semibold">Issued Date</th>
                  <th className="px-4 py-4 text-center font-semibold">Issued Qty</th>
                  <th className="px-4 py-4 text-center font-semibold">Status</th>
                  <th className="px-4 py-4 text-center font-semibold">Unit Buying Price</th>
                  <th className="px-4 py-4 text-center font-semibold">Total Buying Price</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200 bg-white">
                {loading ? (
                  <tr>
                    <td colSpan="9" className="px-4 py-8 text-center text-slate-500">Loading...</td>
                  </tr>
                ) : pageItems.length === 0 ? (
                  <tr>
                    <td colSpan="9" className="px-4 py-8 text-center text-slate-500">No data available in table</td>
                  </tr>
                ) : (
                  pageItems.map((record) => (
                    <tr key={`${record.drNo}-${record.sr}`}>
                      <td className="px-4 py-3 text-center">{record.sr}</td>
                      <td className="px-4 py-3 text-center">{record.itemName}</td>
                      <td className="px-4 py-3 text-center">{record.drNo}</td>
                      <td className="px-4 py-3 text-center">{record.batchNo || '-'}</td>
                      <td className="px-4 py-3 text-center">{formatDateTime(record.issuedDate)}</td>
                      <td className="px-4 py-3 text-center">{record.issuedQty}</td>
                      <td className="px-4 py-3 text-center">{record.status}</td>
                      <td className="px-4 py-3 text-right">{formatCurrency(record.unitBuyingPrice)}</td>
                      <td className="px-4 py-3 text-right">{formatCurrency(record.totalBuyingPrice)}</td>
                    </tr>
                  ))
                )}
              </tbody>
              <tfoot className="bg-white font-semibold text-slate-800">
                <tr>
                  <td className="px-4 py-4 text-center">Sr.</td>
                  <td className="px-4 py-4 text-center">Item Name</td>
                  <td className="px-4 py-4 text-center">DR No.</td>
                  <td className="px-4 py-4 text-center">Batch No.</td>
                  <td className="px-4 py-4 text-center">Issued Date</td>
                  <td className="px-4 py-4 text-center">Total Issued Qty: {totals.totalIssuedQty}</td>
                  <td className="px-4 py-4 text-center">Status</td>
                  <td className="px-4 py-4 text-right">Total Unit Buying Price: {formatCurrency(totals.totalUnitBuyingPrice)}</td>
                  <td className="px-4 py-4 text-right">Total Buying Price: {formatCurrency(totals.totalBuyingPrice)}</td>
                </tr>
              </tfoot>
            </table>
          </div>

          <div className="flex items-center justify-between px-5 py-4 text-sm text-slate-600">
            <div>Showing {showingFrom} to {showingTo} of {records.length} entries</div>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => setCurrentPage((page) => Math.max(1, page - 1))}
                disabled={currentPage === 1}
                className="rounded border border-slate-200 px-3 py-1 disabled:cursor-not-allowed disabled:opacity-50"
              >
                ‹
              </button>
              <button
                type="button"
                onClick={() => setCurrentPage((page) => Math.min(totalPages, page + 1))}
                disabled={currentPage === totalPages}
                className="rounded border border-slate-200 px-3 py-1 disabled:cursor-not-allowed disabled:opacity-50"
              >
                ›
              </button>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
};

export default DemandWiseValuePage;