import React, { useEffect, useMemo, useState } from 'react';
import { InformationCircleIcon } from '@heroicons/react/24/outline';
import pharmacyApi from '../services/pharmacyApi';

function formatDateTime(value) {
  if (!value) return '-';
  return new Date(value).toLocaleString('en-US', {
    month: 'short', day: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false
  });
}

function formatCurrency(value) {
  if (value === null || value === undefined || value === '') return '0.00';
  return Number(value).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

const PharmacyDailySalePage = () => {
  const [stores, setStores] = useState([]);
  const [storeId, setStoreId] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [challanType, setChallanType] = useState('');
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [entriesPerPage, setEntriesPerPage] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);

  useEffect(() => {
    pharmacyApi.getLookups()
      .then((data) => setStores(data.stores || []))
      .catch((lookupError) => console.error('Error loading stores:', lookupError));
    loadEntries();
  }, []);

  const loadEntries = async (overrides = {}) => {
    setLoading(true);
    setError('');
    try {
      const params = {
        storeId: overrides.storeId ?? storeId ?? undefined,
        dateFrom: overrides.dateFrom ?? dateFrom ?? undefined,
        dateTo: overrides.dateTo ?? dateTo ?? undefined,
        challanType: overrides.challanType ?? challanType ?? undefined
      };
      const data = await pharmacyApi.getDailySale(params);
      setEntries(data);
    } catch (loadError) {
      console.error('Error loading daily sale:', loadError);
      setError('Failed to load daily sale.');
    } finally {
      setLoading(false);
    }
  };

  const filteredEntries = useMemo(() => {
    if (!searchTerm.trim()) return entries;
    const normalized = searchTerm.trim().toLowerCase();
    return entries.filter((entry) => [entry.mrNo, entry.patientName, entry.visitNo, entry.challanNo, entry.challanType]
      .some((value) => (value || '').toLowerCase().includes(normalized)));
  }, [entries, searchTerm]);

  useEffect(() => { setCurrentPage(1); }, [entriesPerPage, searchTerm]);

  const totalPages = Math.max(1, Math.ceil(filteredEntries.length / entriesPerPage));
  const startIndex = (currentPage - 1) * entriesPerPage;
  const pageItems = filteredEntries.slice(startIndex, startIndex + entriesPerPage);
  const showingFrom = filteredEntries.length === 0 ? 0 : startIndex + 1;
  const showingTo = Math.min(startIndex + entriesPerPage, filteredEntries.length);

  const totals = useMemo(() => filteredEntries.reduce((acc, entry) => ({
    discount: acc.discount + (Number(entry.discount) || 0),
    total: acc.total + (Number(entry.total) || 0),
    paid: acc.paid + (Number(entry.paidAmount) || 0),
    remaining: acc.remaining + (Number(entry.remaining) || 0)
  }), { discount: 0, total: 0, paid: 0, remaining: 0 }), [filteredEntries]);

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-6 py-3">
            <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
              Daily Sale
              <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
            </h1>
          </div>

          {error && <div className="px-6 pt-4 text-sm text-rose-600">{error}</div>}

          <div className="grid grid-cols-1 gap-4 px-6 py-5 lg:grid-cols-5">
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Store</label>
              <select value={storeId} onChange={(event) => setStoreId(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-indigo-400">
                <option value="">All</option>
                {stores.map((store) => <option key={store.id} value={store.id}>{store.name}</option>)}
              </select>
            </div>
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Challan Type</label>
              <select value={challanType} onChange={(event) => setChallanType(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-indigo-400">
                <option value="">All</option>
                <option value="Final">Final</option>
                <option value="Refund">Refund</option>
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
              <button type="button" onClick={() => loadEntries()} className="w-full rounded-md bg-indigo-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-indigo-700">Search</button>
            </div>
          </div>

          <div className="flex flex-col gap-3 border-t border-slate-100 px-6 py-4 md:flex-row md:items-center md:justify-between">
            <div className="flex items-center gap-2 text-sm text-slate-600">
              <span>Show</span>
              <select value={entriesPerPage} onChange={(event) => setEntriesPerPage(Number(event.target.value))} className="rounded-md border border-slate-200 px-2 py-1 text-sm">
                {[10, 25, 50].map((size) => <option key={size} value={size}>{size}</option>)}
              </select>
              <span>entries</span>
            </div>
            <label className="flex items-center gap-2 text-sm text-slate-600">
              <span>Search:</span>
              <input type="text" value={searchTerm} onChange={(event) => setSearchTerm(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none focus:border-indigo-400 md:w-60" />
            </label>
          </div>

          <div className="overflow-x-auto px-6 pb-4">
            <table className="min-w-full border-separate border-spacing-0 text-sm">
              <thead>
                <tr className="text-left text-slate-700">
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">MR No.</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Name</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Visit/Ref No.</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Challan No.</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Type</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Time</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Discount</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Total</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Paid</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Due</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan="10" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">Loading...</td></tr>
                ) : pageItems.length === 0 ? (
                  <tr><td colSpan="10" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">No data available in table</td></tr>
                ) : (
                  pageItems.map((entry) => (
                    <tr key={entry.id} className="text-slate-700">
                      <td className="border-b border-slate-200 px-4 py-3">{entry.mrNo || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.patientName || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.visitNo || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.challanNo}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.challanType}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{formatDateTime(entry.timestamp)}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{formatCurrency(entry.discount)}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{formatCurrency(entry.total)}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{formatCurrency(entry.paidAmount)}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{formatCurrency(entry.remaining)}</td>
                    </tr>
                  ))
                )}
              </tbody>
              {filteredEntries.length > 0 && (
                <tfoot>
                  <tr className="text-left font-semibold text-slate-800">
                    <td colSpan="6" className="border-t border-slate-200 px-4 py-3">Totals</td>
                    <td className="border-t border-slate-200 px-4 py-3">{formatCurrency(totals.discount)}</td>
                    <td className="border-t border-slate-200 px-4 py-3">{formatCurrency(totals.total)}</td>
                    <td className="border-t border-slate-200 px-4 py-3">{formatCurrency(totals.paid)}</td>
                    <td className="border-t border-slate-200 px-4 py-3">{formatCurrency(totals.remaining)}</td>
                  </tr>
                </tfoot>
              )}
            </table>
          </div>

          <div className="flex flex-col gap-3 px-6 py-4 text-sm text-slate-600 md:flex-row md:items-center md:justify-between">
            <div>Showing {showingFrom} to {showingTo} of {filteredEntries.length} entries</div>
            <div className="flex items-center gap-2">
              <button type="button" onClick={() => setCurrentPage((page) => Math.max(page - 1, 1))} disabled={currentPage === 1} className="rounded-md border border-slate-200 px-3 py-2 disabled:cursor-not-allowed disabled:opacity-50">‹</button>
              <span className="rounded-md bg-indigo-600 px-3 py-2 text-white">{currentPage}</span>
              <button type="button" onClick={() => setCurrentPage((page) => Math.min(page + 1, totalPages))} disabled={currentPage === totalPages} className="rounded-md border border-slate-200 px-3 py-2 disabled:cursor-not-allowed disabled:opacity-50">›</button>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
};

export default PharmacyDailySalePage;
