import React, { useEffect, useMemo, useState } from 'react';
import {
  InformationCircleIcon,
  PlusIcon,
  TrashIcon,
  XMarkIcon
} from '@heroicons/react/24/outline';
import pharmacyApi from '../services/pharmacyApi';
import BranchField from '../components/BranchField';
import { useSession } from '../context/SessionContext';

function formatCurrency(value) {
  if (value === null || value === undefined || value === '') {
    return '0.00';
  }

  return Number(value).toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
}

// Simple debounce for the patient search box - only fires the API call a beat after
// the user stops typing.
function useDebouncedValue(value, delayMs) {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const handle = setTimeout(() => setDebounced(value), delayMs);
    return () => clearTimeout(handle);
  }, [value, delayMs]);

  return debounced;
}

const RetailPharmacyPage = () => {
  const { session } = useSession();
  const branchId = session?.branchId;

  const [lookups, setLookups] = useState({ stores: [], paymentTypes: [], prescribedIns: [] });
  const [storeId, setStoreId] = useState('');
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');

  const [patientQuery, setPatientQuery] = useState('');
  const [patientResults, setPatientResults] = useState([]);
  const [selectedPatient, setSelectedPatient] = useState(null);
  const [visitNo, setVisitNo] = useState('');

  const [doctors, setDoctors] = useState([]);
  const [selectedDoctorId, setSelectedDoctorId] = useState('');

  const [prescribedInId, setPrescribedInId] = useState('');

  const [activeItems, setActiveItems] = useState([]);
  const [selectedItemId, setSelectedItemId] = useState('');
  const [itemQuantity, setItemQuantity] = useState(1);

  const [pendingPrescriptions, setPendingPrescriptions] = useState([]);

  // Items added locally but not yet saved to the server-side basket (Provisional
  // challan). "Add to Basket" persists these and deducts stock; until then they're
  // just a client-side draft, matching the legacy screen's own cart-then-commit flow.
  const [cartItems, setCartItems] = useState([]);

  // The server-side Provisional challan, once at least one "Add to Basket" has
  // succeeded. Its .items are the authoritative, already-stock-deducted lines.
  const [challan, setChallan] = useState(null);
  const [savingBasket, setSavingBasket] = useState(false);

  const [discountMode, setDiscountMode] = useState('none'); // none | amount | percentage
  const [discountValue, setDiscountValue] = useState('');
  const [paidAmount, setPaidAmount] = useState('');
  const [paymentTypeId, setPaymentTypeId] = useState('');
  const [finalizing, setFinalizing] = useState(false);
  const [completedChallan, setCompletedChallan] = useState(null);

  const debouncedPatientQuery = useDebouncedValue(patientQuery, 300);

  useEffect(() => {
    loadLookups();
    pharmacyApi.getActiveDoctors()
      .then(setDoctors)
      .catch((doctorError) => console.error('Error loading doctors:', doctorError));
  }, []);

  const loadLookups = async () => {
    try {
      const data = await pharmacyApi.getLookups();
      setLookups(data);
      if (data.stores?.length === 1) {
        setStoreId(String(data.stores[0].id));
      }
    } catch (lookupError) {
      console.error('Error loading pharmacy lookups:', lookupError);
      setError('Failed to load stores/payment types.');
    }
  };

  useEffect(() => {
    if (!debouncedPatientQuery || debouncedPatientQuery.trim().length < 2 || selectedPatient) {
      setPatientResults([]);
      return;
    }

    let cancelled = false;
    pharmacyApi.searchPatients(debouncedPatientQuery.trim())
      .then((results) => { if (!cancelled) setPatientResults(results); })
      .catch((searchError) => console.error('Error searching patients:', searchError));
    return () => { cancelled = true; };
  }, [debouncedPatientQuery, selectedPatient]);

  useEffect(() => {
    if (!storeId || !branchId) {
      setActiveItems([]);
      return;
    }

    let cancelled = false;
    pharmacyApi.getActiveItems(branchId, storeId)
      .then((results) => { if (!cancelled) setActiveItems(results); })
      .catch((itemsError) => console.error('Error loading active items:', itemsError));
    return () => { cancelled = true; };
  }, [storeId, branchId]);

  useEffect(() => {
    if (!selectedPatient || !storeId) {
      setPendingPrescriptions([]);
      return;
    }

    pharmacyApi.getPendingPrescriptions(selectedPatient.patientId, storeId)
      .then(setPendingPrescriptions)
      .catch((prescriptionError) => console.error('Error loading pending prescriptions:', prescriptionError));
  }, [selectedPatient, storeId]);

  const resetSale = () => {
    setSelectedPatient(null);
    setPatientQuery('');
    setPatientResults([]);
    setVisitNo('');
    setSelectedDoctorId('');
    setPrescribedInId('');
    setSelectedItemId('');
    setItemQuantity(1);
    setPendingPrescriptions([]);
    setCartItems([]);
    setChallan(null);
    setDiscountMode('none');
    setDiscountValue('');
    setPaidAmount('');
    setPaymentTypeId('');
  };

  const addDraftItem = (draft) => {
    setCartItems((current) => [...current, draft]);
  };

  const handleAddSelectedItem = () => {
    const selectedItem = activeItems.find((item) => String(item.itemId) === String(selectedItemId));

    if (!selectedItem || !itemQuantity || itemQuantity <= 0) {
      setError('Select an item and a valid quantity first.');
      return;
    }

    setError('');
    addDraftItem({
      key: `adhoc-${selectedItem.itemId}-${Date.now()}`,
      itemId: selectedItem.itemId,
      medicineName: selectedItem.itemName,
      unitPrice: selectedItem.unitPrice,
      prescribedQuantity: null,
      quantity: itemQuantity
    });

    setSelectedItemId('');
    setItemQuantity(1);
  };

  const handleAddPrescriptionItem = (prescription) => {
    if (!prescription.branchMedicineId) {
      setError(`'${prescription.medicineName}' is not available for sale in this store.`);
      return;
    }

    setError('');
    addDraftItem({
      key: `rx-${prescription.patientPharmacyDetailId}`,
      branchMedicineId: prescription.branchMedicineId,
      medicineName: prescription.medicineName,
      unitPrice: 0,
      prescribedQuantity: prescription.prescribedQuantity,
      quantity: prescription.prescribedQuantity,
      patientPharmacyDetailId: prescription.patientPharmacyDetailId,
      patientsMedicineId: prescription.patientsMedicineId
    });
  };

  const updateDraftQuantity = (key, quantity) => {
    setCartItems((current) => current.map((item) => (item.key === key ? { ...item, quantity } : item)));
  };

  const removeDraftItem = (key) => {
    setCartItems((current) => current.filter((item) => item.key !== key));
  };

  const draftSubtotal = useMemo(
    () => cartItems.reduce((sum, item) => sum + (Number(item.quantity) || 0) * (Number(item.unitPrice) || 0), 0),
    [cartItems]
  );

  const basketSubtotal = challan?.amount ?? 0;
  const subtotal = challan ? basketSubtotal : draftSubtotal;

  const discountAmount = useMemo(() => {
    if (discountMode === 'none' || !discountValue) {
      return 0;
    }

    const value = Number(discountValue) || 0;
    return discountMode === 'percentage' ? Math.min(subtotal, (subtotal * value) / 100) : Math.min(subtotal, value);
  }, [discountMode, discountValue, subtotal]);

  const total = Math.max(0, subtotal - discountAmount);
  const paid = Number(paidAmount) || 0;
  const change = paid > total ? paid - total : 0;

  const handleSaveBasket = async () => {
    if (cartItems.length === 0) {
      setError('Add at least one item before saving the basket.');
      return;
    }

    if (!storeId) {
      setError('Select a store first.');
      return;
    }

    setSavingBasket(true);
    setError('');
    setInfo('');

    try {
      const result = await pharmacyApi.addToProvisional({
        patientId: selectedPatient?.patientId ?? null,
        visitNo: visitNo || null,
        storeId: Number(storeId),
        prescribedInId: prescribedInId || null,
        prescribedById: selectedDoctorId || null,
        items: cartItems.map((item) => ({
          itemId: item.itemId ?? null,
          branchMedicineId: item.branchMedicineId ?? null,
          patientPharmacyDetailId: item.patientPharmacyDetailId ?? null,
          patientsMedicineId: item.patientsMedicineId ?? null,
          quantity: Number(item.quantity),
          unitPrice: Number(item.unitPrice)
        }))
      });

      setChallan(result);
      setCartItems([]);
      setInfo('Items saved to the basket and stock deducted.');
    } catch (saveError) {
      console.error('Error saving pharmacy basket:', saveError);
      setError(saveError.response?.data?.message || 'Failed to save the basket.');
    } finally {
      setSavingBasket(false);
    }
  };

  const handleGenerateChallan = async () => {
    if (!challan) {
      setError('Add items to the basket first.');
      return;
    }

    if (cartItems.length > 0) {
      setError('You have unsaved items - click "Add to Basket" first.');
      return;
    }

    if (!paymentTypeId) {
      setError('Select a payment type.');
      return;
    }

    setFinalizing(true);
    setError('');

    try {
      const discountType = discountMode === 'amount' ? 1 : discountMode === 'percentage' ? 2 : null;
      const result = await pharmacyApi.finalizeDispense(challan.id, {
        discountType,
        discountAmount: discountType ? Number(discountValue) || 0 : 0,
        paidAmount: paid,
        paymentTypeId: Number(paymentTypeId)
      });

      setCompletedChallan(result);
      resetSale();
      setInfo(`Challan ${result.challanNo} generated successfully.`);
    } catch (finalizeError) {
      console.error('Error generating challan:', finalizeError);
      setError(finalizeError.response?.data?.message || 'Failed to generate the challan.');
    } finally {
      setFinalizing(false);
    }
  };

  const combinedItems = [
    ...(challan?.items || []).map((item) => ({ ...item, committed: true })),
    ...cartItems.map((item) => ({ ...item, committed: false, total: (Number(item.quantity) || 0) * (Number(item.unitPrice) || 0) }))
  ];

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-6 py-3">
            <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
              Retail Pharmacy
              <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
            </h1>
          </div>

          {error && <div className="px-6 pt-4 text-sm text-rose-600">{error}</div>}
          {info && <div className="px-6 pt-4 text-sm text-emerald-600">{info}</div>}

          <div className="grid grid-cols-1 gap-x-6 gap-y-5 px-6 py-5 lg:grid-cols-3">
            <BranchField />

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Store</label>
              <select
                value={storeId}
                onChange={(event) => { setStoreId(event.target.value); setChallan(null); setCartItems([]); }}
                className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              >
                <option value="">Select Store</option>
                {lookups.stores.map((store) => (
                  <option key={store.id} value={store.id}>{store.name}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Prescribed In</label>
              <select
                value={prescribedInId}
                onChange={(event) => setPrescribedInId(event.target.value)}
                className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              >
                <option value="">Select</option>
                {lookups.prescribedIns.map((option) => (
                  <option key={option.id} value={option.id}>{option.name}</option>
                ))}
              </select>
            </div>

            <div className="relative">
              <label className="mb-2 block text-sm font-medium text-slate-700">Search Patient</label>
              {selectedPatient ? (
                <div className="flex items-center justify-between rounded-md border border-slate-200 bg-slate-50 px-4 py-3 text-sm">
                  <span>{selectedPatient.mrNo} - {selectedPatient.name}</span>
                  <button type="button" onClick={() => setSelectedPatient(null)} className="text-slate-400 hover:text-slate-600">
                    <XMarkIcon className="h-4 w-4" />
                  </button>
                </div>
              ) : (
                <input
                  type="text"
                  value={patientQuery}
                  onChange={(event) => setPatientQuery(event.target.value)}
                  placeholder="MR No. or Name"
                  className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                />
              )}
              {patientResults.length > 0 && (
                <ul className="absolute z-10 mt-1 max-h-60 w-full overflow-y-auto rounded-md border border-slate-200 bg-white shadow-lg">
                  {patientResults.map((patient) => (
                    <li
                      key={patient.patientId}
                      onClick={() => { setSelectedPatient(patient); setPatientResults([]); }}
                      className="cursor-pointer px-4 py-2 text-sm hover:bg-indigo-50"
                    >
                      {patient.mrNo} - {patient.name} {patient.maskedContact ? `(${patient.maskedContact})` : ''}
                    </li>
                  ))}
                </ul>
              )}
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Visit No</label>
              <input
                type="text"
                value={visitNo}
                onChange={(event) => setVisitNo(event.target.value)}
                className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              />
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Prescribed By</label>
              <select
                value={selectedDoctorId}
                onChange={(event) => setSelectedDoctorId(event.target.value)}
                className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              >
                <option value="">Select Doctor</option>
                {doctors.map((doctor) => (
                  <option key={doctor.doctorId} value={doctor.doctorId}>{doctor.name}</option>
                ))}
              </select>
            </div>
          </div>

          {selectedPatient && pendingPrescriptions.length > 0 && (
            <div className="border-t border-slate-100 px-6 py-4">
              <div className="mb-2 text-sm font-semibold text-slate-800">Pending Prescriptions</div>
              <div className="space-y-2">
                {pendingPrescriptions.map((prescription) => {
                  const alreadyAdded = cartItems.some((item) => item.patientPharmacyDetailId === prescription.patientPharmacyDetailId)
                    || (challan?.items || []).some((item) => item.branchMedicineId === prescription.branchMedicineId);
                  return (
                    <div key={prescription.patientPharmacyDetailId} className="flex items-center justify-between rounded-md border border-slate-200 px-4 py-2 text-sm">
                      <div>
                        <span className="font-medium text-slate-800">{prescription.medicineName}</span>
                        <span className="ml-2 text-slate-500">Qty: {prescription.prescribedQuantity} · Stock: {prescription.currentStock}</span>
                      </div>
                      <button
                        type="button"
                        onClick={() => handleAddPrescriptionItem(prescription)}
                        disabled={alreadyAdded}
                        className="rounded-md bg-indigo-600 px-3 py-1.5 text-xs font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-50"
                      >
                        {alreadyAdded ? 'Added' : 'Add'}
                      </button>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          <div className="border-t border-slate-100 px-6 py-4">
            <div className="grid grid-cols-1 gap-4 lg:grid-cols-[1fr_140px_auto]">
              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Item</label>
                <select
                  value={selectedItemId}
                  onChange={(event) => setSelectedItemId(event.target.value)}
                  disabled={!storeId}
                  className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400 disabled:bg-slate-100"
                >
                  <option value="">{storeId ? 'Select Item' : 'Select a store first'}</option>
                  {activeItems.map((item) => (
                    <option key={item.itemId} value={item.itemId}>
                      {item.itemName} - Stock {formatCurrency(item.storeStockQty)} - Rs. {formatCurrency(item.unitPrice)}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Quantity</label>
                <input
                  type="number"
                  min={1}
                  value={itemQuantity}
                  onChange={(event) => setItemQuantity(Number(event.target.value))}
                  className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                />
              </div>

              <div className="flex items-end">
                <button
                  type="button"
                  onClick={handleAddSelectedItem}
                  className="inline-flex items-center gap-2 rounded-md bg-indigo-600 px-4 py-3 text-sm font-medium text-white transition hover:bg-indigo-700"
                >
                  <PlusIcon className="h-4 w-4" /> Add
                </button>
              </div>
            </div>
          </div>

          <div className="overflow-x-auto border-t border-slate-100 px-6 py-4">
            <table className="min-w-full border-separate border-spacing-0 text-sm">
              <thead>
                <tr className="text-left text-slate-700">
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Medicine</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Rate</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Prescribed Qty</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Dispense Qty</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Total</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Status</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Action</th>
                </tr>
              </thead>
              <tbody>
                {combinedItems.length === 0 ? (
                  <tr>
                    <td colSpan="7" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">
                      No items yet - search and add a medicine above.
                    </td>
                  </tr>
                ) : (
                  combinedItems.map((item) => (
                    <tr key={item.key || `committed-${item.id}`} className="text-slate-700">
                      <td className="border-b border-slate-200 px-4 py-3">{item.medicineName}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{formatCurrency(item.unitPrice)}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{item.prescribedQuantity ?? '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">
                        {item.committed ? item.quantity : (
                          <input
                            type="number"
                            min={1}
                            value={item.quantity}
                            onChange={(event) => updateDraftQuantity(item.key, Number(event.target.value))}
                            className="w-20 rounded-md border border-slate-200 px-2 py-1 text-sm outline-none focus:border-indigo-400"
                          />
                        )}
                      </td>
                      <td className="border-b border-slate-200 px-4 py-3">{formatCurrency(item.total)}</td>
                      <td className="border-b border-slate-200 px-4 py-3">
                        {item.committed ? <span className="text-emerald-700">In Basket</span> : <span className="text-amber-700">Pending Save</span>}
                      </td>
                      <td className="border-b border-slate-200 px-4 py-3">
                        {!item.committed && (
                          <button type="button" onClick={() => removeDraftItem(item.key)} className="text-rose-500 hover:text-rose-700">
                            <TrashIcon className="h-4 w-4" />
                          </button>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          <div className="flex justify-end border-t border-slate-100 px-6 py-3">
            <button
              type="button"
              onClick={handleSaveBasket}
              disabled={savingBasket || cartItems.length === 0}
              className="rounded-md border border-indigo-600 px-5 py-2.5 text-sm font-medium text-indigo-600 transition hover:bg-indigo-50 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {savingBasket ? 'Saving...' : 'Add to Basket'}
            </button>
          </div>

          <div className="border-t border-slate-100 px-6 py-5">
            <div className="ml-auto max-w-md space-y-3">
              <div className="flex items-center justify-between text-sm">
                <span className="text-slate-600">Sub Total</span>
                <span className="font-medium text-slate-900">Rs. {formatCurrency(subtotal)}</span>
              </div>

              <div className="flex items-center gap-3 text-sm">
                <span className="text-slate-600">Discount</span>
                <label className="flex items-center gap-1">
                  <input type="radio" checked={discountMode === 'none'} onChange={() => { setDiscountMode('none'); setDiscountValue(''); }} /> None
                </label>
                <label className="flex items-center gap-1">
                  <input type="radio" checked={discountMode === 'amount'} onChange={() => setDiscountMode('amount')} /> Amount
                </label>
                <label className="flex items-center gap-1">
                  <input type="radio" checked={discountMode === 'percentage'} onChange={() => setDiscountMode('percentage')} /> Percentage
                </label>
              </div>

              {discountMode !== 'none' && (
                <input
                  type="number"
                  min={0}
                  value={discountValue}
                  onChange={(event) => setDiscountValue(event.target.value)}
                  placeholder={discountMode === 'percentage' ? 'Discount %' : 'Discount Amount'}
                  className="w-full rounded-md border border-slate-200 px-4 py-2 text-sm outline-none focus:border-indigo-400"
                />
              )}

              <div className="flex items-center justify-between text-sm">
                <span className="text-slate-600">Total</span>
                <span className="font-semibold text-slate-900">Rs. {formatCurrency(total)}</span>
              </div>

              <div className="flex items-center gap-3">
                <input
                  type="number"
                  min={0}
                  value={paidAmount}
                  onChange={(event) => setPaidAmount(event.target.value)}
                  placeholder="Paid Amount"
                  className="w-1/2 rounded-md border border-slate-200 px-4 py-2 text-sm outline-none focus:border-indigo-400"
                />
                <select
                  value={paymentTypeId}
                  onChange={(event) => setPaymentTypeId(event.target.value)}
                  className="w-1/2 rounded-md border border-slate-200 px-4 py-2 text-sm outline-none focus:border-indigo-400"
                >
                  <option value="">Payment Type</option>
                  {lookups.paymentTypes.map((type) => (
                    <option key={type.id} value={type.id}>{type.name}</option>
                  ))}
                </select>
              </div>

              <div className="flex items-center justify-between text-sm">
                <span className="text-slate-600">Change</span>
                <span className="font-medium text-slate-900">Rs. {formatCurrency(change)}</span>
              </div>

              <div className="flex justify-end pt-2">
                <button
                  type="button"
                  onClick={handleGenerateChallan}
                  disabled={finalizing || !challan || cartItems.length > 0 || !paymentTypeId}
                  className="rounded-md bg-indigo-600 px-6 py-3 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {finalizing ? 'Generating...' : 'Generate Challan'}
                </button>
              </div>
            </div>
          </div>
        </section>

        {completedChallan && (
          <section className="rounded-md border border-emerald-200 bg-emerald-50 p-6">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-emerald-800">Challan {completedChallan.challanNo}</h2>
              <button type="button" onClick={() => setCompletedChallan(null)} className="text-emerald-600 hover:text-emerald-800">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>
            <table className="min-w-full text-sm">
              <thead>
                <tr className="text-left text-emerald-900">
                  <th className="px-3 py-2">Medicine</th>
                  <th className="px-3 py-2">Quantity</th>
                  <th className="px-3 py-2">Total</th>
                </tr>
              </thead>
              <tbody>
                {completedChallan.items.map((item) => (
                  <tr key={item.id}>
                    <td className="px-3 py-1.5">{item.medicineName}</td>
                    <td className="px-3 py-1.5">{item.quantity}</td>
                    <td className="px-3 py-1.5">Rs. {formatCurrency(item.total)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            <div className="mt-3 grid grid-cols-2 gap-2 text-sm text-emerald-900 sm:grid-cols-4">
              <div>Amount: Rs. {formatCurrency(completedChallan.amount)}</div>
              <div>Discount: Rs. {formatCurrency(completedChallan.discount)}</div>
              <div>Total: Rs. {formatCurrency(completedChallan.total)}</div>
              <div>Paid: Rs. {formatCurrency(completedChallan.paidAmount)}</div>
            </div>
          </section>
        )}
      </div>
    </div>
  );
};

export default RetailPharmacyPage;
