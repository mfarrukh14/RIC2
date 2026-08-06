import React, { useEffect, useMemo, useState } from 'react';
import {
  ClipboardDocumentListIcon,
  EyeIcon,
  PlusIcon,
  PrinterIcon,
  Squares2X2Icon,
  XMarkIcon
} from '@heroicons/react/24/outline';
import purchaseRequisitionApi from '../services/purchaseRequisitionApi';
import departmentApi from '../services/departmentApi';
import { vendorApi } from '../services/api';
import itemApi from '../services/itemApi';
import { itemTypeApi } from '../services/itemTypeApi';
import { productOptionValue, parseProductOptionValue, findProductRow } from '../utils/productKey';
import { storeAllocationToUserApi } from '../services/storeAllocationToUserApi';
import { getAllStores } from '../services/storeApi';
import BranchField from '../components/BranchField';
import { useSession } from '../context/SessionContext';

function formatDateTime(value) {
  if (!value) return '-';
  return new Date(value).toLocaleString('en-US', { month: 'short', day: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false });
}

function formatDate(value) {
  if (!value) return '-';
  return new Date(value).toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' });
}

function formatMoney(value) {
  return Number(value || 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

const emptyItemForm = { itemTypeId: '', itemId: '', quantity: 1, unitEstimatedCost: 0, budgetHeadId: '', availableBudget: '', budgetRestriction: '', remarks: '' };

const emptyHeaderForm = {
  demandRequestId: null,
  demandNo: '',
  storeId: '',
  departmentId: '',
  financialYearId: '',
  distributionPlan: '',
  priority: 1,
  dateRequiredBy: '',
  prType: 1,
  vendorId: '',
  suggestedProcurementMethod: '',
  subject: '',
  scopeOfWork: '',
  instructions: '',
  remarks: '',
  goodsDeliveredContactPerson: '',
  goodsDeliveredCellNumber: '',
  goodsDeliveredEmail: '',
  goodsDeliveredTelephone: '',
  goodsDeliveredFaxNo: '',
  goodsDeliveryAddress: '',
  termsAndConditions: '',
  forwardToUserId: ''
};

const PR_TYPES = [
  { id: 1, name: 'Tender' },
  { id: 2, name: 'Quotation' },
  { id: 3, name: 'Direct Purchase' }
];

const PurchaseRequisitionsPage = ({ prefill, onPrefillConsumed }) => {
  const { session } = useSession();

  const [activeTab, setActiveTab] = useState('Pending');
  const [list, setList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  const [showForm, setShowForm] = useState(false);
  const [header, setHeader] = useState(emptyHeaderForm);
  const [items, setItems] = useState([]);
  const [itemForm, setItemForm] = useState(emptyItemForm);
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState(null);

  const [lookups, setLookups] = useState({ departments: [], financialYears: [], budgetHeads: [], vendors: [], items: [], itemTypes: [], stores: [], forwardUsers: [] });

  const [selectedPR, setSelectedPR] = useState(null);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [detailLoading, setDetailLoading] = useState(false);

  const [lifeCycleEntries, setLifeCycleEntries] = useState([]);
  const [showLifeCycleModal, setShowLifeCycleModal] = useState(false);
  const [lifeCycleLoading, setLifeCycleLoading] = useState(false);
  const [lifeCyclePRNumber, setLifeCyclePRNumber] = useState('');

  useEffect(() => {
    loadLookups();
  }, []);

  useEffect(() => {
    loadList();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab]);

  // Launched from Approved Demands' "Generate Purchase Requisition" button - opens the
  // form pre-filled with the demand's items instead of the old simplified PO-creation modal.
  useEffect(() => {
    if (prefill) {
      setHeader((current) => ({
        ...current,
        demandRequestId: prefill.demandRequestId,
        demandNo: prefill.demandNo || '',
        storeId: prefill.storeId || '',
        subject: prefill.subject || ''
      }));
      setItems(prefill.items || []);
      setShowForm(true);
      if (onPrefillConsumed) onPrefillConsumed();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [prefill]);

  const loadLookups = async () => {
    try {
      const [departments, financialYears, budgetHeads, vendors, allItems, itemTypes, stores, forwardUsers] = await Promise.all([
        departmentApi.getDropdown(),
        purchaseRequisitionApi.getFinancialYears(),
        purchaseRequisitionApi.getBudgetHeads(),
        vendorApi.getAll(),
        itemApi.getAllWithMedicines(),
        itemTypeApi.getAll(),
        getAllStores(),
        storeAllocationToUserApi.getEmployeeDropdown()
      ]);
      setLookups({ departments, financialYears, budgetHeads, vendors, items: (allItems || []).filter((row) => row.isActive), itemTypes, stores, forwardUsers });
    } catch (lookupError) {
      console.error('Error loading purchase requisition lookups:', lookupError);
    }
  };

  const loadList = async () => {
    setLoading(true);
    setError('');
    try {
      const data = await purchaseRequisitionApi.getAll({ statusCategory: activeTab, branchId: session?.branchId });
      setList(data);
    } catch (listError) {
      console.error('Error loading purchase requisitions:', listError);
      setError('Failed to load purchase requisitions.');
    } finally {
      setLoading(false);
    }
  };

  const filteredList = useMemo(() => {
    const term = searchTerm.trim().toLowerCase();
    if (!term) return list;
    return list.filter((pr) => [pr.prNumber, pr.departmentName, pr.vendorName, pr.statusName]
      .some((value) => (value || '').toLowerCase().includes(term)));
  }, [list, searchTerm]);

  // itemApi.getAllWithMedicines() doesn't return itemTypeId, so the Item Type
  // dropdown can no longer narrow this list - it shows everything regardless of selection.
  const filteredItemsForType = useMemo(() => lookups.items, [lookups.items]);

  const resetForm = () => {
    setHeader(emptyHeaderForm);
    setItems([]);
    setItemForm(emptyItemForm);
    setFormError(null);
    setShowForm(false);
  };

  const addItem = () => {
    if (!itemForm.itemId || Number(itemForm.quantity) <= 0) {
      setFormError('Select an item and a quantity greater than 0 before adding.');
      return;
    }
    const selected = parseProductOptionValue(itemForm.itemId);
    const item = findProductRow(lookups.items, selected);
    setItems((current) => [...current, {
      itemId: selected.itemId,
      medicineId: selected.medicineId,
      subServiceId: selected.subServiceId,
      itemName: item?.name || 'Item',
      quantity: Number(itemForm.quantity),
      unitEstimatedCost: Number(itemForm.unitEstimatedCost) || 0,
      budgetHeadId: itemForm.budgetHeadId ? Number(itemForm.budgetHeadId) : null,
      budgetHeadName: lookups.budgetHeads.find((b) => String(b.id) === String(itemForm.budgetHeadId))?.name,
      availableBudget: itemForm.availableBudget ? Number(itemForm.availableBudget) : null,
      budgetRestriction: itemForm.budgetRestriction || null,
      remarks: itemForm.remarks || null
    }]);
    setItemForm(emptyItemForm);
    setFormError(null);
  };

  const removeItem = (index) => {
    setItems((current) => current.filter((_, i) => i !== index));
  };

  const submitForm = async (event) => {
    event.preventDefault();
    if (items.length === 0) {
      setFormError('Add at least one item.');
      return;
    }

    setSubmitting(true);
    setFormError(null);
    try {
      await purchaseRequisitionApi.create({
        demandRequestId: header.demandRequestId,
        demandNo: header.demandNo || null,
        branchId: session?.branchId,
        storeId: header.storeId ? Number(header.storeId) : null,
        departmentId: header.departmentId ? Number(header.departmentId) : null,
        financialYearId: header.financialYearId ? Number(header.financialYearId) : null,
        distributionPlan: header.distributionPlan || null,
        priority: Number(header.priority),
        dateRequiredBy: header.dateRequiredBy || null,
        prType: Number(header.prType),
        vendorId: header.vendorId ? Number(header.vendorId) : null,
        suggestedProcurementMethod: header.suggestedProcurementMethod || null,
        subject: header.subject || null,
        scopeOfWork: header.scopeOfWork || null,
        instructions: header.instructions || null,
        remarks: header.remarks || null,
        goodsDeliveredContactPerson: header.goodsDeliveredContactPerson || null,
        goodsDeliveredCellNumber: header.goodsDeliveredCellNumber || null,
        goodsDeliveredEmail: header.goodsDeliveredEmail || null,
        goodsDeliveredTelephone: header.goodsDeliveredTelephone || null,
        goodsDeliveredFaxNo: header.goodsDeliveredFaxNo || null,
        goodsDeliveryAddress: header.goodsDeliveryAddress || null,
        termsAndConditions: header.termsAndConditions || null,
        forwardToUserId: header.forwardToUserId ? Number(header.forwardToUserId) : null,
        items: items.map((item) => ({
          itemId: item.itemId || null,
          medicineId: item.medicineId || null,
          subServiceId: item.subServiceId || null,
          quantity: item.quantity,
          unitEstimatedCost: item.unitEstimatedCost,
          budgetHeadId: item.budgetHeadId,
          availableBudget: item.availableBudget,
          budgetRestriction: item.budgetRestriction,
          remarks: item.remarks
        }))
      });
      resetForm();
      setActiveTab('Pending');
      loadList();
    } catch (submitError) {
      console.error('Error creating purchase requisition:', submitError);
      setFormError(submitError.response?.data?.message || 'Failed to create the purchase requisition.');
    } finally {
      setSubmitting(false);
    }
  };

  const openDetail = async (pr) => {
    setShowDetailModal(true);
    setDetailLoading(true);
    try {
      const details = await purchaseRequisitionApi.getById(pr.id);
      setSelectedPR(details);
    } catch (detailError) {
      console.error('Error loading purchase requisition details:', detailError);
      setSelectedPR(null);
    } finally {
      setDetailLoading(false);
    }
  };

  const openLifeCycle = async (pr) => {
    setShowLifeCycleModal(true);
    setLifeCycleLoading(true);
    setLifeCyclePRNumber(pr.prNumber);
    try {
      const entries = await purchaseRequisitionApi.getLifeCycle(pr.id);
      setLifeCycleEntries(entries);
    } catch (lifeCycleError) {
      console.error('Error loading purchase requisition life cycle:', lifeCycleError);
      setLifeCycleEntries([]);
    } finally {
      setLifeCycleLoading(false);
    }
  };

  const tabs = ['Pending', 'Processed', 'Closed'];

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="flex items-center justify-between border-b border-slate-100 px-6 py-3">
            <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
              <ClipboardDocumentListIcon className="h-6 w-6 text-indigo-500" />
              Purchase Requisition
            </h1>
            {!showForm && (
              <button
                type="button"
                onClick={() => setShowForm(true)}
                className="inline-flex items-center gap-2 rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
              >
                <PlusIcon className="h-4 w-4" />
                Add Purchase Requisition
              </button>
            )}
          </div>

          {showForm && (
            <form onSubmit={submitForm} className="space-y-6 px-6 py-5">
              {formError && (
                <div className="rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-700">{formError}</div>
              )}

              <div className="grid grid-cols-1 gap-x-4 gap-y-5 md:grid-cols-3">
                <BranchField />
                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Demand No.</label>
                  <input type="text" value={header.demandNo} readOnly disabled className="w-full cursor-not-allowed rounded-lg border border-slate-200 bg-slate-100 px-4 py-3 text-sm text-slate-600" />
                </div>
                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Financial Year</label>
                  <select value={header.financialYearId} onChange={(e) => setHeader({ ...header, financialYearId: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400">
                    <option value="">Select</option>
                    {lookups.financialYears.map((fy) => <option key={fy.id} value={fy.id}>{fy.name}</option>)}
                  </select>
                </div>

                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Distribution Plan</label>
                  <input type="text" value={header.distributionPlan} onChange={(e) => setHeader({ ...header, distributionPlan: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
                </div>
                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Priority</label>
                  <select value={header.priority} onChange={(e) => setHeader({ ...header, priority: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400">
                    <option value={1}>Routine</option>
                    <option value={2}>Urgent</option>
                  </select>
                </div>
                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Required Date</label>
                  <input type="date" value={header.dateRequiredBy} onChange={(e) => setHeader({ ...header, dateRequiredBy: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
                </div>

                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Department</label>
                  <select value={header.departmentId} onChange={(e) => setHeader({ ...header, departmentId: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400">
                    <option value="">Select</option>
                    {lookups.departments.map((d) => <option key={d.value} value={d.value}>{d.text}</option>)}
                  </select>
                </div>
                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">PR Type</label>
                  <select value={header.prType} onChange={(e) => setHeader({ ...header, prType: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400">
                    {PR_TYPES.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
                  </select>
                </div>
                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Vendor</label>
                  <select value={header.vendorId} onChange={(e) => setHeader({ ...header, vendorId: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400">
                    <option value="">Select</option>
                    {lookups.vendors.map((v) => <option key={v.id} value={v.id}>{v.name}</option>)}
                  </select>
                </div>

                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Store</label>
                  <select value={header.storeId} onChange={(e) => setHeader({ ...header, storeId: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400">
                    <option value="">Select</option>
                    {lookups.stores.map((s) => <option key={s.storeId} value={s.storeId}>{s.storeName}</option>)}
                  </select>
                </div>
                <div className="md:col-span-2">
                  <label className="mb-2 block text-sm font-medium text-slate-700">Suggested Procurement Method</label>
                  <input type="text" value={header.suggestedProcurementMethod} onChange={(e) => setHeader({ ...header, suggestedProcurementMethod: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
                </div>

                <div className="md:col-span-3">
                  <label className="mb-2 block text-sm font-medium text-slate-700">Subject</label>
                  <input type="text" value={header.subject} onChange={(e) => setHeader({ ...header, subject: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
                </div>

                <div className="md:col-span-3">
                  <label className="mb-2 block text-sm font-medium text-slate-700">Scope Of Work</label>
                  <textarea rows={3} value={header.scopeOfWork} onChange={(e) => setHeader({ ...header, scopeOfWork: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
                </div>
              </div>

              <div className="rounded-lg border border-slate-200">
                <div className="border-b border-slate-200 px-4 py-3 text-sm font-semibold text-slate-800">Items</div>
                <div className="grid grid-cols-1 gap-3 px-4 py-4 md:grid-cols-7">
                  <div className="md:col-span-1">
                    <label className="mb-1 block text-xs font-medium text-slate-600">Item Type</label>
                    <select value={itemForm.itemTypeId} onChange={(e) => setItemForm({ ...itemForm, itemTypeId: e.target.value, itemId: '' })} className="w-full rounded-md border border-slate-200 px-2 py-2 text-sm">
                      <option value="">All</option>
                      {lookups.itemTypes.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
                    </select>
                  </div>
                  <div className="md:col-span-2">
                    <label className="mb-1 block text-xs font-medium text-slate-600">Item</label>
                    <select value={itemForm.itemId} onChange={(e) => setItemForm({ ...itemForm, itemId: e.target.value })} className="w-full rounded-md border border-slate-200 px-2 py-2 text-sm">
                      <option value="">Select item</option>
                      {filteredItemsForType.map((i) => (
                        <option key={productOptionValue(i)} value={productOptionValue(i)}>
                          {i.sourceType === 'Item' ? i.name : `${i.name} (${i.sourceType})`}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="mb-1 block text-xs font-medium text-slate-600">Quantity</label>
                    <input type="number" min="1" value={itemForm.quantity} onChange={(e) => setItemForm({ ...itemForm, quantity: e.target.value })} className="w-full rounded-md border border-slate-200 px-2 py-2 text-sm" />
                  </div>
                  <div>
                    <label className="mb-1 block text-xs font-medium text-slate-600">Unit Est. Cost</label>
                    <input type="number" min="0" step="0.01" value={itemForm.unitEstimatedCost} onChange={(e) => setItemForm({ ...itemForm, unitEstimatedCost: e.target.value })} className="w-full rounded-md border border-slate-200 px-2 py-2 text-sm" />
                  </div>
                  <div>
                    <label className="mb-1 block text-xs font-medium text-slate-600">Budget Head</label>
                    <select value={itemForm.budgetHeadId} onChange={(e) => setItemForm({ ...itemForm, budgetHeadId: e.target.value })} className="w-full rounded-md border border-slate-200 px-2 py-2 text-sm">
                      <option value="">Select</option>
                      {lookups.budgetHeads.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
                    </select>
                  </div>
                  <div className="flex items-end">
                    <button type="button" onClick={addItem} className="w-full rounded-md bg-indigo-600 px-3 py-2 text-sm font-medium text-white hover:bg-indigo-700">Add Item</button>
                  </div>
                  <div>
                    <label className="mb-1 block text-xs font-medium text-slate-600">Available Budget</label>
                    <input type="number" min="0" step="0.01" value={itemForm.availableBudget} onChange={(e) => setItemForm({ ...itemForm, availableBudget: e.target.value })} className="w-full rounded-md border border-slate-200 px-2 py-2 text-sm" />
                  </div>
                  <div>
                    <label className="mb-1 block text-xs font-medium text-slate-600">Budget Restriction</label>
                    <input type="text" value={itemForm.budgetRestriction} onChange={(e) => setItemForm({ ...itemForm, budgetRestriction: e.target.value })} className="w-full rounded-md border border-slate-200 px-2 py-2 text-sm" />
                  </div>
                  <div className="md:col-span-3">
                    <label className="mb-1 block text-xs font-medium text-slate-600">Remarks</label>
                    <input type="text" value={itemForm.remarks} onChange={(e) => setItemForm({ ...itemForm, remarks: e.target.value })} className="w-full rounded-md border border-slate-200 px-2 py-2 text-sm" />
                  </div>
                </div>

                <div className="overflow-x-auto border-t border-slate-200">
                  <table className="min-w-full text-sm">
                    <thead className="bg-slate-50 text-left text-slate-600">
                      <tr>
                        <th className="px-4 py-2 font-semibold">Sr</th>
                        <th className="px-4 py-2 font-semibold">Item</th>
                        <th className="px-4 py-2 font-semibold">Quantity</th>
                        <th className="px-4 py-2 font-semibold">Unit Est. Cost</th>
                        <th className="px-4 py-2 font-semibold">Total Est. Cost</th>
                        <th className="px-4 py-2 font-semibold">Budget Head</th>
                        <th className="px-4 py-2 font-semibold">Available Budget</th>
                        <th className="px-4 py-2 font-semibold">Budget Restriction</th>
                        <th className="px-4 py-2 font-semibold">Remarks</th>
                        <th className="px-4 py-2 font-semibold"></th>
                      </tr>
                    </thead>
                    <tbody>
                      {items.length === 0 ? (
                        <tr><td colSpan="10" className="px-4 py-6 text-center text-slate-500">No items added yet.</td></tr>
                      ) : (
                        items.map((item, index) => (
                          <tr key={index} className="border-t border-slate-100">
                            <td className="px-4 py-2">{index + 1}</td>
                            <td className="px-4 py-2">{item.itemName}</td>
                            <td className="px-4 py-2">{item.quantity}</td>
                            <td className="px-4 py-2">{formatMoney(item.unitEstimatedCost)}</td>
                            <td className="px-4 py-2">{formatMoney(item.unitEstimatedCost * item.quantity)}</td>
                            <td className="px-4 py-2">{item.budgetHeadName || '-'}</td>
                            <td className="px-4 py-2">{item.availableBudget != null ? formatMoney(item.availableBudget) : '-'}</td>
                            <td className="px-4 py-2">{item.budgetRestriction || '-'}</td>
                            <td className="px-4 py-2">{item.remarks || '-'}</td>
                            <td className="px-4 py-2">
                              <button type="button" onClick={() => removeItem(index)} className="text-rose-600 hover:text-rose-700">
                                <XMarkIcon className="h-4 w-4" />
                              </button>
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
              </div>

              <div className="grid grid-cols-1 gap-x-4 gap-y-5 md:grid-cols-2">
                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Instructions</label>
                  <textarea rows={2} value={header.instructions} onChange={(e) => setHeader({ ...header, instructions: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
                </div>
                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Remarks</label>
                  <textarea rows={2} value={header.remarks} onChange={(e) => setHeader({ ...header, remarks: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
                </div>
              </div>

              <div className="rounded-lg border border-slate-200 p-4">
                <div className="mb-3 text-sm font-semibold text-slate-800">Goods To Be Deliver To</div>
                <div className="grid grid-cols-1 gap-x-4 gap-y-4 md:grid-cols-3">
                  <div>
                    <label className="mb-2 block text-sm font-medium text-slate-700">Contact Person</label>
                    <input type="text" value={header.goodsDeliveredContactPerson} onChange={(e) => setHeader({ ...header, goodsDeliveredContactPerson: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
                  </div>
                  <div>
                    <label className="mb-2 block text-sm font-medium text-slate-700">Cell Number</label>
                    <input type="text" value={header.goodsDeliveredCellNumber} onChange={(e) => setHeader({ ...header, goodsDeliveredCellNumber: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
                  </div>
                  <div>
                    <label className="mb-2 block text-sm font-medium text-slate-700">Email</label>
                    <input type="email" value={header.goodsDeliveredEmail} onChange={(e) => setHeader({ ...header, goodsDeliveredEmail: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
                  </div>
                  <div>
                    <label className="mb-2 block text-sm font-medium text-slate-700">Telephone</label>
                    <input type="text" value={header.goodsDeliveredTelephone} onChange={(e) => setHeader({ ...header, goodsDeliveredTelephone: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
                  </div>
                  <div>
                    <label className="mb-2 block text-sm font-medium text-slate-700">Fax No.</label>
                    <input type="text" value={header.goodsDeliveredFaxNo} onChange={(e) => setHeader({ ...header, goodsDeliveredFaxNo: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
                  </div>
                  <div>
                    <label className="mb-2 block text-sm font-medium text-slate-700">Address</label>
                    <input type="text" value={header.goodsDeliveryAddress} onChange={(e) => setHeader({ ...header, goodsDeliveryAddress: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
                  </div>
                </div>
              </div>

              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Term &amp; Conditions</label>
                <textarea rows={2} value={header.termsAndConditions} onChange={(e) => setHeader({ ...header, termsAndConditions: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
              </div>

              <div className="rounded-lg border border-slate-200 p-4">
                <div className="mb-3 text-sm font-semibold text-slate-800">Forward</div>
                <div className="grid grid-cols-1 gap-x-4 gap-y-4 md:grid-cols-2">
                  <div>
                    <label className="mb-2 block text-sm font-medium text-slate-700">Forward To</label>
                    <select value={header.forwardToUserId} onChange={(e) => setHeader({ ...header, forwardToUserId: e.target.value })} className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400">
                      <option value="">Not forwarded (stays Pending)</option>
                      {lookups.forwardUsers.map((u) => <option key={u.value} value={u.value}>{u.text}</option>)}
                    </select>
                  </div>
                </div>
              </div>

              <div className="flex justify-end gap-2 border-t border-slate-200 pt-4">
                <button type="button" onClick={resetForm} className="rounded-md border border-slate-200 px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-50">Cancel</button>
                <button type="submit" disabled={submitting} className="rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-50">
                  {submitting ? 'Submitting...' : 'Submit'}
                </button>
              </div>
            </form>
          )}
        </section>

        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="flex flex-col gap-4 border-b border-slate-100 px-4 py-3 lg:flex-row lg:items-center lg:justify-between">
            <div className="flex items-center gap-1 rounded-md border border-slate-200 p-1">
              {tabs.map((tab) => (
                <button
                  key={tab}
                  type="button"
                  onClick={() => setActiveTab(tab)}
                  className={`rounded px-4 py-1.5 text-sm font-medium transition ${activeTab === tab ? 'bg-indigo-600 text-white' : 'text-slate-600 hover:bg-slate-50'}`}
                >
                  {tab}
                </button>
              ))}
            </div>
            <label className="flex items-center gap-2 text-sm text-slate-600">
              <span>Search:</span>
              <input type="text" value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none focus:border-indigo-400 md:w-60" />
            </label>
          </div>

          {error ? (
            <div className="px-4 py-4 text-sm text-rose-600">{error}</div>
          ) : loading ? (
            <div className="px-4 py-4 text-sm text-slate-500">Loading purchase requisitions...</div>
          ) : (
            <div className="overflow-x-auto px-4 py-2">
              <table className="min-w-full border-separate border-spacing-0 text-sm">
                <thead>
                  <tr className="text-left text-slate-700">
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">PR Number</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Department</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Vendor</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Priority</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Total Est. Cost</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Date Required</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Technical Review</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Action By</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Modified On</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Status</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Action</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredList.length === 0 ? (
                    <tr><td colSpan="11" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">No data available in table</td></tr>
                  ) : (
                    filteredList.map((pr) => (
                      <tr key={pr.id} className="text-slate-700">
                        <td className="border-b border-slate-200 px-4 py-3 text-sky-700">{pr.prNumber}</td>
                        <td className="border-b border-slate-200 px-4 py-3">{pr.departmentName || '-'}</td>
                        <td className="border-b border-slate-200 px-4 py-3">{pr.vendorName || '-'}</td>
                        <td className="border-b border-slate-200 px-4 py-3">{pr.priorityName}</td>
                        <td className="border-b border-slate-200 px-4 py-3">{formatMoney(pr.totalEstimatedCost)}</td>
                        <td className="border-b border-slate-200 px-4 py-3">{formatDate(pr.dateRequiredBy)}</td>
                        <td className="border-b border-slate-200 px-4 py-3">{pr.isTechnicalReviewed ? 'Yes' : 'No'}</td>
                        <td className="border-b border-slate-200 px-4 py-3">{pr.assignedToName || '-'}</td>
                        <td className="border-b border-slate-200 px-4 py-3">{formatDateTime(pr.modifiedOn)}</td>
                        <td className="border-b border-slate-200 px-4 py-3">{pr.statusName}</td>
                        <td className="border-b border-slate-200 px-4 py-3">
                          <div className="flex items-center gap-3 text-indigo-500">
                            <button type="button" onClick={() => openDetail(pr)} title="View Detail" className="hover:text-indigo-700">
                              <EyeIcon className="h-5 w-5" />
                            </button>
                            <button type="button" onClick={() => openLifeCycle(pr)} title="Life Cycle" className="hover:text-indigo-700">
                              <Squares2X2Icon className="h-5 w-5" />
                            </button>
                            <button type="button" title="Print" className="text-emerald-600 hover:text-emerald-700" onClick={() => window.print()}>
                              <PrinterIcon className="h-5 w-5" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          )}
        </section>
      </div>

      {showDetailModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
          <div className="max-h-[90vh] w-full max-w-4xl overflow-hidden rounded-2xl bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
              <h3 className="text-lg font-semibold text-slate-900">Purchase Requisition Detail</h3>
              <button type="button" onClick={() => setShowDetailModal(false)} className="rounded-md p-2 text-slate-500 hover:bg-slate-100">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>
            <div className="max-h-[calc(90vh-72px)] overflow-y-auto px-6 py-5">
              {detailLoading ? (
                <div className="text-sm text-slate-500">Loading...</div>
              ) : !selectedPR ? (
                <div className="text-sm text-slate-500">Unable to load details.</div>
              ) : (
                <div className="space-y-5">
                  <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">PR Number</div>
                      <div className="mt-1 font-semibold text-slate-900">{selectedPR.prNumber}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Status</div>
                      <div className="mt-1 font-semibold text-slate-900">{selectedPR.statusName}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Department</div>
                      <div className="mt-1 font-semibold text-slate-900">{selectedPR.departmentName || '-'}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Vendor</div>
                      <div className="mt-1 font-semibold text-slate-900">{selectedPR.vendorName || '-'}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Financial Year</div>
                      <div className="mt-1 font-semibold text-slate-900">{selectedPR.financialYearName || '-'}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Total Estimated Cost</div>
                      <div className="mt-1 font-semibold text-slate-900">{formatMoney(selectedPR.totalEstimatedCost)}</div>
                    </div>
                  </div>

                  {selectedPR.subject && (
                    <div>
                      <div className="text-xs uppercase tracking-wide text-slate-500">Subject</div>
                      <div className="mt-1 text-sm text-slate-800">{selectedPR.subject}</div>
                    </div>
                  )}

                  <div className="rounded-xl border border-slate-200">
                    <div className="border-b border-slate-200 px-4 py-3 text-sm font-semibold text-slate-800">Items</div>
                    <div className="overflow-x-auto">
                      <table className="min-w-full text-sm">
                        <thead className="bg-slate-50 text-left text-slate-600">
                          <tr>
                            <th className="px-4 py-3 font-semibold">Item</th>
                            <th className="px-4 py-3 font-semibold">Quantity</th>
                            <th className="px-4 py-3 font-semibold">Unit Est. Cost</th>
                            <th className="px-4 py-3 font-semibold">Total Est. Cost</th>
                            <th className="px-4 py-3 font-semibold">Budget Head</th>
                          </tr>
                        </thead>
                        <tbody>
                          {selectedPR.items.map((item) => (
                            <tr key={item.id} className="border-t border-slate-100">
                              <td className="px-4 py-3">{item.itemName || 'Item'}</td>
                              <td className="px-4 py-3">{item.quantity}</td>
                              <td className="px-4 py-3">{formatMoney(item.unitEstimatedCost)}</td>
                              <td className="px-4 py-3">{formatMoney(item.totalEstimatedCost)}</td>
                              <td className="px-4 py-3">{item.budgetHeadName || '-'}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>

                  {selectedPR.statusCategory === 'Pending' && (
                    <div className="flex justify-end gap-2">
                      <button
                        type="button"
                        onClick={async () => {
                          await purchaseRequisitionApi.changeStatus(selectedPR.id, { status: 'Rejected' });
                          setShowDetailModal(false);
                          loadList();
                        }}
                        className="rounded-md border border-rose-200 px-4 py-2 text-sm font-medium text-rose-600 hover:bg-rose-50"
                      >
                        Reject
                      </button>
                      <button
                        type="button"
                        onClick={async () => {
                          await purchaseRequisitionApi.changeStatus(selectedPR.id, { status: 'Approved' });
                          setShowDetailModal(false);
                          loadList();
                        }}
                        className="rounded-md bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700"
                      >
                        Approve
                      </button>
                    </div>
                  )}
                  {selectedPR.statusCategory === 'Processed' && (
                    <div className="flex justify-end gap-2">
                      <button
                        type="button"
                        onClick={async () => {
                          await purchaseRequisitionApi.changeStatus(selectedPR.id, { status: 'Closed' });
                          setShowDetailModal(false);
                          loadList();
                        }}
                        className="rounded-md bg-slate-700 px-4 py-2 text-sm font-medium text-white hover:bg-slate-800"
                      >
                        Close
                      </button>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {showLifeCycleModal && (
        <div className="fixed inset-0 z-[60] flex items-start justify-center bg-slate-900/40 p-4 pt-6">
          <div className="w-full max-w-4xl overflow-hidden rounded-md border border-slate-200 bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
              <div>
                <h3 className="text-[18px] font-medium text-slate-700">Purchase Requisition Life Cycle</h3>
                <p className="text-sm text-slate-500">{lifeCyclePRNumber}</p>
              </div>
              <button type="button" onClick={() => setShowLifeCycleModal(false)} className="rounded-md p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>
            <div className="px-6 py-4">
              <div className="overflow-x-auto border border-slate-200">
                <table className="min-w-full text-sm">
                  <thead>
                    <tr className="bg-white text-slate-900">
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Status</th>
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Action By</th>
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Remarks</th>
                      <th className="border-b border-slate-200 px-6 py-4 text-center font-semibold">Date</th>
                    </tr>
                  </thead>
                  <tbody>
                    {lifeCycleLoading ? (
                      <tr><td colSpan="4" className="px-6 py-10 text-center text-slate-500">Loading...</td></tr>
                    ) : lifeCycleEntries.length === 0 ? (
                      <tr><td colSpan="4" className="px-6 py-10 text-center text-slate-500">No lifecycle entries found.</td></tr>
                    ) : (
                      lifeCycleEntries.map((entry) => (
                        <tr key={entry.id} className="odd:bg-slate-50/60">
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-center text-base text-slate-700">{entry.status}</td>
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-center text-base text-slate-700">{entry.actionBy || '-'}</td>
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-center text-base text-slate-700">{entry.remarks || '-'}</td>
                          <td className="border-b border-slate-200 px-6 py-4 text-center text-base text-slate-700">{formatDateTime(entry.createdOn)}</td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default PurchaseRequisitionsPage;
