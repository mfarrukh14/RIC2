import React, { useEffect, useState } from 'react';
import { InformationCircleIcon } from '@heroicons/react/24/outline';
import pharmacyApi from '../services/pharmacyApi';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';

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

  const {
    items: pageItems,
    totalCount,
    raw,
    currentPage,
    pageSize: entriesPerPage,
    setPageSize: setEntriesPerPage,
    goToPage,
    search: runSearch,
    loading,
    error,
  } = usePagedList(pharmacyApi.getDailySale, {}, { autoLoad: false, initialPageSize: 10 });

  useEffect(() => {
    pharmacyApi.getLookups()
      .then((data) => setStores(data.stores || []))
      .catch((lookupError) => console.error('Error loading stores:', lookupError));
    runSearch({ storeId: undefined, dateFrom: undefined, dateTo: undefined, challanType: undefined });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleSearch = () => {
    runSearch({
      storeId: storeId || undefined,
      dateFrom: dateFrom || undefined,
      dateTo: dateTo || undefined,
      challanType: challanType || undefined
    });
  };

  // Grand totals across the whole filtered result set (not just this page) -
  // computed server-side alongside the paged rows, see PharmacyDailySaleReport.
  const totals = {
    discount: raw?.totalDiscount ?? 0,
    total: raw?.totalSaleAmount ?? 0,
    paid: raw?.totalPaid ?? 0,
    remaining: raw?.totalRemaining ?? 0
  };

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

          {error && <div className="px-6 pt-4 text-sm text-rose-600">Failed to load daily sale{error.message ? `: ${error.message}` : ''}</div>}

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
              <button type="button" onClick={handleSearch} className="w-full rounded-md bg-indigo-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-indigo-700">Search</button>
            </div>
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
              {totalCount > 0 && (
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

          <Pagination
            currentPage={currentPage}
            pageSize={entriesPerPage}
            totalCount={totalCount}
            onPageChange={goToPage}
            onPageSizeChange={setEntriesPerPage}
          />
        </section>
      </div>
    </div>
  );
};

export default PharmacyDailySalePage;
