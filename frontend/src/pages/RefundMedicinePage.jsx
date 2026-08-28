import React, { useEffect, useState } from 'react';
import { InformationCircleIcon } from '@heroicons/react/24/outline';
import pharmacyApi from '../services/pharmacyApi';

function formatCurrency(value) {
  if (value === null || value === undefined || value === '') return '0.00';
  return Number(value).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

const RefundMedicinePage = () => {
  const [stores, setStores] = useState([]);
  const [storeId, setStoreId] = useState('');
  const [challanNo, setChallanNo] = useState('');
  const [lines, setLines] = useState([]);
  const [refundQuantities, setRefundQuantities] = useState({});
  const [searching, setSearching] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');

  useEffect(() => {
    pharmacyApi.getLookups()
      .then((data) => setStores(data.stores || []))
      .catch((lookupError) => console.error('Error loading stores:', lookupError));
  }, []);

  const handleSearch = async () => {
    if (!storeId || !challanNo.trim()) {
      setError('Select a store and enter a Challan No.');
      return;
    }

    setSearching(true);
    setError('');
    setInfo('');
    setLines([]);
    setRefundQuantities({});

    try {
      const results = await pharmacyApi.getRefundableLines(storeId, challanNo.trim());
      setLines(results);
      setRefundQuantities(Object.fromEntries(results.map((line) => [line.challanFormDetailId, 0])));
      if (results.length === 0) {
        setInfo('No refundable items found for this challan.');
      }
    } catch (searchError) {
      console.error('Error searching refundable lines:', searchError);
      setError('Failed to search for this challan.');
    } finally {
      setSearching(false);
    }
  };

  const updateRefundQuantity = (id, value, max) => {
    const clamped = Math.max(0, Math.min(Number(value) || 0, max));
    setRefundQuantities((current) => ({ ...current, [id]: clamped }));
  };

  const handleSubmitRefund = async () => {
    const items = Object.entries(refundQuantities)
      .filter(([, quantity]) => quantity > 0)
      .map(([challanFormDetailId, refundQuantity]) => ({ challanFormDetailId: Number(challanFormDetailId), refundQuantity }));

    if (items.length === 0) {
      setError('Enter a refund quantity for at least one item.');
      return;
    }

    setSubmitting(true);
    setError('');
    setInfo('');

    try {
      const result = await pharmacyApi.processRefund({ storeId: Number(storeId), challanNo: challanNo.trim(), items });
      setInfo(`Refund challan ${result.challanNo} generated successfully.`);
      setLines([]);
      setRefundQuantities({});
      setChallanNo('');
    } catch (refundError) {
      console.error('Error processing refund:', refundError);
      setError(refundError.response?.data?.message || 'Failed to process the refund.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-6 py-3">
            <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
              Refund Medicine
              <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
            </h1>
          </div>

          {error && <div className="px-6 pt-4 text-sm text-rose-600">{error}</div>}
          {info && <div className="px-6 pt-4 text-sm text-emerald-600">{info}</div>}

          <div className="grid grid-cols-1 gap-4 px-6 py-5 lg:grid-cols-[1fr_1fr_auto]">
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Store*</label>
              <select
                value={storeId}
                onChange={(event) => setStoreId(event.target.value)}
                className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              >
                <option value="">Select</option>
                {stores.map((store) => (
                  <option key={store.id} value={store.id}>{store.name}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Challan No*</label>
              <input
                type="text"
                value={challanNo}
                onChange={(event) => setChallanNo(event.target.value)}
                placeholder="Enter Challan No"
                className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              />
            </div>

            <div className="flex items-end">
              <button
                type="button"
                onClick={handleSearch}
                disabled={searching}
                className="rounded-md bg-indigo-600 px-6 py-3 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-50"
              >
                {searching ? 'Searching...' : 'Search'}
              </button>
            </div>
          </div>

          <div className="overflow-x-auto border-t border-slate-100 px-6 py-4">
            <table className="min-w-full border-separate border-spacing-0 text-sm">
              <thead>
                <tr className="text-left text-slate-700">
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Medicine Name</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Rate</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Issued Quantity</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Already Refunded</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Refund Quantity</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Total</th>
                </tr>
              </thead>
              <tbody>
                {lines.length === 0 ? (
                  <tr><td colSpan="6" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">No data available in table</td></tr>
                ) : (
                  lines.map((line) => (
                    <tr key={line.challanFormDetailId} className="text-slate-700">
                      <td className="border-b border-slate-200 px-4 py-3">{line.medicineName}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{formatCurrency(line.rate)}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{line.issuedQuantity}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{line.alreadyRefundedQuantity}</td>
                      <td className="border-b border-slate-200 px-4 py-3">
                        <input
                          type="number"
                          min={0}
                          max={line.refundableQuantity}
                          value={refundQuantities[line.challanFormDetailId] ?? 0}
                          onChange={(event) => updateRefundQuantity(line.challanFormDetailId, event.target.value, line.refundableQuantity)}
                          disabled={line.refundableQuantity <= 0}
                          className="w-24 rounded-md border border-slate-200 px-2 py-1 text-sm outline-none focus:border-indigo-400 disabled:bg-slate-100"
                        />
                      </td>
                      <td className="border-b border-slate-200 px-4 py-3">
                        {formatCurrency((refundQuantities[line.challanFormDetailId] || 0) * line.rate)}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {lines.length > 0 && (
            <div className="flex justify-end border-t border-slate-100 px-6 py-4">
              <button
                type="button"
                onClick={handleSubmitRefund}
                disabled={submitting}
                className="rounded-md bg-rose-600 px-6 py-3 text-sm font-medium text-white transition hover:bg-rose-700 disabled:cursor-not-allowed disabled:opacity-50"
              >
                {submitting ? 'Processing...' : 'Process Refund'}
              </button>
            </div>
          )}
        </section>
      </div>
    </div>
  );
};

export default RefundMedicinePage;
