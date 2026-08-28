import React, { useEffect, useMemo, useState } from 'react';
import {
  ArrowDownTrayIcon,
  ClipboardDocumentListIcon,
  EyeIcon,
  InformationCircleIcon,
  PaperAirplaneIcon,
  PrinterIcon,
  QrCodeIcon,
  ShoppingCartIcon,
  Squares2X2Icon,
  XMarkIcon
} from '@heroicons/react/24/outline';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import JsBarcode from 'jsbarcode';
import demandRequestApi from '../services/demandRequestApi';
import { branchApi } from '../services/branchApi';
import { getAllStores } from '../services/storeApi';
import stockTypesApi from '../services/stockTypesApi';
import BranchField from '../components/BranchField';
import { useSession } from '../context/SessionContext';

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

function statusClasses(status) {
  switch ((status || '').toLowerCase()) {
    case 'pending':
      return 'text-amber-700';
    case 'approved':
      return 'text-emerald-700';
    case 'issued':
      return 'text-blue-700';
    case 'partial issued':
      return 'text-sky-700';
    case 'rejected':
      return 'text-rose-700';
    default:
      return 'text-slate-700';
  }
}

const ApprovedDemandsPage = ({ onGeneratePurchaseRequisition }) => {
  const { session } = useSession();
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [dispatchingId, setDispatchingId] = useState(null);
  const [showDispatchModal, setShowDispatchModal] = useState(false);
  const [dispatchTarget, setDispatchTarget] = useState(null);
  const [dispatchDetailsLoading, setDispatchDetailsLoading] = useState(false);
  const [dispatchItems, setDispatchItems] = useState([]);
  const [dispatchDriverName, setDispatchDriverName] = useState('');
  const [dispatchVehicleNumber, setDispatchVehicleNumber] = useState('');
  const [dispatchContactNumber, setDispatchContactNumber] = useState('');
  const [dispatchDetail, setDispatchDetail] = useState('');
  const [submittingDispatch, setSubmittingDispatch] = useState(false);
  const [dispatchError, setDispatchError] = useState('');
  const [entriesPerPage, setEntriesPerPage] = useState(5);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [detailsLoading, setDetailsLoading] = useState(false);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [lifeCycleEntries, setLifeCycleEntries] = useState([]);
  const [lifeCycleLoading, setLifeCycleLoading] = useState(false);
  const [showLifeCycleModal, setShowLifeCycleModal] = useState(false);
  const [lifeCycleRequest, setLifeCycleRequest] = useState(null);
  const [lifeCycleSearchTerm, setLifeCycleSearchTerm] = useState('');
  const [lifeCycleEntriesPerPage, setLifeCycleEntriesPerPage] = useState(10);
  const [lifeCyclePage, setLifeCyclePage] = useState(1);
  const [lookups, setLookups] = useState({
    branches: [],
    stores: [],
    stockTypes: []
  });
  const [filters, setFilters] = useState({
    branchId: '',
    requestedStoreId: '',
    stockTypeId: ''
  });

  useEffect(() => {
    loadLookups();
  }, []);

  // Branch filter is always scoped to the logged-in user's own branch.
  useEffect(() => {
    if (session?.branchId) {
      setFilters((current) => ({ ...current, branchId: session.branchId }));
    }
  }, [session?.branchId]);

  const loadLookups = async () => {
    try {
      const [branches, stores, stockTypes] = await Promise.all([
        branchApi.getAll(),
        getAllStores(),
        stockTypesApi.getAllStockTypes()
      ]);

      setLookups({ branches, stores, stockTypes });
    } catch (lookupError) {
      console.error('Error loading approved demand lookups:', lookupError);
      setError('Failed to load filter options.');
    }
  };

  // This page tracks a demand once it's been acted on (approved, dispatched - fully or
  // partially - and issued) through to receipt - not just the "Approved" status.
  const APPROVED_STATUSES = 'Approved,Partial Issued,Issued,Received';

  // Dispatching removes a row from this Approved/Partial-Issued list - that can leave the
  // current page number pointing past the end of the now-shorter result set, which the
  // backend legitimately answers with zero rows, making the table look "cleared" until
  // something resets the page (a hard refresh resets currentPage back to 1, which is why
  // that "fixes" it). Self-correct instead of requiring a refresh.
  const loadRequests = async (pageToLoad = currentPage) => {
    setLoading(true);
    setError('');

    try {
      const params = {
        statuses: APPROVED_STATUSES,
        branchId: filters.branchId || undefined,
        requestedStoreId: filters.requestedStoreId || undefined,
        stockTypeId: filters.stockTypeId || undefined,
        search: searchTerm.trim() || undefined,
        pageSize: entriesPerPage
      };
      let response = await demandRequestApi.getAll({ ...params, pageNumber: pageToLoad });

      if (response.items.length === 0 && response.totalCount > 0 && pageToLoad > 1) {
        const lastValidPage = Math.max(1, Math.ceil(response.totalCount / entriesPerPage));
        response = await demandRequestApi.getAll({ ...params, pageNumber: lastValidPage });
        setCurrentPage(lastValidPage);
      }

      setRequests(response.items);
      setTotalCount(response.totalCount);
    } catch (requestError) {
      console.error('Error loading approved demands:', requestError);
      setError('Failed to load approved demands.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadRequests();
  }, [entriesPerPage, currentPage, filters.branchId, filters.requestedStoreId, filters.stockTypeId, searchTerm]);

  useEffect(() => {
    setCurrentPage(1);
  }, [entriesPerPage, filters.branchId, filters.requestedStoreId, filters.stockTypeId, searchTerm]);

  const pageItems = requests;
  const totalPages = Math.max(1, Math.ceil(totalCount / entriesPerPage));
  const startIndex = (currentPage - 1) * entriesPerPage;

  const handleFilterChange = (event) => {
    const { name, value } = event.target;
    setFilters((current) => ({
      ...current,
      [name]: value
    }));
  };

  const exportCsv = async () => {
    let allRequests;
    try {
      const response = await demandRequestApi.getAll({
        statuses: APPROVED_STATUSES,
        branchId: filters.branchId || undefined,
        requestedStoreId: filters.requestedStoreId || undefined,
        stockTypeId: filters.stockTypeId || undefined,
        search: searchTerm.trim() || undefined,
        pageNumber: 1,
        pageSize: Math.max(totalCount, 1)
      });
      allRequests = response.items;
    } catch (exportError) {
      console.error('Error exporting approved demands:', exportError);
      setError('Failed to export approved demands.');
      return;
    }

    const rows = allRequests.map((request) => [
      `${request.drNo} / ${request.indentNo || ''}`,
      request.stockTypeName || '',
      request.requestingBranchName,
      request.itemSummary || '',
      formatDateTime(request.createdOn),
      request.status
    ]);

    const csv = [
      ['DR-NO. / INDENT NO.', 'Stock Type', 'Requesting Store', 'Items', 'Date & Time', 'Status'],
      ...rows
    ]
      .map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(','))
      .join('\n');

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'approved-demands.csv';
    link.click();
    URL.revokeObjectURL(url);
  };

  // Barcode of the DR number for the physical box being dispatched, plus a
  // timestamp and the page title, laid out exactly like the old system's
  // "Print Box Detail" printout. This is a separate action from "Print" below.
  const handlePrintBarcode = (request) => {
    const canvas = document.createElement('canvas');
    JsBarcode(canvas, request.drNo, { format: 'CODE128', displayValue: false, width: 2, height: 60, margin: 0 });

    const doc = new jsPDF();
    const pageWidth = doc.internal.pageSize.width;

    const now = new Date();
    const dateStr = now.toLocaleDateString('en-GB');
    const timeStr = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });

    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(0, 0, 0);
    doc.text(`${dateStr}, ${timeStr}`, 14, 16);

    doc.setTextColor(37, 99, 235);
    doc.text('Approved Demands', pageWidth - 14, 16, { align: 'right' });
    doc.setTextColor(0, 0, 0);

    const barcodeWidth = 90;
    const barcodeHeight = 30;
    doc.addImage(canvas.toDataURL('image/png'), 'PNG', (pageWidth - barcodeWidth) / 2, 30, barcodeWidth, barcodeHeight);

    doc.setFont('courier', 'bold');
    doc.setFontSize(13);
    doc.text(request.drNo, pageWidth / 2, 30 + barcodeHeight + 10, { align: 'center' });

    doc.save(`ApprovedDemand_Barcode_${request.drNo}.pdf`);
  };

  // "Print" in the old system - the full "Demand Request" report: RIC
  // letterhead, a DR-Number/Stock Type/Requested Date/Requested By/Request
  // Status/From Store/To Store/Approved Date/Issued Date header grid, an
  // items table with Requested/Approved/Issued/Remaining quantities, a Demand
  // Notes section, a Sign/Stamp/Name/Designation/Department/Date signature
  // block, and a "computer generated document" disclaimer footer.
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

  // Hands off to the full Purchase Requisition form (App.jsx switches sections),
  // pre-filled with this demand's items - replaces the old simplified modal that
  // created a Purchase Order directly.
  const handleGeneratePurchaseRequisition = async (request) => {
    if (!onGeneratePurchaseRequisition) return;

    try {
      const details = await demandRequestApi.getById(request.demandRequestId);
      onGeneratePurchaseRequisition({
        demandRequestId: request.demandRequestId,
        demandNo: request.drNo,
        storeId: request.requestedStoreId,
        subject: `Purchase Requisition for Demand ${request.drNo}`,
        items: details.items.map((item) => ({
          itemId: item.itemId,
          medicineId: item.medicineId,
          subServiceId: item.subServiceId,
          itemName: item.itemName || 'Unassigned Item',
          quantity: item.remainingQuantity || item.approvedQuantity || item.requestedQuantity || 1,
          unitEstimatedCost: 0,
          budgetHeadId: null,
          budgetHeadName: undefined,
          availableBudget: null,
          budgetRestriction: null,
          remarks: null
        }))
      });
    } catch (detailsError) {
      console.error('Error loading demand details for requisition:', detailsError);
      setError('Failed to load this demand\'s items.');
    }
  };

  // Issues stock for a demand sitting in "Approved" (or "Partial Issued", for a later
  // trip against what's still outstanding) - the actual dispatch step. Supports
  // dispatching less than the full approved quantity per item; only once every item is
  // fully issued does the demand move to "Issued" and become fully receivable.
  const openDispatchModal = async (request) => {
    setShowDispatchModal(true);
    setDispatchDetailsLoading(true);
    setDispatchTarget(request);
    setDispatchError('');
    setDispatchItems([]);

    try {
      const details = await demandRequestApi.getById(request.demandRequestId);
      setDispatchTarget(details);
      setDispatchDriverName(details.driverName || '');
      setDispatchVehicleNumber(details.vehicleNumber || '');
      setDispatchContactNumber(details.contactNumber || '');
      setDispatchDetail(details.detail || '');
      setDispatchItems(details.items.map((item) => {
        const remaining = item.remainingQuantity ?? Math.max((item.approvedQuantity ?? item.requestedQuantity) - (item.issuedQuantity ?? 0), 0);
        return {
          id: item.id,
          itemName: item.itemName || 'Unassigned Item',
          requestedQuantity: item.requestedQuantity,
          approvedQuantity: item.approvedQuantity ?? item.requestedQuantity,
          issuedQuantity: item.issuedQuantity ?? 0,
          availableQuantityInRequestedStore: item.availableQuantityInRequestedStore ?? 0,
          remainingQuantity: remaining,
          remarks: item.remarks || '',
          issuingQuantity: remaining
        };
      }));
    } catch (detailsError) {
      console.error('Error loading demand details for dispatch:', detailsError);
      setDispatchTarget(null);
      setDispatchError('Failed to load demand details.');
    } finally {
      setDispatchDetailsLoading(false);
    }
  };

  const closeDispatchModal = () => {
    setShowDispatchModal(false);
    setDispatchTarget(null);
    setDispatchItems([]);
    setDispatchDriverName('');
    setDispatchVehicleNumber('');
    setDispatchContactNumber('');
    setDispatchDetail('');
    setDispatchError('');
  };

  const updateDispatchItemQuantity = (itemId, rawValue) => {
    setDispatchItems((current) => current.map((item) => {
      if (item.id !== itemId) {
        return item;
      }

      const parsed = Number(rawValue);
      const clamped = Number.isFinite(parsed) ? Math.max(0, Math.min(parsed, item.remainingQuantity)) : 0;
      return { ...item, issuingQuantity: clamped };
    }));
  };

  const handleDispatchSubmit = async () => {
    if (!dispatchTarget) {
      return;
    }

    const itemsToDispatch = dispatchItems.filter((item) => item.issuingQuantity > 0);

    if (itemsToDispatch.length === 0) {
      setDispatchError('Enter an issuing quantity for at least one item.');
      return;
    }

    setSubmittingDispatch(true);
    setDispatchError('');
    setDispatchingId(dispatchTarget.demandRequestId);

    try {
      await demandRequestApi.dispatch(dispatchTarget.demandRequestId, {
        driverName: dispatchDriverName || null,
        vehicleNumber: dispatchVehicleNumber || null,
        contactNumber: dispatchContactNumber || null,
        detail: dispatchDetail || null,
        items: itemsToDispatch.map((item) => ({ id: item.id, issuingQuantity: item.issuingQuantity }))
      });
      closeDispatchModal();
      await loadRequests();
    } catch (dispatchSubmitError) {
      console.error('Error dispatching demand request:', dispatchSubmitError);
      setDispatchError(dispatchSubmitError.response?.data?.message || 'Failed to dispatch this demand.');
    } finally {
      setSubmittingDispatch(false);
      setDispatchingId(null);
    }
  };

  const openDetailsModal = async (requestId) => {
    setShowDetailsModal(true);
    setDetailsLoading(true);

    try {
      const details = await demandRequestApi.getById(requestId);
      setSelectedRequest(details);
    } catch (detailsError) {
      console.error('Error loading approved demand details:', detailsError);
      setSelectedRequest(null);
      setError('Failed to load demand details.');
    } finally {
      setDetailsLoading(false);
    }
  };

  const closeDetailsModal = () => {
    setShowDetailsModal(false);
    setSelectedRequest(null);
  };

  const openLifeCycleModal = async (request) => {
    setShowLifeCycleModal(true);
    setLifeCycleLoading(true);
    setLifeCycleRequest(request);
    setLifeCycleSearchTerm('');
    setLifeCyclePage(1);

    try {
      const entries = await demandRequestApi.getLifeCycle(request.demandRequestId);
      setLifeCycleEntries(entries);
    } catch (lifeCycleError) {
      console.error('Error loading demand life cycle:', lifeCycleError);
      setLifeCycleEntries([]);
      setError('Failed to load demand life cycle.');
    } finally {
      setLifeCycleLoading(false);
    }
  };

  const closeLifeCycleModal = () => {
    setShowLifeCycleModal(false);
    setLifeCycleEntries([]);
    setLifeCycleRequest(null);
    setLifeCycleSearchTerm('');
    setLifeCyclePage(1);
  };

  const filteredLifeCycleEntries = useMemo(() => {
    const normalizedSearch = lifeCycleSearchTerm.trim().toLowerCase();

    if (!normalizedSearch) {
      return lifeCycleEntries;
    }

    return lifeCycleEntries.filter((entry) => [entry.status, entry.actionBy, formatDateTime(entry.createdOn)]
      .some((value) => (value || '').toLowerCase().includes(normalizedSearch)));
  }, [lifeCycleEntries, lifeCycleSearchTerm]);

  useEffect(() => {
    setLifeCyclePage(1);
  }, [lifeCycleEntriesPerPage, lifeCycleSearchTerm, showLifeCycleModal]);

  const lifeCycleTotalPages = Math.max(1, Math.ceil(filteredLifeCycleEntries.length / lifeCycleEntriesPerPage));
  const lifeCycleStartIndex = (lifeCyclePage - 1) * lifeCycleEntriesPerPage;
  const currentLifeCycleEntries = filteredLifeCycleEntries.slice(lifeCycleStartIndex, lifeCycleStartIndex + lifeCycleEntriesPerPage);
  const lifeCycleShowingFrom = filteredLifeCycleEntries.length === 0 ? 0 : lifeCycleStartIndex + 1;
  const lifeCycleShowingTo = Math.min(lifeCycleStartIndex + lifeCycleEntriesPerPage, filteredLifeCycleEntries.length);

  const showingFrom = totalCount === 0 ? 0 : startIndex + 1;
  const showingTo = Math.min(startIndex + entriesPerPage, totalCount);

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-6 py-3">
            <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
              Approved Demands
              <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
            </h1>
          </div>

          <div className="grid grid-cols-1 gap-x-4 gap-y-6 px-6 py-5 lg:grid-cols-2">
            {/* Branch - locked to the logged-in user's own branch */}
            <BranchField />

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Store</label>
              <select
                name="requestedStoreId"
                value={filters.requestedStoreId}
                onChange={handleFilterChange}
                className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              >
                <option value="">All</option>
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
                value={filters.stockTypeId}
                onChange={handleFilterChange}
                className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
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

        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="flex flex-col gap-4 border-b border-slate-100 px-4 py-3 lg:flex-row lg:items-center lg:justify-between">
            <h2 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
              <ClipboardDocumentListIcon className="h-5 w-5 text-indigo-500" />
              Approved Demands
            </h2>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={exportCsv}
                className="inline-flex items-center gap-2 rounded-md border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50"
              >
                <ArrowDownTrayIcon className="h-4 w-4 text-indigo-500" />
                Export
              </button>
            </div>
          </div>

          <div className="flex flex-col gap-3 px-4 py-4 md:flex-row md:items-center md:justify-between">
            <div className="flex items-center gap-2 text-sm text-slate-600">
              <span>Show</span>
              <select
                value={entriesPerPage}
                onChange={(event) => setEntriesPerPage(Number(event.target.value))}
                className="rounded-md border border-slate-200 px-2 py-1 text-sm"
              >
                {[5, 10, 25, 50].map((size) => (
                  <option key={size} value={size}>{size}</option>
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
            <div className="px-4 pb-4 text-sm text-rose-600">{error}</div>
          ) : loading ? (
            <div className="px-4 pb-4 text-sm text-slate-500">Loading approved demands...</div>
          ) : (
            <>
              <div className="overflow-x-auto px-4">
                <table className="min-w-full border-separate border-spacing-0 text-sm">
                  <thead>
                    <tr className="text-left text-slate-700">
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">DR-NO. / Indent NO.</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Stock Type</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Requesting Store</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Items</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Date &amp; Time</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Status</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    {pageItems.length === 0 ? (
                      <tr>
                        <td colSpan="7" className="border-b border-slate-200 px-4 py-12 text-center text-slate-500">
                          No data available in table
                        </td>
                      </tr>
                    ) : (
                      pageItems.map((request) => (
                        <tr key={request.demandRequestId} className="text-slate-700">
                          <td className="border-b border-slate-200 px-6 py-8 align-middle text-center">
                            <div className="text-base text-sky-700">{request.drNo} /</div>
                            <div className="text-base text-slate-700">{request.indentNo || '-'}</div>
                          </td>
                          <td className="border-b border-slate-200 px-6 py-8 align-middle">{request.stockTypeName || 'All'}</td>
                          <td className="border-b border-slate-200 px-6 py-8 align-middle">{request.requestingStoreName}</td>
                          <td className="border-b border-slate-200 px-6 py-8 align-middle">
                            <div className="max-w-[620px] truncate" title={request.itemSummary || ''}>
                              {request.itemSummary || `${request.itemsCount} item${request.itemsCount === 1 ? '' : 's'}`}
                            </div>
                          </td>
                          <td className="border-b border-slate-200 px-6 py-8 align-middle">{formatDateTime(request.createdOn)}</td>
                          <td className={`border-b border-slate-200 px-6 py-8 align-middle font-medium ${statusClasses(request.status)}`}>
                            {request.status}
                          </td>
                          <td className="border-b border-slate-200 px-6 py-8 align-middle">
                            <div className="flex flex-col items-center gap-3 text-indigo-400">
                              {['approved', 'partial issued'].includes((request.status || '').toLowerCase()) && (
                                <button
                                  type="button"
                                  onClick={() => openDispatchModal(request)}
                                  disabled={dispatchingId === request.demandRequestId}
                                  className="text-indigo-600 transition hover:text-indigo-800 disabled:cursor-not-allowed disabled:opacity-50"
                                  title="Dispatch (Issue Stock)"
                                >
                                  <PaperAirplaneIcon className="h-5 w-5" />
                                </button>
                              )}
                              <button
                                type="button"
                                onClick={() => handlePrintDemandRequest(request)}
                                className="text-emerald-600 transition hover:text-emerald-700"
                                title="Print"
                              >
                                <PrinterIcon className="h-5 w-5" />
                              </button>
                              <button
                                type="button"
                                onClick={() => handlePrintBarcode(request)}
                                className="text-slate-600 transition hover:text-slate-800"
                                title="Print Box Detail (Barcode)"
                              >
                                <QrCodeIcon className="h-5 w-5" />
                              </button>
                              <button
                                type="button"
                                onClick={() => openDetailsModal(request.demandRequestId)}
                                className="transition hover:text-indigo-600"
                                title="View Report"
                              >
                                <EyeIcon className="h-5 w-5" />
                              </button>
                              <button
                                type="button"
                                onClick={() => openLifeCycleModal(request)}
                                className="transition hover:text-indigo-600"
                                title="Life Cycle"
                              >
                                <Squares2X2Icon className="h-5 w-5" />
                              </button>
                              <button
                                type="button"
                                onClick={() => handleGeneratePurchaseRequisition(request)}
                                className="text-orange-600 transition hover:text-orange-700"
                                title="Generate Purchase Requisition"
                              >
                                <ShoppingCartIcon className="h-5 w-5" />
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                  <tfoot>
                    <tr className="text-left text-slate-700">
                      <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">DR-NO. / Indent NO.</th>
                      <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Stock Type</th>
                      <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Requesting Store</th>
                      <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Items</th>
                      <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Date &amp; Time</th>
                      <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Status</th>
                      <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Action</th>
                    </tr>
                  </tfoot>
                </table>
              </div>

              <div className="flex flex-col gap-3 px-4 py-4 text-sm text-slate-600 md:flex-row md:items-center md:justify-between">
                <div>Showing {showingFrom} to {showingTo} of {totalCount} entries</div>
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => setCurrentPage((page) => Math.max(page - 1, 1))}
                    disabled={currentPage === 1}
                    className="rounded-md border border-slate-200 px-3 py-2 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    ‹
                  </button>
                  <span className="rounded-md bg-indigo-600 px-3 py-2 text-white">{currentPage}</span>
                  <button
                    type="button"
                    onClick={() => setCurrentPage((page) => Math.min(page + 1, totalPages))}
                    disabled={currentPage === totalPages}
                    className="rounded-md border border-slate-200 px-3 py-2 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    ›
                  </button>
                </div>
              </div>
            </>
          )}
        </section>
      </div>

      {showDetailsModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
          <div className="max-h-[90vh] w-full max-w-4xl overflow-hidden rounded-2xl bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
              <div>
                <h3 className="text-lg font-semibold text-slate-900">Approved Demand Details</h3>
                <p className="text-sm text-slate-500">Review the demand header and requested items.</p>
              </div>
              <button type="button" onClick={closeDetailsModal} className="rounded-md p-2 text-slate-500 hover:bg-slate-100">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            <div className="max-h-[calc(90vh-72px)] overflow-y-auto px-6 py-5">
              {detailsLoading ? (
                <div className="text-sm text-slate-500">Loading demand details...</div>
              ) : !selectedRequest ? (
                <div className="text-sm text-slate-500">Demand details are unavailable.</div>
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
                      <div className="text-xs uppercase tracking-wide text-slate-500">Branch</div>
                      <div className="mt-1 font-semibold text-slate-900">{selectedRequest.requestingBranchName}</div>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-4">
                      <div className="text-xs uppercase tracking-wide text-slate-500">Store</div>
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

      {showDispatchModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
          <div className="max-h-[92vh] w-full max-w-6xl overflow-hidden rounded-md bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
              <h3 className="text-lg font-semibold text-slate-900">
                Dispatch Stock {dispatchTarget?.drNo ? `- ${dispatchTarget.drNo}` : ''}
              </h3>
              <button type="button" onClick={closeDispatchModal} className="rounded-md p-2 text-slate-500 hover:bg-slate-100">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            <div className="max-h-[calc(92vh-72px)] overflow-y-auto px-6 py-5">
              {dispatchDetailsLoading ? (
                <div className="text-sm text-slate-500">Loading demand details...</div>
              ) : !dispatchTarget ? (
                <div className="text-sm text-slate-500">Demand details are unavailable.</div>
              ) : (
                <div className="space-y-6">
                  {dispatchError && (
                    <div className="rounded-md bg-rose-50 px-4 py-3 text-sm text-rose-700">{dispatchError}</div>
                  )}

                  <div className="grid grid-cols-1 gap-x-10 gap-y-4 lg:grid-cols-2">
                    <div className="space-y-4">
                      <div className="grid grid-cols-[160px_1fr] gap-2">
                        <div className="font-semibold text-slate-900">Requesting Store:</div>
                        <div className="text-slate-800">{dispatchTarget.requestingStoreName || '-'}</div>
                      </div>
                      <div className="grid grid-cols-[160px_1fr] gap-2">
                        <div className="font-semibold text-slate-900">Indent Number:</div>
                        <div className="text-slate-800">{dispatchTarget.indentNo || '-'}</div>
                      </div>
                      <div className="grid grid-cols-[160px_1fr] gap-2">
                        <div className="font-semibold text-slate-900">Demand Notes:</div>
                        <div className="text-slate-800">{dispatchTarget.remarks || '-'}</div>
                      </div>
                      <label className="grid grid-cols-[160px_1fr] items-center gap-2">
                        <span className="font-semibold text-slate-900">Delivery Person:</span>
                        <input
                          type="text"
                          value={dispatchDriverName}
                          onChange={(event) => setDispatchDriverName(event.target.value)}
                          placeholder="Enter Delivery Person Name"
                          className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400"
                        />
                      </label>
                      <label className="grid grid-cols-[160px_1fr] items-center gap-2">
                        <span className="font-semibold text-slate-900">Contact No:</span>
                        <input
                          type="text"
                          value={dispatchContactNumber}
                          onChange={(event) => setDispatchContactNumber(event.target.value)}
                          placeholder="Enter Contact Number"
                          className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400"
                        />
                      </label>
                    </div>

                    <div className="space-y-4">
                      <div className="grid grid-cols-[160px_1fr] gap-2">
                        <div className="font-semibold text-slate-900">Requested Store:</div>
                        <div className="text-slate-800">{dispatchTarget.requestedStoreName || '-'}</div>
                      </div>
                      <div className="grid grid-cols-[160px_1fr] gap-2">
                        <div className="font-semibold text-slate-900">Stock Type:</div>
                        <div className="text-slate-800">{dispatchTarget.stockTypeName || 'All'}</div>
                      </div>
                      <label className="grid grid-cols-[160px_1fr] items-center gap-2">
                        <span className="font-semibold text-slate-900">Vehicle No:</span>
                        <input
                          type="text"
                          value={dispatchVehicleNumber}
                          onChange={(event) => setDispatchVehicleNumber(event.target.value)}
                          placeholder="Enter Vehicle Number"
                          className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400"
                        />
                      </label>
                      <label className="grid grid-cols-[160px_1fr] items-start gap-2">
                        <span className="pt-2 font-semibold text-slate-900">Detail:</span>
                        <textarea
                          value={dispatchDetail}
                          onChange={(event) => setDispatchDetail(event.target.value)}
                          placeholder="Enter Detail"
                          rows={2}
                          className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400"
                        />
                      </label>
                    </div>
                  </div>

                  <div className="overflow-x-auto border border-slate-200">
                    <table className="min-w-full text-sm">
                      <thead>
                        <tr className="bg-slate-50 text-slate-900">
                          <th className="border-b border-r border-slate-200 px-3 py-3 text-center font-semibold">Sr#</th>
                          <th className="border-b border-r border-slate-200 px-3 py-3 text-left font-semibold">Items</th>
                          <th className="border-b border-r border-slate-200 px-3 py-3 text-center font-semibold">Requested Qty</th>
                          <th className="border-b border-r border-slate-200 px-3 py-3 text-center font-semibold">Approved Qty</th>
                          <th className="border-b border-r border-slate-200 px-3 py-3 text-center font-semibold">Available Qty</th>
                          <th className="border-b border-r border-slate-200 px-3 py-3 text-center font-semibold">Issued Qty</th>
                          <th className="border-b border-r border-slate-200 px-3 py-3 text-center font-semibold">Remaining Qty</th>
                          <th className="border-b border-slate-200 px-3 py-3 text-center font-semibold">Issuing Quantity</th>
                        </tr>
                      </thead>
                      <tbody>
                        {dispatchItems.map((item, index) => (
                          <tr key={item.id} className="odd:bg-slate-50/60">
                            <td className="border-b border-r border-slate-200 px-3 py-3 text-center">{index + 1}</td>
                            <td className="border-b border-r border-slate-200 px-3 py-3">{item.itemName}</td>
                            <td className="border-b border-r border-slate-200 px-3 py-3 text-center">{item.requestedQuantity}</td>
                            <td className="border-b border-r border-slate-200 px-3 py-3 text-center">{item.approvedQuantity}</td>
                            <td className="border-b border-r border-slate-200 px-3 py-3 text-center">{item.availableQuantityInRequestedStore}</td>
                            <td className="border-b border-r border-slate-200 px-3 py-3 text-center">{item.issuedQuantity}</td>
                            <td className="border-b border-r border-slate-200 px-3 py-3 text-center">{item.remainingQuantity}</td>
                            <td className="border-b border-slate-200 px-3 py-3 text-center">
                              <input
                                type="number"
                                min={0}
                                max={item.remainingQuantity}
                                value={item.issuingQuantity}
                                disabled={item.remainingQuantity <= 0}
                                onChange={(event) => updateDispatchItemQuantity(item.id, event.target.value)}
                                className="w-24 rounded-md border border-slate-200 px-2 py-1 text-center text-sm outline-none transition focus:border-indigo-400 disabled:bg-slate-100"
                              />
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  <div className="flex justify-end">
                    <button
                      type="button"
                      onClick={handleDispatchSubmit}
                      disabled={submittingDispatch}
                      className="rounded-md bg-indigo-600 px-6 py-3 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                      {submittingDispatch ? 'Dispatching...' : 'Dispatch Stock'}
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {showLifeCycleModal && (
        <div className="fixed inset-0 z-[60] flex items-start justify-center bg-slate-900/40 p-4 pt-6">
          <div className="w-full max-w-7xl overflow-hidden rounded-md border border-slate-200 bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
              <div>
                <h3 className="text-[18px] font-medium text-slate-700">Demand Life Cycle</h3>
                {lifeCycleRequest && (
                  <p className="text-sm text-slate-500">{lifeCycleRequest.drNo} / {lifeCycleRequest.indentNo || '-'}</p>
                )}
              </div>
              <button type="button" onClick={closeLifeCycleModal} className="rounded-md p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            <div className="px-6 py-4">
              <div className="mb-5 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
                <div className="flex items-center gap-2 text-sm text-slate-700">
                  <span>Show</span>
                  <select
                    value={lifeCycleEntriesPerPage}
                    onChange={(event) => setLifeCycleEntriesPerPage(Number(event.target.value))}
                    className="rounded-md border border-slate-200 px-3 py-2 text-sm outline-none"
                  >
                    {[10, 25, 50].map((size) => (
                      <option key={size} value={size}>{size}</option>
                    ))}
                  </select>
                  <span>entries</span>
                </div>

                <label className="flex items-center gap-2 text-sm text-slate-700">
                  <span>Search:</span>
                  <input
                    type="text"
                    value={lifeCycleSearchTerm}
                    onChange={(event) => setLifeCycleSearchTerm(event.target.value)}
                    className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400 md:w-56"
                  />
                </label>
              </div>

              <div className="overflow-x-auto border border-slate-200">
                <table className="min-w-full text-sm">
                  <thead>
                    <tr className="bg-white text-slate-900">
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Status</th>
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Action By</th>
                      <th className="border-b border-slate-200 px-6 py-4 text-center font-semibold">Date</th>
                    </tr>
                  </thead>
                  <tbody>
                    {lifeCycleLoading ? (
                      <tr>
                        <td colSpan="3" className="px-6 py-10 text-center text-slate-500">Loading demand life cycle...</td>
                      </tr>
                    ) : currentLifeCycleEntries.length === 0 ? (
                      <tr>
                        <td colSpan="3" className="px-6 py-10 text-center text-slate-500">No lifecycle entries found.</td>
                      </tr>
                    ) : (
                      currentLifeCycleEntries.map((entry) => (
                        <tr key={entry.id} className="odd:bg-slate-50/60">
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-center text-base text-slate-700">{entry.status}</td>
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-center text-base text-slate-700">{entry.actionBy}</td>
                          <td className="border-b border-slate-200 px-6 py-4 text-center text-base text-slate-700">{formatDateTime(entry.createdOn)}</td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>

              <div className="mt-5 flex flex-col gap-3 text-sm text-slate-600 md:flex-row md:items-center md:justify-between">
                <div>Showing {lifeCycleShowingFrom} to {lifeCycleShowingTo} of {filteredLifeCycleEntries.length} entries</div>
                <div className="flex items-center gap-1.5">
                  <button
                    type="button"
                    onClick={() => setLifeCyclePage((page) => Math.max(page - 1, 1))}
                    disabled={lifeCyclePage === 1}
                    className="rounded bg-slate-100 px-3 py-2 text-slate-500 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    ‹
                  </button>
                  <span className="rounded bg-indigo-500 px-3 py-2 text-white">{lifeCyclePage}</span>
                  <button
                    type="button"
                    onClick={() => setLifeCyclePage((page) => Math.min(page + 1, lifeCycleTotalPages))}
                    disabled={lifeCyclePage === lifeCycleTotalPages}
                    className="rounded bg-slate-100 px-3 py-2 text-slate-500 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    ›
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ApprovedDemandsPage;