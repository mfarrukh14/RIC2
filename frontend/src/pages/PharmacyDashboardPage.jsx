import React, { useEffect, useState } from 'react';
import { AcademicCapIcon } from '@heroicons/react/24/outline';
import pharmacyApi from '../services/pharmacyApi';

function formatCurrency(value) {
  if (value === null || value === undefined || value === '') return '0.00';
  return Number(value).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function formatDate(value) {
  if (!value) return '-';
  return new Date(value).toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' });
}

const StatList = ({ title, items, valueLabel = 'Quantity', renderExtra }) => (
  <div className="rounded-md border border-slate-200 bg-white shadow-sm">
    <div className="border-b border-slate-100 px-4 py-3 text-sm font-semibold text-indigo-600">{title}</div>
    <div className="max-h-80 overflow-y-auto">
      {items.length === 0 ? (
        <div className="px-4 py-6 text-center text-sm text-slate-500">No data available</div>
      ) : (
        <table className="min-w-full text-sm">
          <tbody>
            {items.map((item, index) => (
              <tr key={`${item.name}-${index}`} className="odd:bg-slate-50/60">
                <td className="px-4 py-2 text-slate-700">{item.name}</td>
                {renderExtra && <td className="px-4 py-2 text-slate-500">{renderExtra(item)}</td>}
                <td className="px-4 py-2 text-right text-slate-900">{formatCurrency(item.quantity)} {valueLabel === 'Quantity' ? '' : valueLabel}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  </div>
);

const PharmacyDashboardPage = () => {
  const [stores, setStores] = useState([]);
  const [storeId, setStoreId] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    pharmacyApi.getLookups()
      .then((data) => setStores(data.stores || []))
      .catch((lookupError) => console.error('Error loading stores:', lookupError));
    loadDashboard();
  }, []);

  const loadDashboard = async (overrides = {}) => {
    setLoading(true);
    setError('');
    try {
      const data = await pharmacyApi.getDashboard({
        storeId: overrides.storeId ?? storeId ?? undefined,
        dateFrom: overrides.dateFrom ?? dateFrom ?? undefined,
        dateTo: overrides.dateTo ?? dateTo ?? undefined
      });
      setSummary(data);
    } catch (loadError) {
      console.error('Error loading pharmacy dashboard:', loadError);
      setError('Failed to load the dashboard.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-6 py-3">
            <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
              <AcademicCapIcon className="h-6 w-6 text-indigo-500" />
              Pharmacy Dashboard
            </h1>
          </div>

          {error && <div className="px-6 pt-4 text-sm text-rose-600">{error}</div>}

          <div className="grid grid-cols-1 gap-4 px-6 py-5 lg:grid-cols-4">
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Store Name</label>
              <select value={storeId} onChange={(event) => setStoreId(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-indigo-400">
                <option value="">All Stores</option>
                {stores.map((store) => <option key={store.id} value={store.id}>{store.name}</option>)}
              </select>
            </div>
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Date From</label>
              <input type="date" value={dateFrom} onChange={(event) => setDateFrom(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-indigo-400" />
            </div>
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Date To</label>
              <input type="date" value={dateTo} onChange={(event) => setDateTo(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-indigo-400" />
            </div>
            <div className="flex items-end">
              <button type="button" onClick={() => loadDashboard()} className="w-full rounded-md bg-indigo-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-indigo-700">Apply</button>
            </div>
          </div>
        </section>

        {loading ? (
          <div className="rounded-md border border-slate-200 bg-white p-10 text-center text-sm text-slate-500 shadow-sm">Loading dashboard...</div>
        ) : summary && (
          <>
            <section className="rounded-md border border-slate-200 bg-white p-6 shadow-sm">
              <div className="text-sm font-medium text-slate-600">Daily Prescriptions Dispensed</div>
              <div className="mt-2 text-3xl font-semibold text-indigo-600">{summary.dailyPrescriptionsDispensed}</div>
            </section>

            <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
              <StatList title="Top Dispensed Items" items={summary.topDispensedItems} />
              <StatList title="Top Items In Stock" items={summary.topItemsInStock} />
            </div>

            <StatList
              title="Expiring in 90 Days"
              items={summary.expiringSoon}
              renderExtra={(item) => formatDate(item.expiryDate)}
            />
          </>
        )}
      </div>
    </div>
  );
};

export default PharmacyDashboardPage;
