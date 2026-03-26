import React, { useEffect, useMemo, useState } from 'react';
import { MagnifyingGlassIcon } from '@heroicons/react/24/outline';
import estimatedPurchaseOrderApi from '../services/estimatedPurchaseOrderApi';
import vendorApi from '../services/vendorApi';
import { manufacturerApi } from '../services/manufacturerApi';
import { getAllStores } from '../services/storeApi';

function toDateInputValue(date) {
  const adjusted = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
  return adjusted.toISOString().slice(0, 10);
}

function defaultFilters() {
  const today = new Date();
  const from = new Date(today);
  from.setDate(today.getDate() - 30);

  return {
    storeId: '',
    vendorId: '',
    manufacturerId: '',
    startDate: toDateInputValue(from),
    endDate: toDateInputValue(today),
    deliveryLeadTimeDays: '7',
    safetyStock: '20'
  };
}

function formatNumber(value, maximumFractionDigits = 2) {
  if (value === null || value === undefined || Number.isNaN(Number(value))) {
    return '0';
  }

  return Number(value).toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits
  });
}

function formatDate(value) {
  if (!value) {
    return '-';
  }

  return new Date(value).toLocaleDateString('en-US', {
    month: 'short',
    day: '2-digit',
    year: 'numeric'
  });
}

function categoryClasses(category) {
  switch (category) {
    case 'Fast Running Items':
      return 'bg-emerald-100 text-emerald-700 border border-emerald-200';
    case 'Dead Items':
      return 'bg-rose-100 text-rose-700 border border-rose-200';
    default:
      return 'bg-amber-100 text-amber-700 border border-amber-200';
  }
}

const legendItems = [
  { label: 'Fast Running Items', className: 'bg-emerald-500' },
  { label: 'Slow Moving Items', className: 'bg-amber-500' },
  { label: 'Dead Items', className: 'bg-rose-500' }
];

const EstimatedPurchaseOrderPage = () => {
  const [filters, setFilters] = useState(defaultFilters());
  const [lookups, setLookups] = useState({
    stores: [],
    vendors: [],
    manufacturers: []
  });
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const loadInitialData = async () => {
      setLoading(true);
      try {
        const [storesResult, vendorsResult, manufacturersResult] = await Promise.allSettled([
          getAllStores(),
          vendorApi.getAll(),
          manufacturerApi.getAll()
        ]);

        const stores = storesResult.status === 'fulfilled' ? storesResult.value : [];
        const vendors = vendorsResult.status === 'fulfilled' ? vendorsResult.value : [];
        const manufacturers = manufacturersResult.status === 'fulfilled' ? manufacturersResult.value : [];

        if (storesResult.status === 'rejected' || vendorsResult.status === 'rejected') {
          throw new Error('Required lookup data could not be loaded.');
        }

        setLookups({ stores, vendors, manufacturers });
        await fetchRows(defaultFilters());

        if (manufacturersResult.status === 'rejected') {
          setError('Manufacturer lookup is temporarily unavailable. Estimated purchase orders are still loaded without that filter.');
        }
      } catch (loadError) {
        console.error('Error loading estimated purchase order lookups:', loadError);
        setError('Failed to load estimated purchase order data.');
      } finally {
        setLoading(false);
      }
    };

    loadInitialData();
  }, []);

  const fetchRows = async (activeFilters = filters) => {
    try {
      setError('');
      const data = await estimatedPurchaseOrderApi.getAll({
        storeId: activeFilters.storeId || undefined,
        vendorId: activeFilters.vendorId || undefined,
        manufacturerId: activeFilters.manufacturerId || undefined,
        startDate: activeFilters.startDate ? `${activeFilters.startDate}T00:00:00.000Z` : undefined,
        endDate: activeFilters.endDate ? `${activeFilters.endDate}T23:59:59.999Z` : undefined,
        deliveryLeadTimeDays: Number(activeFilters.deliveryLeadTimeDays || 7),
        safetyStock: Number(activeFilters.safetyStock || 0)
      });
      setRows(data);
    } catch (requestError) {
      console.error('Error loading estimated purchase orders:', requestError);
      setRows([]);
      setError('Failed to load estimated purchase order recommendations.');
    }
  };

  const handleFilterChange = (event) => {
    const { name, value } = event.target;
    setFilters((current) => ({
      ...current,
      [name]: value
    }));
  };

  const handleSearch = async () => {
    setLoading(true);
    await fetchRows(filters);
    setLoading(false);
  };

  const summary = useMemo(() => {
    return rows.reduce(
      (accumulator, row) => {
        accumulator.totalRows += 1;
        accumulator.totalSuggestedQuantity += Number(row.recommendedOrderQuantity || 0);
        accumulator.totalCurrentStock += Number(row.currentStock || 0);

        if (row.runningCategory === 'Fast Running Items') {
          accumulator.fast += 1;
        } else if (row.runningCategory === 'Dead Items') {
          accumulator.dead += 1;
        } else {
          accumulator.slow += 1;
        }

        return accumulator;
      },
      {
        totalRows: 0,
        totalSuggestedQuantity: 0,
        totalCurrentStock: 0,
        fast: 0,
        slow: 0,
        dead: 0
      }
    );
  }, [rows]);

  return (
    <div className="p-6 space-y-6">
      <div className="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">Estimated Purchase Order</h1>
          <p className="text-sm text-slate-500">Estimate procurement quantities from current stock, recent consumption, vendor, and manufacturer history.</p>
        </div>
      </div>

      <div className="rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div className="grid gap-4 p-5 md:grid-cols-2 xl:grid-cols-4">
          <div>
            <label className="mb-2 block text-sm font-medium text-slate-700">Store</label>
            <select
              name="storeId"
              value={filters.storeId}
              onChange={handleFilterChange}
              className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm text-slate-700 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
            >
              <option value="">All Stores</option>
              {lookups.stores.map((store) => (
                <option key={store.storeId} value={store.storeId}>{store.storeName}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="mb-2 block text-sm font-medium text-slate-700">Vendor</label>
            <select
              name="vendorId"
              value={filters.vendorId}
              onChange={handleFilterChange}
              className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm text-slate-700 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
            >
              <option value="">All Vendors</option>
              {lookups.vendors.map((vendor) => (
                <option key={vendor.id} value={vendor.id}>{vendor.name}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="mb-2 block text-sm font-medium text-slate-700">Date Range From</label>
            <input
              type="date"
              name="startDate"
              value={filters.startDate}
              onChange={handleFilterChange}
              className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm text-slate-700 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
            />
          </div>

          <div>
            <label className="mb-2 block text-sm font-medium text-slate-700">Date Range To</label>
            <input
              type="date"
              name="endDate"
              value={filters.endDate}
              onChange={handleFilterChange}
              className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm text-slate-700 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
            />
          </div>

          <div>
            <label className="mb-2 block text-sm font-medium text-slate-700">Manufacturer</label>
            <select
              name="manufacturerId"
              value={filters.manufacturerId}
              onChange={handleFilterChange}
              className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm text-slate-700 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
            >
              <option value="">All Manufacturers</option>
              {lookups.manufacturers.map((manufacturer) => (
                <option key={manufacturer.id} value={manufacturer.id}>{manufacturer.name}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="mb-2 block text-sm font-medium text-slate-700">Delivery Lead Time (Days)</label>
            <input
              type="number"
              min="1"
              name="deliveryLeadTimeDays"
              value={filters.deliveryLeadTimeDays}
              onChange={handleFilterChange}
              className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm text-slate-700 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
            />
          </div>

          <div>
            <label className="mb-2 block text-sm font-medium text-slate-700">Safety Stock</label>
            <input
              type="number"
              min="0"
              name="safetyStock"
              value={filters.safetyStock}
              onChange={handleFilterChange}
              className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm text-slate-700 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
            />
          </div>

          <div className="flex items-end">
            <button
              type="button"
              onClick={handleSearch}
              className="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-blue-600 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blue-700"
            >
              <MagnifyingGlassIcon className="h-4 w-4" />
              Search
            </button>
          </div>
        </div>

        <div className="border-t border-slate-200 px-5 py-4">
          <div className="flex flex-wrap items-center gap-4 text-sm text-slate-600">
            {legendItems.map((item) => (
              <div key={item.label} className="flex items-center gap-2">
                <span className={`h-3 w-3 rounded-full ${item.className}`} />
                <span>{item.label}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {error ? (
        <div className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
          {error}
        </div>
      ) : null}

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <div className="rounded-2xl bg-slate-900 px-5 py-4 text-white shadow-sm">
          <div className="text-sm text-slate-300">Recommended Items</div>
          <div className="mt-2 text-3xl font-semibold">{formatNumber(summary.totalRows, 0)}</div>
        </div>
        <div className="rounded-2xl bg-white px-5 py-4 shadow-sm ring-1 ring-slate-200">
          <div className="text-sm text-slate-500">Suggested Quantity</div>
          <div className="mt-2 text-3xl font-semibold text-slate-800">{formatNumber(summary.totalSuggestedQuantity, 0)}</div>
        </div>
        <div className="rounded-2xl bg-white px-5 py-4 shadow-sm ring-1 ring-slate-200">
          <div className="text-sm text-slate-500">Fast Running</div>
          <div className="mt-2 text-3xl font-semibold text-emerald-600">{formatNumber(summary.fast, 0)}</div>
        </div>
        <div className="rounded-2xl bg-white px-5 py-4 shadow-sm ring-1 ring-slate-200">
          <div className="text-sm text-slate-500">Current Stock In View</div>
          <div className="mt-2 text-3xl font-semibold text-slate-800">{formatNumber(summary.totalCurrentStock, 0)}</div>
        </div>
      </div>

      <div className="overflow-hidden rounded-2xl bg-white shadow-sm ring-1 ring-slate-200">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200 text-sm">
            <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
              <tr>
                <th className="px-4 py-3 text-left">Item</th>
                <th className="px-4 py-3 text-left">Store</th>
                <th className="px-4 py-3 text-left">Vendor</th>
                <th className="px-4 py-3 text-left">Manufacturer</th>
                <th className="px-4 py-3 text-right">Consumed</th>
                <th className="px-4 py-3 text-right">Current Stock</th>
                <th className="px-4 py-3 text-right">Avg / Day</th>
                <th className="px-4 py-3 text-right">Lead Days</th>
                <th className="px-4 py-3 text-right">Safety</th>
                <th className="px-4 py-3 text-right">Est. Qty</th>
                <th className="px-4 py-3 text-left">Item Movement</th>
                <th className="px-4 py-3 text-left">Last Receipt</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 bg-white">
              {loading ? (
                <tr>
                  <td colSpan="12" className="px-4 py-10 text-center text-slate-500">Loading estimated purchase orders...</td>
                </tr>
              ) : rows.length === 0 ? (
                <tr>
                  <td colSpan="12" className="px-4 py-10 text-center text-slate-500">No estimated purchase orders found for the selected filters.</td>
                </tr>
              ) : (
                rows.map((row) => (
                  <tr key={`${row.storeId}-${row.itemId}`} className="hover:bg-slate-50">
                    <td className="px-4 py-3">
                      <div className="font-medium text-slate-800">{row.itemName}</div>
                      <div className="text-xs text-slate-500">{row.itemTypeName || 'Unassigned item type'}</div>
                    </td>
                    <td className="px-4 py-3 text-slate-600">{row.storeName}</td>
                    <td className="px-4 py-3 text-slate-600">{row.vendorName || '-'}</td>
                    <td className="px-4 py-3 text-slate-600">{row.manufacturerName || '-'}</td>
                    <td className="px-4 py-3 text-right text-slate-600">{formatNumber(row.consumedQuantity, 0)}</td>
                    <td className="px-4 py-3 text-right text-slate-600">{formatNumber(row.currentStock, 0)}</td>
                    <td className="px-4 py-3 text-right text-slate-600">{formatNumber(row.averageDailyConsumption)}</td>
                    <td className="px-4 py-3 text-right text-slate-600">{formatNumber(row.deliveryLeadTimeDays, 0)}</td>
                    <td className="px-4 py-3 text-right text-slate-600">{formatNumber(row.safetyStock, 0)}</td>
                    <td className="px-4 py-3 text-right font-semibold text-slate-800">{formatNumber(row.recommendedOrderQuantity, 0)}</td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-medium ${categoryClasses(row.runningCategory)}`}>
                        {row.runningCategory}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-slate-600">{formatDate(row.lastReceiptDate)}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default EstimatedPurchaseOrderPage;