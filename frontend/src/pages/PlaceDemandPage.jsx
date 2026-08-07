import React, { useEffect, useState } from 'react';
import {
  ArrowDownTrayIcon,
  EyeIcon,
  InformationCircleIcon,
  PlusIcon,
  PrinterIcon,
  XMarkIcon
} from '@heroicons/react/24/outline';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import demandRequestApi from '../services/demandRequestApi';
import { getAllStores } from '../services/storeApi';
import stockTypesApi from '../services/stockTypesApi';
import itemApi from '../services/itemApi';
import stockApi from '../services/stockApi';
import BranchField from '../components/BranchField';
import { useSession } from '../context/SessionContext';
import { productOptionValue, parseProductOptionValue } from '../utils/productKey';

const createDefaultDateRange = () => {
  const now = new Date();
  const from = new Date(now);
  from.setDate(from.getDate() - 30);
  from.setHours(0, 0, 0, 0);

  const to = new Date(now);
  to.setDate(to.getDate() + 30);
  to.setHours(23, 59, 0, 0);

  return {
    dateFrom: toInputValue(from),
    dateTo: toInputValue(to)
  };
};

function toInputValue(date) {
  const adjusted = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
  return adjusted.toISOString().slice(0, 16);
}

function formatDateTime(value) {
  if (!value) {
    return '-';
  }

  const date = new Date(value);
  return date.toLocaleString('en-GB', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}

function formatRange(dateFrom, dateTo) {
  if (!dateFrom && !dateTo) {
    return 'All';
  }

  return `${formatDateTime(dateFrom)} - ${formatDateTime(dateTo)}`;
}

function statusClasses(status) {
  switch ((status || '').toLowerCase()) {
    case 'approved':
      return 'bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-200';
    case 'pending':
      return 'bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-200';
    case 'issued':
      return 'bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-200';
    case 'rejected':
      return 'bg-rose-50 text-rose-700 ring-1 ring-inset ring-rose-200';
    default:
      return 'bg-slate-100 text-slate-700 ring-1 ring-inset ring-slate-200';
  }
}

const emptyForm = () => {
  const defaults = createDefaultDateRange();
  return {
    branchId: '',
    requestingStoreId: '',
    requestedStoreId: '',
    stockTypeId: '',
    dateFrom: defaults.dateFrom,
    dateTo: defaults.dateTo,
    remarks: '',
    items: [
      {
        itemId: '',
        requestedQuantity: ''
      }
    ]
  };
};

const PlaceDemandPage = () => {
  const { session } = useSession();
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const [formError, setFormError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [entriesPerPage, setEntriesPerPage] = useState(5);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [detailsLoading, setDetailsLoading] = useState(false);
  const [lookups, setLookups] = useState({
    stores: [],
    stockTypes: [],
    items: []
  });
  const [filters, setFilters] = useState(createDefaultDateRange());
  const [formData, setFormData] = useState(emptyForm());
  const [itemQuantities, setItemQuantities] = useState({});

  useEffect(() => {
    loadLookups();
  }, []);

  // Refresh the item picker's "in stock at Requested Store" quantities whenever the
  // create form's Requested Store changes, so the dropdown always reflects that store.
  useEffect(() => {
    if (!showCreateModal || !formData.requestedStoreId) {
      setItemQuantities({});
      return;
    }

    let cancelled = false;

    stockApi.getQuantitiesByStore(formData.requestedStoreId)
      .then((quantities) => {
        if (!cancelled) {
          setItemQuantities(quantities);
        }
      })
      .catch((quantitiesError) => {
        console.error('Error loading item quantities for store:', quantitiesError);
        if (!cancelled) {
          setItemQuantities({});
        }
      });

    return () => {
      cancelled = true;
    };
  }, [showCreateModal, formData.requestedStoreId]);

  // "Branch Request By" (filter) and "Branch Request To" (create form) are both
  // always scoped to the logged-in user's own branch, same as everywhere else in
  // this app - a demand request is placed BY your branch, not on behalf of any
  // branch you pick from a list.
  useEffect(() => {
    if (session?.branchId) {
      setFilters((current) => ({ ...current, branchId: session.branchId }));
      setFormData((current) => ({ ...current, branchId: session.branchId }));
    }
  }, [session?.branchId]);

  useEffect(() => {
    loadRequests();
  }, [filters.dateFrom, filters.dateTo, filters.branchId, filters.requestingStoreId, filters.stockTypeId, searchTerm, entriesPerPage, currentPage]);

  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, entriesPerPage, filters.dateFrom, filters.dateTo, filters.branchId, filters.requestingStoreId, filters.stockTypeId]);

  const loadLookups = async () => {
    try {
      const [stores, stockTypes, items] = await Promise.all([
        getAllStores(),
        stockTypesApi.getAllStockTypes(),
        itemApi.getAllWithMedicines()
      ]);

      setLookups({
        stores,
        stockTypes,
        items
      });
    } catch (lookupError) {
      console.error('Error loading lookup data:', lookupError);
      setError('Failed to load dropdown data.');
    }
  };

  const loadRequests = async () => {
    setLoading(true);
    setError('');

    try {
      const response = await demandRequestApi.getAll({
        dateFrom: filters.dateFrom ? new Date(filters.dateFrom).toISOString() : undefined,
        dateTo: filters.dateTo ? new Date(filters.dateTo).toISOString() : undefined,
        branchId: filters.branchId || undefined,
        requestingStoreId: filters.requestingStoreId || undefined,
        stockTypeId: filters.stockTypeId || undefined,
        search: searchTerm.trim() || undefined,
        pageNumber: currentPage,
        pageSize: entriesPerPage
      });
      setRequests(response.items);
      setTotalCount(response.totalCount);
    } catch (requestError) {
      console.error('Error loading demand requests:', requestError);
      setError('Failed to load demand requests.');
    } finally {
      setLoading(false);
    }
  };

  const pagedRequests = requests;
  const totalPages = Math.max(1, Math.ceil(totalCount / entriesPerPage));
  const startIndex = (currentPage - 1) * entriesPerPage;

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
  };

  const handleItemChange = (index, field, value) => {
    setFormData((current) => {
      const nextItems = [...current.items];
      nextItems[index] = {
        ...nextItems[index],
        ...(field === 'itemId' ? parseProductOptionValue(value) : { [field]: value })
      };

      return {
        ...current,
        items: nextItems
      };
    });
  };

  // Only the item picker and quantity are per-demand; the store/stock type picked for one
  // demand carries over to the next so the user isn't asked to re-select them every time.
  const openCreateModal = () => {
    setFormData((current) => ({
      ...current,
      remarks: '',
      items: [{ itemId: '', medicineId: '', subServiceId: '', requestedQuantity: '' }]
    }));
    setShowCreateModal(true);
  };

  const closeCreateModal = () => {
    setShowCreateModal(false);
    setSubmitting(false);
    setFormError('');
  };

  const openDetailsModal = async (requestId) => {
    setDetailsLoading(true);
    setShowDetailsModal(true);

    try {
      const details = await demandRequestApi.getById(requestId);
      setSelectedRequest(details);
    } catch (detailsError) {
      console.error('Error loading demand request details:', detailsError);
      setSelectedRequest(null);
      setError('Failed to load request details.');
    } finally {
      setDetailsLoading(false);
    }
  };

  const closeDetailsModal = () => {
    setShowDetailsModal(false);
    setSelectedRequest(null);
  };

  // "Print" - the full "Demand Request" report: RIC letterhead, header grid, items
  // table with Requested/Approved/Issued/Remaining quantities, notes, and signature block.
  const handlePrintDemandRequest = async (request) => {
    let details;
    try {
      details = await demandRequestApi.getById(request.demandRequestId);
    } catch (printError) {
      console.error('Error loading demand details for print:', printError);
      setError('Failed to load demand details for printing.');
      return;
    }

    const doc = new jsPDF();
    const pageWidth = doc.internal.pageSize.width;

    try {
      const logoImg = new Image();
      logoImg.src = '/logo.jpg';
      await new Promise((resolve) => {
        logoImg.onload = () => {
          doc.addImage(logoImg, 'JPEG', 14, 10, 18, 18);
          resolve();
        };
        logoImg.onerror = () => resolve();
      });
    } catch (logoError) {
      console.error('Logo load error:', logoError);
    }

    doc.setFontSize(15);
    doc.setFont('helvetica', 'bold');
    doc.text('Rawalpindi Institute of Cardiology', pageWidth / 2, 16, { align: 'center' });

    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    doc.text('Rawal Road', pageWidth / 2, 22, { align: 'center' });
    doc.text('Email: info@ric.gov.pk, Ph: 051928111-9', pageWidth / 2, 27, { align: 'center' });

    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('Demand Request', pageWidth / 2, 36, { align: 'center' });

    const dateOnly = (value) => (value ? new Date(value).toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' }) : '-');

    const headerRows = [
      ['DR-Number', details.drNo || '-', 'Stock Type', details.stockTypeName || 'All'],
      ['Requested Date', dateOnly(details.createdOn), 'Requested By', details.requestedByName || '-'],
      ['Request Status', details.status || '-', 'From Store', details.requestingStoreName || '-'],
      ['To Store', details.requestedStoreName || '-', 'Approved Date', dateOnly(details.approvedDate)],
      ['Issued Date', dateOnly(details.issuedDate), '', '']
    ];

    autoTable(doc, {
      startY: 42,
      body: headerRows,
      theme: 'grid',
      styles: { fontSize: 9, cellPadding: 3, lineColor: [0, 0, 0], lineWidth: 0.1 },
      columnStyles: {
        0: { fontStyle: 'bold', cellWidth: 40 },
        1: { cellWidth: 55 },
        2: { fontStyle: 'bold', cellWidth: 40 },
        3: { cellWidth: 55 }
      }
    });

    const itemsBody = details.items.map((item, index) => [
      index + 1,
      item.itemName || 'Unassigned Item',
      item.requestedQuantity ?? 0,
      item.approvedQuantity ?? '-',
      item.issuedQuantity ?? '-',
      item.remainingQuantity ?? '-'
    ]);

    autoTable(doc, {
      startY: doc.lastAutoTable.finalY + 6,
      head: [['Sr.', 'Items', 'Requested Qty', 'Approved Qty', 'Issued Qty', 'Remaining Qty']],
      body: itemsBody,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 2, lineColor: [0, 0, 0], lineWidth: 0.1 },
      headStyles: { fillColor: [255, 255, 255], textColor: [0, 0, 0], fontStyle: 'bold', halign: 'center' },
      columnStyles: {
        0: { cellWidth: 10, halign: 'center' },
        2: { halign: 'right' },
        3: { halign: 'right' },
        4: { halign: 'right' },
        5: { halign: 'right' }
      }
    });

    let y = doc.lastAutoTable.finalY + 8;
    doc.setFontSize(9);
    doc.setFont('helvetica', 'bold');
    doc.text('Demand Notes:', 14, y);
    doc.setFont('helvetica', 'normal');
    doc.text(details.remarks || '-', 40, y);

    y += 12;
    autoTable(doc, {
      startY: y,
      head: [['Sign/Stamp', 'Name', 'Designation', 'Department', 'Date']],
      body: [['', '', '', '', '']],
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 6, lineColor: [0, 0, 0], lineWidth: 0.1 },
      headStyles: { fillColor: [255, 255, 255], textColor: [0, 0, 0], fontStyle: 'bold', halign: 'center' }
    });

    y = doc.lastAutoTable.finalY + 8;
    doc.setFontSize(8);
    doc.setFont('helvetica', 'italic');
    doc.text('This is a computer generated document, therefore signatures are not required.', pageWidth / 2, y, { align: 'center' });

    const now = new Date();
    const dateStr = now.toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' });
    const timeStr = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
    doc.setFont('helvetica', 'normal');
    doc.text(`${dateStr}   ${timeStr}`, 14, doc.internal.pageSize.height - 10);
    doc.text('Page 1 of 1', pageWidth - 14, doc.internal.pageSize.height - 10, { align: 'right' });

    doc.save(`DemandRequest_${details.drNo}.pdf`);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    const validItems = formData.items.filter((item) => (item.itemId || item.medicineId || item.subServiceId) && Number(item.requestedQuantity) > 0);

    if (!formData.branchId || !formData.requestingStoreId || !formData.requestedStoreId || !formData.dateFrom || !formData.dateTo) {
      alert('Please complete the required request fields.');
      return;
    }

    if (formData.requestingStoreId === formData.requestedStoreId) {
      alert('Requesting Store and Requested Store must be different.');
      return;
    }

    if (validItems.length === 0) {
      alert('Please add at least one item with quantity.');
      return;
    }

    setSubmitting(true);
    setSuccessMessage('');
    setFormError('');

    try {
      const created = await demandRequestApi.create({
        branchId: Number(formData.branchId),
        requestingStoreId: Number(formData.requestingStoreId),
        requestedStoreId: Number(formData.requestedStoreId),
        stockTypeId: formData.stockTypeId ? Number(formData.stockTypeId) : null,
        dateFrom: new Date(formData.dateFrom).toISOString(),
        dateTo: new Date(formData.dateTo).toISOString(),
        remarks: formData.remarks || null,
        items: validItems.map((item) => ({
          itemId: item.itemId ? Number(item.itemId) : null,
          medicineId: item.medicineId ? Number(item.medicineId) : null,
          subServiceId: item.subServiceId ? Number(item.subServiceId) : null,
          requestedQuantity: Number(item.requestedQuantity),
          stockTypeId: formData.stockTypeId ? Number(formData.stockTypeId) : null
        }))
      });

      setSuccessMessage(`Demand request ${created.drNo} created successfully. It may not appear below if it doesn't match the current filters.`);
      closeCreateModal();
      await loadRequests();
    } catch (submitError) {
      console.error('Error creating demand request:', submitError);
      setFormError(submitError.response?.data?.message || 'Failed to create demand request.');
      setSubmitting(false);
    }
  };

  const exportCsv = async () => {
    let allRequests;
    try {
      const response = await demandRequestApi.getAll({
        dateFrom: filters.dateFrom ? new Date(filters.dateFrom).toISOString() : undefined,
        dateTo: filters.dateTo ? new Date(filters.dateTo).toISOString() : undefined,
        branchId: filters.branchId || undefined,
        requestingStoreId: filters.requestingStoreId || undefined,
        stockTypeId: filters.stockTypeId || undefined,
        search: searchTerm.trim() || undefined,
        pageNumber: 1,
        pageSize: Math.max(totalCount, 1)
      });
      allRequests = response.items;
    } catch (exportError) {
      console.error('Error exporting demand requests:', exportError);
      setError('Failed to export demand requests.');
      return;
    }

    const rows = allRequests.map((request) => [
      request.drNo,
      request.indentNo || '',
      request.stockTypeName || '',
      request.requestingBranchName,
      request.requestedStoreName,
      request.itemsCount,
      formatDateTime(request.createdOn),
      request.status
    ]);

    const csv = [
      ['DR-No.', 'Indent No.', 'Stock Type', 'Requesting Store', 'Requested Store', 'Items', 'Date & Time', 'Status'],
      ...rows
    ]
      .map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(','))
      .join('\n');

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'place-demand.csv';
    link.click();
    URL.revokeObjectURL(url);
  };

  const showingFrom = totalCount === 0 ? 0 : startIndex + 1;
  const showingTo = Math.min(startIndex + entriesPerPage, totalCount);

  return (
    <div className="min-h-screen bg-slate-100 p-6">
      <div className="space-y-4">
        <section className="rounded-xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-6 py-4">
            <h1 className="flex items-center gap-2 text-xl font-semibold text-slate-900">
              Place Demand
              <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
            </h1>
          </div>

          <div className="grid grid-cols-1 gap-5 px-6 py-5 xl:grid-cols-3">
            <div className="xl:col-span-3">
              <label className="mb-2 block text-sm font-medium text-slate-700">Date Range*</label>
              <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                <input
                  type="datetime-local"
                  name="dateFrom"
                  value={filters.dateFrom || ''}
                  onChange={handleFilterChange}
                  className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                />
                <input
                  type="datetime-local"
                  name="dateTo"
                  value={filters.dateTo || ''}
                  onChange={handleFilterChange}
                  className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                />
              </div>
            </div>

            {/* Branch Request By - locked to the logged-in user's own branch */}
            <BranchField label="Branch Request By" />

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Store Request By</label>
              <select
                name="requestingStoreId"
                value={filters.requestingStoreId || ''}
                onChange={handleFilterChange}
                className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              >
                <option value="">All Stores</option>
                {lookups.stores.map((store) => (
                  <option key={store.storeId} value={store.storeId}>
                    {store.storeName}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Stock Type</label>
              <select
                name="stockTypeId"
                value={filters.stockTypeId || ''}
                onChange={handleFilterChange}
                className="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              >
                <option value="">All</option>
                {lookups.stockTypes.map((stockType) => (
                  <option key={stockType.id} value={stockType.id}>
                    {stockType.name}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </section>

        {successMessage && (
          <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
            {successMessage}
          </div>
        )}

        <section className="rounded-xl border border-slate-200 bg-white shadow-sm">
          <div className="flex flex-col gap-4 border-b border-slate-100 px-6 py-4 lg:flex-row lg:items-center lg:justify-between">
            <h2 className="flex items-center gap-2 text-xl font-semibold text-slate-900">
              Place Demand
            </h2>

            <div className="flex flex-col gap-3 sm:flex-row">
              <button
                type="button"
                onClick={exportCsv}
                className="inline-flex items-center justify-center gap-2 rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50"
              >
                <ArrowDownTrayIcon className="h-4 w-4" />
                Export
              </button>
              <button
                type="button"
                onClick={openCreateModal}
                className="inline-flex items-center justify-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-indigo-700"
              >
                <PlusIcon className="h-4 w-4" />
                Add Demand Request
              </button>
            </div>
          </div>

          <div className="flex flex-col gap-3 px-6 py-4 md:flex-row md:items-center md:justify-between">
            <div className="flex items-center gap-2 text-sm text-slate-600">
              <span>Show</span>
              <select
                value={entriesPerPage}
                onChange={(event) => setEntriesPerPage(Number(event.target.value))}
                className="rounded-md border border-slate-200 px-2 py-1 text-sm"
              >
                {[5, 10, 25, 50].map((size) => (
                  <option key={size} value={size}>
                    {size}
                  </option>
                ))}
              </select>
              <span>entries</span>
            </div>

            <label className="flex items-center gap-2 text-sm text-slate-600">
              <span>Search:</span>
              <input
                type="text"
                value={searchTerm}
                onChange={(event) => setSearchTerm(event.target.value)}
                className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400 md:w-60"
              />
            </label>
          </div>

          {error ? (
            <div className="px-6 pb-6 text-sm text-rose-600">{error}</div>
          ) : loading ? (
            <div className="px-6 pb-6 text-sm text-slate-500">Loading demand requests...</div>
          ) : (
            <>
              <div className="overflow-x-auto px-6">
                <table className="min-w-full border-separate border-spacing-0 text-sm">
                  <thead>
                    <tr className="text-left text-slate-600">
                      <th className="border-y border-slate-200 bg-slate-50 px-4 py-3 font-semibold">DR-No. / Indent No.</th>
                      <th className="border-y border-slate-200 bg-slate-50 px-4 py-3 font-semibold">Stock Type</th>
                      <th className="border-y border-slate-200 bg-slate-50 px-4 py-3 font-semibold">Requesting Store</th>
                      <th className="border-y border-slate-200 bg-slate-50 px-4 py-3 font-semibold">Requested Store</th>
                      <th className="border-y border-slate-200 bg-slate-50 px-4 py-3 font-semibold">Items</th>
                      <th className="border-y border-slate-200 bg-slate-50 px-4 py-3 font-semibold">Date &amp; Time</th>
                      <th className="border-y border-slate-200 bg-slate-50 px-4 py-3 font-semibold">Status</th>
                      <th className="border-y border-slate-200 bg-slate-50 px-4 py-3 font-semibold">Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    {pagedRequests.length === 0 ? (
                      <tr>
                        <td colSpan="8" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">
                          No data available in table
                        </td>
                      </tr>
                    ) : (
                      pagedRequests.map((request) => (
                        <tr key={request.demandRequestId} className="text-slate-700">
                          <td className="border-b border-slate-100 px-4 py-4 align-top">
                            <div className="font-semibold text-slate-900">{request.drNo}</div>
                            <div className="text-xs text-slate-500">{request.indentNo || '-'}</div>
                          </td>
                          <td className="border-b border-slate-100 px-4 py-4 align-top">{request.stockTypeName || 'All'}</td>
                          <td className="border-b border-slate-100 px-4 py-4 align-top">{request.requestingStoreName}</td>
                          <td className="border-b border-slate-100 px-4 py-4 align-top">{request.requestedStoreName}</td>
                          <td className="border-b border-slate-100 px-4 py-4 align-top">
                            <div>{request.itemsCount} item{request.itemsCount === 1 ? '' : 's'}</div>
                            <div className="text-xs text-slate-500">Qty {request.totalRequestedQuantity}</div>
                          </td>
                          <td className="border-b border-slate-100 px-4 py-4 align-top">
                            <div>{formatDateTime(request.createdOn)}</div>
                            <div className="text-xs text-slate-500">{formatRange(request.dateFrom, request.dateTo)}</div>
                          </td>
                          <td className="border-b border-slate-100 px-4 py-4 align-top">
                            <span className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${statusClasses(request.status)}`}>
                              {request.status}
                            </span>
                          </td>
                          <td className="border-b border-slate-100 px-4 py-4 align-top">
                            <div className="flex items-center gap-2">
                              <button
                                type="button"
                                onClick={() => openDetailsModal(request.demandRequestId)}
                                className="inline-flex items-center gap-1 rounded-md border border-slate-200 px-3 py-2 text-xs font-medium text-slate-700 transition hover:bg-slate-50"
                              >
                                <EyeIcon className="h-4 w-4" />
                                View
                              </button>
                              <button
                                type="button"
                                onClick={() => handlePrintDemandRequest(request)}
                                className="inline-flex items-center gap-1 rounded-md border border-slate-200 px-3 py-2 text-xs font-medium text-emerald-700 transition hover:bg-emerald-50"
                                title="Print"
                              >
                                <PrinterIcon className="h-4 w-4" />
                                Print
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>

              <div className="flex flex-col gap-3 px-6 py-4 text-sm text-slate-600 md:flex-row md:items-center md:justify-between">
                <div>
                  Showing {showingFrom} to {showingTo} of {totalCount} entries
                </div>
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => setCurrentPage((page) => Math.max(page - 1, 1))}
                    disabled={currentPage === 1}
                    className="rounded-md border border-slate-200 px-3 py-2 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    Prev
                  </button>
                  <span>
                    {currentPage} / {totalPages}
                  </span>
                  <button
                    type="button"
                    onClick={() => setCurrentPage((page) => Math.min(page + 1, totalPages))}
                    disabled={currentPage === totalPages}
                    className="rounded-md border border-slate-200 px-3 py-2 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    Next
                  </button>
                </div>
              </div>
            </>
          )}
        </section>
      </div>

      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
          <div className="w-full max-w-[1800px] overflow-hidden rounded-xl bg-white shadow-2xl">
            <div className="border-b border-slate-200 px-6 py-4">
              <h3 className="text-2xl font-semibold text-slate-900">Place Demand</h3>
            </div>

            <form onSubmit={handleSubmit} className="px-4 py-5 sm:px-6">
              {formError && (
                <div className="mb-4 rounded-md border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
                  {formError}
                </div>
              )}

              <div className="grid grid-cols-1 gap-x-4 gap-y-6 lg:grid-cols-2">
                <BranchField label="Branch Request To" />

                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Requesting Store<span className="text-rose-500">*</span></label>
                  <select
                    name="requestingStoreId"
                    value={formData.requestingStoreId}
                    onChange={handleFormChange}
                    className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                    required
                  >
                    <option value="">Select store</option>
                    {lookups.stores
                      .filter((store) => String(store.storeId) !== String(formData.requestedStoreId))
                      .map((store) => (
                        <option key={store.storeId} value={store.storeId}>
                          {store.storeName}
                        </option>
                      ))}
                  </select>
                </div>

                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Store Request To<span className="text-rose-500">*</span></label>
                  <select
                    name="requestedStoreId"
                    value={formData.requestedStoreId}
                    onChange={handleFormChange}
                    className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                    required
                  >
                    <option value="">Select store</option>
                    {lookups.stores
                      .filter((store) => String(store.storeId) !== String(formData.requestingStoreId))
                      .map((store) => (
                        <option key={store.storeId} value={store.storeId}>
                          {store.storeName}
                        </option>
                      ))}
                  </select>
                </div>

                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Stock Type<span className="text-rose-500">*</span></label>
                  <select
                    name="stockTypeId"
                    value={formData.stockTypeId}
                    onChange={handleFormChange}
                    className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                    required
                  >
                    <option value="">Select stock type</option>
                    {lookups.stockTypes.map((stockType) => (
                      <option key={stockType.id} value={stockType.id}>
                        {stockType.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Item<span className="text-rose-500">*</span></label>
                  <select
                    value={productOptionValue(formData.items[0] || {})}
                    onChange={(event) => handleItemChange(0, 'itemId', event.target.value)}
                    className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                    required
                  >
                    <option value="">Search Item</option>
                    {lookups.items.map((lookupItem) => (
                      <option key={productOptionValue(lookupItem)} value={productOptionValue(lookupItem)}>
                        {lookupItem.sourceType === 'Item' ? lookupItem.name : `${lookupItem.name} (${lookupItem.sourceType})`}
                        {lookupItem.itemId != null ? ` - ${itemQuantities[lookupItem.itemId] ?? 0}` : ''}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="mb-2 block text-sm font-medium text-slate-700">Requested Quantity<span className="text-rose-500">*</span></label>
                  <input
                    type="number"
                    min="1"
                    value={formData.items[0]?.requestedQuantity || ''}
                    onChange={(event) => handleItemChange(0, 'requestedQuantity', event.target.value)}
                    className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                    required
                  />
                </div>
              </div>

              <div className="mt-6 flex justify-end gap-2 border-t border-slate-100 pt-5">
                <button
                  type="submit"
                  disabled={submitting}
                  className="rounded-md bg-indigo-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-70"
                >
                  {submitting ? 'Adding...' : 'Add'}
                </button>
                <button
                  type="button"
                  onClick={closeCreateModal}
                  className="rounded-md border border-slate-200 px-5 py-2.5 text-sm font-medium text-slate-700 transition hover:bg-slate-50"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {showDetailsModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
          <div className="max-h-[90vh] w-full max-w-4xl overflow-hidden rounded-2xl bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
              <div>
                <h3 className="text-lg font-semibold text-slate-900">Demand Request Details</h3>
                <p className="text-sm text-slate-500">View the full item breakdown for the selected request.</p>
              </div>
              <button type="button" onClick={closeDetailsModal} className="rounded-md p-2 text-slate-500 hover:bg-slate-100">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            <div className="max-h-[calc(90vh-72px)] overflow-y-auto px-6 py-5">
              {detailsLoading ? (
                <div className="text-sm text-slate-500">Loading request details...</div>
              ) : !selectedRequest ? (
                <div className="text-sm text-slate-500">Request details are unavailable.</div>
              ) : (
                <div className="space-y-5">
                  <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">DR-No.</div>
                      <div className="mt-1 font-semibold text-slate-900">{selectedRequest.drNo}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Indent No.</div>
                      <div className="mt-1 font-semibold text-slate-900">{selectedRequest.indentNo || '-'}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Requesting Store</div>
                      <div className="mt-1 font-semibold text-slate-900">{selectedRequest.requestingStoreName}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Requested Store</div>
                      <div className="mt-1 font-semibold text-slate-900">{selectedRequest.requestedStoreName}</div>
                    </div>
                  </div>

                  <div className="rounded-xl border border-slate-200">
                    <div className="border-b border-slate-200 px-4 py-3 text-sm font-semibold text-slate-800">Requested Items</div>
                    <div className="overflow-x-auto">
                      <table className="min-w-full text-sm">
                        <thead className="bg-slate-50 text-left text-slate-600">
                          <tr>
                            <th className="px-4 py-3 font-semibold">Item</th>
                            <th className="px-4 py-3 font-semibold">Requested Qty</th>
                            <th className="px-4 py-3 font-semibold">Approved Qty</th>
                            <th className="px-4 py-3 font-semibold">Issued Qty</th>
                            <th className="px-4 py-3 font-semibold">Remaining Qty</th>
                            <th className="px-4 py-3 font-semibold">Remarks</th>
                          </tr>
                        </thead>
                        <tbody>
                          {selectedRequest.items.map((item) => (
                            <tr key={item.id} className="border-t border-slate-100">
                              <td className="px-4 py-3">{item.itemName || 'Unassigned Item'}</td>
                              <td className="px-4 py-3">{item.requestedQuantity}</td>
                              <td className="px-4 py-3">{item.approvedQuantity ?? '-'}</td>
                              <td className="px-4 py-3">{item.issuedQuantity ?? '-'}</td>
                              <td className="px-4 py-3">{item.remainingQuantity ?? '-'}</td>
                              <td className="px-4 py-3">{item.remarks || '-'}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
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

export default PlaceDemandPage;