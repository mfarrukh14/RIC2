import React, { useEffect, useState } from 'react';
import { InformationCircleIcon } from '@heroicons/react/24/outline';
import pharmacyApi from '../services/pharmacyApi';
import BranchField from '../components/BranchField';

function formatDateTime(value) {
  if (!value) return '-';
  return new Date(value).toLocaleString('en-US', {
    month: 'short', day: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false
  });
}

const PharmacyQueuePage = () => {
  const [stores, setStores] = useState([]);
  const [storeId, setStoreId] = useState('');
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    pharmacyApi.getLookups()
      .then((data) => {
        setStores(data.stores || []);
        if ((data.stores || []).length === 1) {
          setStoreId(String(data.stores[0].id));
        }
      })
      .catch((lookupError) => console.error('Error loading stores:', lookupError));
  }, []);

  useEffect(() => {
    if (!storeId) {
      setEntries([]);
      return;
    }

    setLoading(true);
    setError('');
    pharmacyApi.getQueue(storeId)
      .then(setEntries)
      .catch((loadError) => {
        console.error('Error loading pharmacy queue:', loadError);
        setError('Failed to load the queue.');
      })
      .finally(() => setLoading(false));
  }, [storeId]);

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-6 py-3">
            <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
              Pharmacy Queue
              <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
            </h1>
          </div>

          {error && <div className="px-6 pt-4 text-sm text-rose-600">{error}</div>}

          <div className="grid grid-cols-1 gap-4 px-6 py-5 lg:grid-cols-2">
            <BranchField />
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Store</label>
              <select value={storeId} onChange={(event) => setStoreId(event.target.value)} className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400">
                <option value="">Select Store</option>
                {stores.map((store) => <option key={store.id} value={store.id}>{store.name}</option>)}
              </select>
            </div>
          </div>

          <div className="overflow-x-auto border-t border-slate-100 px-6 py-4">
            <table className="min-w-full border-separate border-spacing-0 text-sm">
              <thead>
                <tr className="text-left text-slate-700">
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Token</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Name</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">MR Number</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Visit Number</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Prescribed By</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Date Time</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Prescribed In</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan="7" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">Loading...</td></tr>
                ) : !storeId ? (
                  <tr><td colSpan="7" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">Select a store to view its queue.</td></tr>
                ) : entries.length === 0 ? (
                  <tr><td colSpan="7" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">No data available in table</td></tr>
                ) : (
                  entries.map((entry) => (
                    <tr key={entry.patientPharmacyId} className="text-slate-700">
                      <td className="border-b border-slate-200 px-4 py-3">{entry.patientPharmacyId}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.patientName || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.mrNo || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.visitNo || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.prescribedByName || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{formatDateTime(entry.timestamp)}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{entry.prescribedInName || '-'}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
          <div className="px-6 pb-4 text-sm text-slate-500">Showing 1 to {entries.length} of {entries.length} entries</div>
        </section>
      </div>
    </div>
  );
};

export default PharmacyQueuePage;
