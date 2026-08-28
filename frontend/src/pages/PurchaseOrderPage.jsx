import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ArrowDownTrayIcon,
  EyeIcon,
  InformationCircleIcon,
  MagnifyingGlassIcon,
  PlusIcon,
  XMarkIcon
} from '@heroicons/react/24/outline';
import purchaseOrderApi from '../services/purchaseOrderApi';
import vendorApi from '../services/vendorApi';
import { getAllStores } from '../services/storeApi';
import itemApi from '../services/itemApi';
import { productOptionValue, parseProductOptionValue, findProductRow } from '../utils/productKey';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';

function formatDateTime(value) {
  if (!value) {
    return '-';
  }

  return new Date(value).toLocaleString('en-US', {
    month: 'short',
    day: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  });
}

function formatDate(value) {
  if (!value) {
    return '-';
  }

  return new Date(value).toLocaleDateString('en-US', {
    month: '2-digit',
    day: '2-digit',
    year: 'numeric'
  });
}

function formatNumber(value) {
  if (value === null || value === undefined || value === '') {
    return '0';
  }

  return Number(value).toLocaleString('en-US', {
    maximumFractionDigits: 2
  });
}

function formatCurrency(value) {
  if (value === null || value === undefined || value === '') {
    return '0.00';
  }

  return Number(value).toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
}

function statusClasses(status) {
  switch ((status || '').toLowerCase()) {
    case 'approved':
      return 'text-emerald-700';
    case 'pending':
      return 'text-amber-700';
    case 'cancelled':
      return 'text-rose-700';
    default:
      return 'text-slate-700';
  }
}

function emptyLineDraft() {
  return {
    itemId: '',
    packetQuantity: '',
    unitQuantity: '',
    packetPrice: '',
    unitPrice: ''
  };
}

function emptyForm() {
  return {
    storeId: '',
    vendorId: '',
    itemType: 'Medicine',
    manualPONumber: '',
    poValidityDate: '',
    subject: '',
    instructions: '',
    termsAndConditions: '',
    items: []
  };
}

function matchesItemType(item, selectedType) {
  if (!selectedType) {
    return true;
  }

  return item.sourceType === selectedType;
}

const PurchaseOrderPage = () => {
  const [submitting, setSubmitting] = useState(false);
  const [showCreateForm, setShowCreateForm] = useState(false);
  // No date range by default - a real purchase order can be weeks or months old, and
  // silently filtering the list down to "the last 30 days" on first load made the page
  // look empty/broken even when orders existed. The date pickers stay empty until the
  // user actively narrows the range and clicks Search.
  const [filters, setFilters] = useState({
    dateFrom: '',
    dateTo: '',
    vendorId: '',
    status: ''
  });
  const [submittedFilters, setSubmittedFilters] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');

  const fetchPage = useCallback(async (params) => {
    const data = await purchaseOrderApi.getAll(params);
    return { items: data.items || [], totalCount: data.totalCount || 0 };
  }, []);

  const {
    items: orders,
    totalCount,
    currentPage,
    pageSize: entriesPerPage,
    setPageSize: setEntriesPerPage,
    goToPage,
    loading,
    error: fetchError,
    reload: loadOrders,
    search: runSearch,
  } = usePagedList(
    fetchPage,
    {
      dateFrom: submittedFilters?.dateFrom ? `${submittedFilters.dateFrom}T00:00:00.000Z` : undefined,
      dateTo: submittedFilters?.dateTo ? `${submittedFilters.dateTo}T23:59:59.999Z` : undefined,
      vendorId: submittedFilters?.vendorId || undefined,
      status: submittedFilters?.status || undefined,
      search: searchTerm || undefined,
    },
    { autoLoad: false, initialPageSize: 10 }
  );
  const [lookups, setLookups] = useState({
    vendors: [],
    stores: [],
    items: []
  });
  const [formData, setFormData] = useState(emptyForm());
  const [lineDraft, setLineDraft] = useState(emptyLineDraft());
  const [lineSearchTerm, setLineSearchTerm] = useState('');
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [detailsLoading, setDetailsLoading] = useState(false);
  const [showDetailsModal, setShowDetailsModal] = useState(false);

  const [pageError, setPageError] = useState('');

  useEffect(() => {
    loadLookups();
    setSubmittedFilters(filters);
    runSearch({
      dateFrom: filters.dateFrom ? `${filters.dateFrom}T00:00:00.000Z` : undefined,
      dateTo: filters.dateTo ? `${filters.dateTo}T23:59:59.999Z` : undefined,
      vendorId: filters.vendorId || undefined,
      status: filters.status || undefined,
      search: searchTerm || undefined,
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const loadLookups = async () => {
    try {
      const [vendors, stores, items] = await Promise.all([
        vendorApi.getAll(),
        getAllStores(),
        itemApi.getAllWithMedicines()
      ]);

      setLookups({ vendors, stores, items });
    } catch (lookupErr) {
      console.error('Error loading purchase order lookups:', lookupErr);
      setPageError('Failed to load purchase order dropdown data.');
    }
  };

  const handleSearch = () => {
    setSubmittedFilters(filters);
    runSearch({
      dateFrom: filters.dateFrom ? `${filters.dateFrom}T00:00:00.000Z` : undefined,
      dateTo: filters.dateTo ? `${filters.dateTo}T23:59:59.999Z` : undefined,
      vendorId: filters.vendorId || undefined,
      status: filters.status || undefined,
      search: searchTerm || undefined,
    });
  };

  const handleSearchTermChange = (value) => {
    setSearchTerm(value);
    runSearch({
      dateFrom: submittedFilters?.dateFrom ? `${submittedFilters.dateFrom}T00:00:00.000Z` : undefined,
      dateTo: submittedFilters?.dateTo ? `${submittedFilters.dateTo}T23:59:59.999Z` : undefined,
      vendorId: submittedFilters?.vendorId || undefined,
      status: submittedFilters?.status || undefined,
      search: value || undefined,
    });
  };

  const filteredLineItems = useMemo(() => {
    if (!lineSearchTerm.trim()) {
      return formData.items;
    }

    const normalized = lineSearchTerm.trim().toLowerCase();
    return formData.items.filter((item) => [item.itemName, item.itemModel, item.itemType]
      .some((value) => (value || '').toLowerCase().includes(normalized)));
  }, [formData.items, lineSearchTerm]);

  const selectableItems = useMemo(
    () => lookups.items.filter((item) => matchesItemType(item, formData.itemType)),
    [formData.itemType, lookups.items]
  );

  const handleFilterChange = (event) => {
    const { name, value } = event.target;
    setFilters((current) => ({
      ...current,
      [name]: value
    }));
  };

  const handleFormChange = (event) => {
    const { name, value } = event.target;
    setFormData((current) => ({
      ...current,
      [name]: value
    }));

    if (name === 'itemType') {
      setLineDraft(emptyLineDraft());
    }
  };

  const handleLineDraftChange = (event) => {
    const { name, value } = event.target;
    setLineDraft((current) => ({
      ...current,
      [name]: value
    }));
  };

  const openCreateForm = () => {
    setFormData(emptyForm());
    setLineDraft(emptyLineDraft());
    setLineSearchTerm('');
    setShowCreateForm(true);
  };

  const closeCreateForm = () => {
    setShowCreateForm(false);
    setSubmitting(false);
  };

  const addLineItem = () => {
    if (!lineDraft.itemId || !lineDraft.unitQuantity || !lineDraft.unitPrice) {
      alert('Please select an item and enter unit quantity and unit price.');
      return;
    }

    const selectedItem = findProductRow(lookups.items, parseProductOptionValue(lineDraft.itemId));
    if (!selectedItem) {
      alert('Selected item could not be found.');
      return;
    }

    const unitQuantity = Number(lineDraft.unitQuantity);
    const unitPrice = Number(lineDraft.unitPrice);
    const packetQuantity = lineDraft.packetQuantity ? Number(lineDraft.packetQuantity) : null;
    const packetPrice = lineDraft.packetPrice ? Number(lineDraft.packetPrice) : null;

    if (unitQuantity <= 0 || unitPrice <= 0) {
      alert('Unit quantity and unit price must be greater than zero.');
      return;
    }

    setFormData((current) => ({
      ...current,
      items: [
        ...current.items,
        {
          itemId: selectedItem.itemId,
          medicineId: selectedItem.medicineId,
          subServiceId: selectedItem.subServiceId,
          itemName: selectedItem.name,
          itemModel: selectedItem.model,
          itemType: formData.itemType,
          packetQuantity,
          unitQuantity,
          packetPrice,
          unitPrice,
          totalPrice: unitQuantity * unitPrice
        }
      ]
    }));

    setLineDraft(emptyLineDraft());
  };

  const removeLineItem = (indexToRemove) => {
    setFormData((current) => ({
      ...current,
      items: current.items.filter((_, index) => index !== indexToRemove)
    }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!formData.storeId || !formData.vendorId) {
      alert('Please select a store and vendor.');
      return;
    }

    if (formData.items.length === 0) {
      alert('Please add at least one item to the purchase order.');
      return;
    }

    setSubmitting(true);

    try {
      await purchaseOrderApi.create({
        storeId: Number(formData.storeId),
        vendorId: Number(formData.vendorId),
        manualPONumber: formData.manualPONumber || null,
        poValidityDate: formData.poValidityDate ? new Date(`${formData.poValidityDate}T00:00:00`).toISOString() : null,
        subject: formData.subject || null,
        instructions: formData.instructions || null,
        termsAndConditions: formData.termsAndConditions || null,
        items: formData.items.map((item) => ({
          itemId: item.itemId,
          medicineId: item.medicineId,
          subServiceId: item.subServiceId,
          itemType: item.itemType,
          packetQuantity: item.packetQuantity,
          unitQuantity: item.unitQuantity,
          packetPrice: item.packetPrice,
          unitPrice: item.unitPrice
        }))
      });

      closeCreateForm();
      await loadOrders();
    } catch (submitError) {
      console.error('Error creating purchase order:', submitError);
      alert(submitError.response?.data?.message || 'Failed to create purchase order.');
      setSubmitting(false);
    }
  };

  // Exports only the current page - the full filtered result set now lives
  // server-side and isn't all loaded into the browser at once.
  const exportCsv = () => {
    const rows = orders.map((order) => [
      order.poNumber,
      `${order.itemsCount} item(s) / ${formatNumber(order.totalQuantity)}`,
      order.vendorName,
      formatDateTime(order.createdOn),
      formatDate(order.poValidityDate),
      order.status
    ]);

    const csv = [
      ['PO Number', 'Items (Qty)', 'Vendor', 'Date & Time', 'PO Validity', 'Status'],
      ...rows
    ]
      .map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(','))
      .join('\n');

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'purchase-orders.csv';
    link.click();
    URL.revokeObjectURL(url);
  };

  const openDetailsModal = async (purchaseOrderId) => {
    setShowDetailsModal(true);
    setDetailsLoading(true);
    try {
      const details = await purchaseOrderApi.getById(purchaseOrderId);
      setSelectedOrder(details);
    } catch (detailsError) {
      console.error('Error loading purchase order details:', detailsError);
      setSelectedOrder(null);
      setPageError('Failed to load purchase order details.');
    } finally {
      setDetailsLoading(false);
    }
  };

  const closeDetailsModal = () => {
    setShowDetailsModal(false);
    setSelectedOrder(null);
  };

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      {!showCreateForm ? (
        <div className="space-y-3">
          <section className="rounded-md border border-slate-200 bg-white shadow-sm">
            <div className="flex flex-col gap-4 border-b border-slate-100 px-4 py-3 lg:flex-row lg:items-center lg:justify-between">
              <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
                Purchase Order
                <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
              </h1>

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={exportCsv}
                  className="inline-flex items-center gap-2 rounded-md border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50"
                >
                  <ArrowDownTrayIcon className="h-4 w-4 text-indigo-500" />
                  Export
                </button>
                <button
                  type="button"
                  onClick={openCreateForm}
                  className="inline-flex items-center gap-2 rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-indigo-700"
                >
                  <PlusIcon className="h-4 w-4" />
                  Add Purchase Order
                </button>
              </div>
            </div>

            {pageError && (
              <div className="px-6 pt-4 text-sm text-rose-600">{pageError}</div>
            )}

            <div className="grid grid-cols-1 gap-x-8 gap-y-6 px-6 py-5 lg:grid-cols-2">
              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Date Range</label>
                <div className="grid grid-cols-[1fr_auto_1fr] items-center gap-2">
                  <input type="date" name="dateFrom" value={filters.dateFrom} onChange={handleFilterChange} className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400" />
                  <span className="text-slate-400">-</span>
                  <input type="date" name="dateTo" value={filters.dateTo} onChange={handleFilterChange} className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400" />
                </div>
              </div>

              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Vendor</label>
                <select name="vendorId" value={filters.vendorId} onChange={handleFilterChange} className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400">
                  <option value="">Select Vendor</option>
                  {lookups.vendors.map((vendor) => (
                    <option key={vendor.id} value={vendor.id}>{vendor.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">PO Status</label>
                <select name="status" value={filters.status} onChange={handleFilterChange} className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400">
                  <option value="">Please Select</option>
                  <option value="Pending">Pending</option>
                  <option value="Approved">Approved</option>
                  <option value="Cancelled">Cancelled</option>
                </select>
              </div>

              <div className="flex items-end justify-end">
                <button type="button" onClick={handleSearch} className="inline-flex items-center gap-2 rounded-md bg-indigo-600 px-6 py-3 text-sm font-medium text-white transition hover:bg-indigo-700">
                  <MagnifyingGlassIcon className="h-4 w-4" />
                  Search
                </button>
              </div>
            </div>
          </section>

          <section className="rounded-md border border-slate-200 bg-white shadow-sm">
            <div className="flex flex-col gap-3 px-4 py-4 md:flex-row md:items-center md:justify-end">
              <label className="flex items-center gap-2 text-sm text-slate-600">
                <span>Search:</span>
                <input type="text" value={searchTerm} onChange={(event) => handleSearchTermChange(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400 md:w-60" />
              </label>
            </div>

            {fetchError ? (
              <div className="px-4 pb-4 text-sm text-rose-600">Failed to load purchase orders.</div>
            ) : (
              <>
                <div className="overflow-x-auto px-4">
                  <table className="min-w-full border-separate border-spacing-0 text-sm">
                    <thead>
                      <tr className="text-left text-slate-700">
                        <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">PO Number</th>
                        <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Items (Qty)</th>
                        <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Vendor</th>
                        <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Date &amp; Time</th>
                        <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">PO Validity</th>
                        <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Status</th>
                        <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      {orders.length === 0 ? (
                        <tr>
                          <td colSpan="7" className="border-b border-slate-200 px-4 py-12 text-center text-slate-500">{loading ? 'Loading purchase orders...' : 'No data available in table'}</td>
                        </tr>
                      ) : (
                        orders.map((order) => (
                          <tr key={order.purchaseOrderId} className="text-slate-700">
                            <td className="border-b border-slate-200 px-6 py-8 align-middle">{order.poNumber}</td>
                            <td className="border-b border-slate-200 px-6 py-8 align-middle">{order.itemsCount} item(s) ({formatNumber(order.totalQuantity)})</td>
                            <td className="border-b border-slate-200 px-6 py-8 align-middle">{order.vendorName}</td>
                            <td className="border-b border-slate-200 px-6 py-8 align-middle">{formatDateTime(order.createdOn)}</td>
                            <td className="border-b border-slate-200 px-6 py-8 align-middle">{formatDate(order.poValidityDate)}</td>
                            <td className={`border-b border-slate-200 px-6 py-8 align-middle ${statusClasses(order.status)}`}>{order.status}</td>
                            <td className="border-b border-slate-200 px-6 py-8 align-middle">
                              <button type="button" onClick={() => openDetailsModal(order.purchaseOrderId)} className="text-indigo-500 transition hover:text-indigo-700" title="View Purchase Order">
                                <EyeIcon className="h-5 w-5" />
                              </button>
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                    <tfoot>
                      <tr className="text-left text-slate-700">
                        <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">PO Number</th>
                        <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Items (Qty)</th>
                        <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Vendor</th>
                        <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Date &amp; Time</th>
                        <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">PO Validity</th>
                        <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Status</th>
                        <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Action</th>
                      </tr>
                    </tfoot>
                  </table>
                </div>

                <Pagination
                  currentPage={currentPage}
                  pageSize={entriesPerPage}
                  totalCount={totalCount}
                  onPageChange={goToPage}
                  onPageSizeChange={setEntriesPerPage}
                />
              </>
            )}
          </section>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className="space-y-4 rounded-md border border-slate-200 bg-white px-4 py-4 shadow-sm">
          <div className="flex items-center justify-between border-b border-slate-100 pb-3">
            <h1 className="text-xl font-semibold text-slate-900">Purchase Order</h1>
            <button type="button" onClick={closeCreateForm} className="rounded-md p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600">
              <XMarkIcon className="h-5 w-5" />
            </button>
          </div>

          <div className="grid grid-cols-1 gap-x-4 gap-y-5 lg:grid-cols-2">
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Store*</label>
              <select name="storeId" value={formData.storeId} onChange={handleFormChange} className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400">
                <option value="">Select Store</option>
                {lookups.stores.map((store) => (
                  <option key={store.storeId} value={store.storeId}>{store.storeName}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Vendor*</label>
              <select name="vendorId" value={formData.vendorId} onChange={handleFormChange} className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400">
                <option value="">Select Vendor</option>
                {lookups.vendors.map((vendor) => (
                  <option key={vendor.id} value={vendor.id}>{vendor.name}</option>
                ))}
              </select>
            </div>

            <div className="lg:col-span-2">
              <label className="mb-2 block text-sm font-medium text-slate-700">Item Type</label>
              <div className="flex flex-wrap items-center gap-6 pt-2 text-sm text-slate-700">
                {['Medicine', 'Disposable', 'Item'].map((type) => (
                  <label key={type} className="inline-flex items-center gap-2">
                    <input type="radio" name="itemType" value={type} checked={formData.itemType === type} onChange={handleFormChange} />
                    {type === 'Item' ? 'Item(s)' : `${type}(s)`}
                  </label>
                ))}
              </div>
            </div>

            <div className="lg:col-span-2">
              <label className="mb-2 block text-sm font-medium text-slate-700">Item*</label>
              <select name="itemId" value={lineDraft.itemId} onChange={handleLineDraftChange} className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400">
                <option value="">Search Item</option>
                {selectableItems.map((item) => (
                  <option key={productOptionValue(item)} value={productOptionValue(item)}>{item.name}{item.model ? ` (${item.model})` : ''}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Packet Quantity</label>
              <input type="number" min="0" step="0.01" name="packetQuantity" value={lineDraft.packetQuantity} onChange={handleLineDraftChange} placeholder="Packet Quantity" className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400" />
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Unit Quantity*</label>
              <input type="number" min="0" step="0.01" name="unitQuantity" value={lineDraft.unitQuantity} onChange={handleLineDraftChange} placeholder="Quantity" className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400" />
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Packet Price</label>
              <input type="number" min="0" step="0.01" name="packetPrice" value={lineDraft.packetPrice} onChange={handleLineDraftChange} placeholder="Packet Price (Currency)" className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400" />
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Unit Price*</label>
              <input type="number" min="0" step="0.01" name="unitPrice" value={lineDraft.unitPrice} onChange={handleLineDraftChange} placeholder="Unit Price (Currency)" className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400" />
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Manual PO Number</label>
              <input type="text" name="manualPONumber" value={formData.manualPONumber} onChange={handleFormChange} placeholder="Manual PO Number" className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400" />
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">PO Validity Date</label>
              <input type="date" name="poValidityDate" value={formData.poValidityDate} onChange={handleFormChange} className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400" />
            </div>
          </div>

          <div className="flex items-center justify-end gap-2">
            <button type="button" onClick={addLineItem} className="rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-indigo-700">Add</button>
            <button type="button" onClick={() => setLineDraft(emptyLineDraft())} className="rounded-md border border-slate-200 px-4 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-50">Cancel</button>
          </div>

          <div className="space-y-4 rounded-md border border-slate-200 p-3">
            <div className="flex items-center justify-end">
              <label className="flex items-center gap-2 text-sm text-slate-600">
                <span>Search:</span>
                <input type="text" value={lineSearchTerm} onChange={(event) => setLineSearchTerm(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400 md:w-52" />
              </label>
            </div>

            <div className="overflow-x-auto">
              <table className="min-w-full border-separate border-spacing-0 text-sm">
                <thead>
                  <tr className="text-left text-slate-700">
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Sr#</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Items, Brand (Model)</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Unit Price</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Quantity</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Total Price</th>
                    <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Action</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredLineItems.length === 0 ? (
                    <tr>
                      <td colSpan="6" className="border-b border-slate-200 px-4 py-8 text-center text-slate-500">No data available in table</td>
                    </tr>
                  ) : (
                    filteredLineItems.map((item, index) => (
                      <tr key={`${item.itemId}-${index}`}>
                        <td className="border-b border-slate-200 px-4 py-4">{index + 1}</td>
                        <td className="border-b border-slate-200 px-4 py-4">{item.itemName}{item.itemModel ? ` (${item.itemModel})` : ''}</td>
                        <td className="border-b border-slate-200 px-4 py-4">{formatCurrency(item.unitPrice)}</td>
                        <td className="border-b border-slate-200 px-4 py-4">{formatNumber(item.unitQuantity)}</td>
                        <td className="border-b border-slate-200 px-4 py-4">{formatCurrency(item.totalPrice)}</td>
                        <td className="border-b border-slate-200 px-4 py-4">
                          <button type="button" onClick={() => removeLineItem(index)} className="text-rose-600 transition hover:text-rose-700">Remove</button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

            <div className="text-sm text-slate-600">Showing {filteredLineItems.length === 0 ? 0 : 1} to {filteredLineItems.length} of {filteredLineItems.length} entries</div>
          </div>

          <div className="rounded-md border border-slate-200 p-4">
            <div className="mb-4 text-sm font-medium text-slate-700">Instructions and Term &amp; Conditions</div>
            <div className="space-y-4">
              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Subject</label>
                <input type="text" name="subject" value={formData.subject} onChange={handleFormChange} className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400" />
              </div>
              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Instructions</label>
                <textarea name="instructions" value={formData.instructions} onChange={handleFormChange} rows="4" className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400" />
              </div>
              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Term &amp; Conditions</label>
                <textarea name="termsAndConditions" value={formData.termsAndConditions} onChange={handleFormChange} rows="8" className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400" />
              </div>
            </div>
          </div>

          <div className="flex justify-end">
            <button type="submit" disabled={submitting} className="rounded-md bg-indigo-600 px-6 py-3 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60">
              {submitting ? 'Submitting...' : 'Submit'}
            </button>
          </div>
        </form>
      )}

      {showDetailsModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
          <div className="max-h-[90vh] w-full max-w-5xl overflow-hidden rounded-md bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
              <h3 className="text-lg font-semibold text-slate-900">Purchase Order Details</h3>
              <button type="button" onClick={closeDetailsModal} className="rounded-md p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            <div className="max-h-[calc(90vh-72px)] overflow-y-auto px-6 py-5">
              {detailsLoading ? (
                <div className="text-sm text-slate-500">Loading purchase order details...</div>
              ) : !selectedOrder ? (
                <div className="text-sm text-slate-500">Purchase order details are unavailable.</div>
              ) : (
                <div className="space-y-5">
                  <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">PO Number</div>
                      <div className="mt-1 font-semibold text-slate-900">{selectedOrder.poNumber}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Manual PO Number</div>
                      <div className="mt-1 font-semibold text-slate-900">{selectedOrder.manualPONumber || '-'}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Store</div>
                      <div className="mt-1 font-semibold text-slate-900">{selectedOrder.storeName}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Vendor</div>
                      <div className="mt-1 font-semibold text-slate-900">{selectedOrder.vendorName}</div>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Date &amp; Time</div>
                      <div className="mt-1 font-semibold text-slate-900">{formatDateTime(selectedOrder.createdOn)}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">PO Validity</div>
                      <div className="mt-1 font-semibold text-slate-900">{formatDate(selectedOrder.poValidityDate)}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Status</div>
                      <div className={`mt-1 font-semibold ${statusClasses(selectedOrder.status)}`}>{selectedOrder.status}</div>
                    </div>
                  </div>

                  <div className="rounded-xl border border-slate-200">
                    <div className="border-b border-slate-200 px-4 py-3 text-sm font-semibold text-slate-800">Ordered Items</div>
                    <div className="overflow-x-auto">
                      <table className="min-w-full text-sm">
                        <thead className="bg-slate-50 text-left text-slate-600">
                          <tr>
                            <th className="px-4 py-3 font-semibold">Item</th>
                            <th className="px-4 py-3 font-semibold">Type</th>
                            <th className="px-4 py-3 font-semibold">Packet Qty</th>
                            <th className="px-4 py-3 font-semibold">Unit Qty</th>
                            <th className="px-4 py-3 font-semibold">Unit Price</th>
                            <th className="px-4 py-3 font-semibold">Total</th>
                          </tr>
                        </thead>
                        <tbody>
                          {selectedOrder.items.map((item) => (
                            <tr key={item.id} className="border-t border-slate-100">
                              <td className="px-4 py-3">{item.itemName}{item.itemModel ? ` (${item.itemModel})` : ''}</td>
                              <td className="px-4 py-3">{item.itemTypeName || '-'}</td>
                              <td className="px-4 py-3">{formatNumber(item.packetQuantity)}</td>
                              <td className="px-4 py-3">{formatNumber(item.unitQuantity)}</td>
                              <td className="px-4 py-3">{formatCurrency(item.unitPrice)}</td>
                              <td className="px-4 py-3">{formatCurrency(item.totalPrice)}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Subject</div>
                      <div className="mt-1 text-sm text-slate-800">{selectedOrder.subject || '-'}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Instructions</div>
                      <div className="mt-1 text-sm text-slate-800 whitespace-pre-wrap">{selectedOrder.instructions || '-'}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Terms &amp; Conditions</div>
                      <div className="mt-1 text-sm text-slate-800 whitespace-pre-wrap">{selectedOrder.termsAndConditions || '-'}</div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default PurchaseOrderPage;