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

const PharmacyOnlineOrderPage = () => {
  const [stores, setStores] = useState([]);
  const [storeId, setStoreId] = useState('');
  const [status, setStatus] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [submittedFilters, setSubmittedFilters] = useState(null);

  const {
    items: entries,
    totalCount,
    currentPage,
    pageSize: entriesPerPage,
    setPageSize: setEntriesPerPage,
    goToPage,
    search: runSearch,
    loading,
    error,
  } = usePagedList(pharmacyApi.getOnlineOrders, submittedFilters || {}, { autoLoad: false, initialPageSize: 10 });

  useEffect(() => {
    pharmacyApi.getLookups()
      .then((data) => setStores(data.stores || []))
      .catch((lookupError) => console.error('Error loading stores:', lookupError));

    const searchFilters = { storeId: undefined, status: undefined, dateFrom: undefined, dateTo: undefined };
    setSubmittedFilters(searchFilters);
    runSearch(searchFilters);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleSearch = () => {
    const searchFilters = {
      storeId: storeId || undefined,
      status: status || undefined,
      dateFrom: dateFrom || undefined,
      dateTo: dateTo || undefined
    };
    setSubmittedFilters(searchFilters);
    runSearch(searchFilters);
  };

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-6 py-3">
            <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
              Pharmacy Online Order
              <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
            </h1>
          </div>

          {error && <div className="px-6 pt-4 text-sm text-rose-600">Failed to load online orders{error.message ? `: ${error.message}` : ''}</div>}

          <div className="grid grid-cols-1 gap-4 px-6 py-5 lg:grid-cols-5">
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Date From</label>
              <input type="date" value={dateFrom} onChange={(event) => setDateFrom(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-indigo-400" />
            </div>
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Date To</label>
              <input type="date" value={dateTo} onChange={(event) => setDateTo(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-indigo-400" />
            </div>
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Store</label>
              <select value={storeId} onChange={(event) => setStoreId(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-indigo-400">
                <option value="">All</option>
                {stores.map((store) => <option key={store.id} value={store.id}>{store.name}</option>)}
              </select>
            </div>
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Status</label>
              <input type="text" value={status} onChange={(event) => setStatus(event.target.value)} placeholder="Select Status" className="w-full rounded-md border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-indigo-400" />
            </div>
            <div className="flex items-end">
              <button type="button" onClick={handleSearch} disabled={loading} className="w-full rounded-md bg-indigo-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50">Search</button>
            </div>
          </div>

          <div className="overflow-x-auto px-6 pb-4">
            <table className="min-w-full border-separate border-spacing-0 text-sm">
              <thead>
                <tr className="text-left text-slate-700">
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Order #</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Name</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">CNIC</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">MR No.</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Action By</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Store</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Date Time</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Status</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan="8" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">Loading...</td></tr>
                ) : entries.length === 0 ? (
                  <tr><td colSpan="8" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">No data available in table</td></tr>
                ) : (
                  entries.map((entry) => (
                    <tr key={entry.patientPharmacyId} className="text-slate-700">
                      <td className="border-b border-slate-200 px-4 py-3">{entry.orderNumber || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.patientName || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.cnic || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.mrNo || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.actionByName || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.storeName || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{formatDateTime(entry.timestamp)}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.status || '-'}</td>
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
        </section>
      </div>
    </div>
  );
};

export default PharmacyOnlineOrderPage;
