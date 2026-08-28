import React, { useEffect, useMemo, useState } from 'react';
import {
  ArrowDownTrayIcon,
  ClipboardDocumentListIcon,
  EyeIcon,
  InformationCircleIcon,
  PencilSquareIcon,
  PrinterIcon,
  Squares2X2Icon,
  XMarkIcon
} from '@heroicons/react/24/outline';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import demandRequestApi from '../services/demandRequestApi';
import { branchApi } from '../services/branchApi';
import { getAllStores } from '../services/storeApi';
import stockTypesApi from '../services/stockTypesApi';
import itemApi from '../services/itemApi';
import transferInventoryApi from '../services/transferInventoryApi';
import BranchField from '../components/BranchField';
import { useSession } from '../context/SessionContext';
import { productOptionValue, parseProductOptionValue, findProductRow } from '../utils/productKey';

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
    case 'rejected':
      return 'text-rose-700';
    default:
      return 'text-slate-700';
  }
}

const PendingDemandsPage = () => {
  const { session } = useSession();
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
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
    stockTypes: [],
    items: []
  });
  const [filters, setFilters] = useState({
    branchId: '',
    requestedStoreId: '',
    stockTypeId: ''
  });

  // Update Demand modal (edit / approve / reject a pending demand)
  const [showUpdateModal, setShowUpdateModal] = useState(false);
  const [updateLoading, setUpdateLoading] = useState(false);
  const [updateSubmitting, setUpdateSubmitting] = useState(false);
  const [updateRequest, setUpdateRequest] = useState(null);
  const [updateIndentNo, setUpdateIndentNo] = useState('');
  const [updateDemandNotes, setUpdateDemandNotes] = useState('');
  const [updateItems, setUpdateItems] = useState([]);
  const [updateSearchTerm, setUpdateSearchTerm] = useState('');
  const [newItemId, setNewItemId] = useState('');
  const [newItemQuantity, setNewItemQuantity] = useState('');

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
      const [branches, stores, stockTypes, items] = await Promise.all([
        branchApi.getAll(),
        getAllStores(),
        stockTypesApi.getAllStockTypes(),
        itemApi.getAllWithMedicines()
      ]);

      setLookups({ branches, stores, stockTypes, items });
    } catch (lookupError) {
      console.error('Error loading pending demand lookups:', lookupError);
      setError('Failed to load filter options.');
    }
  };

  // Approving/rejecting removes a row from this Pending list - that can leave the current
  // page number pointing past the end of the now-shorter result set, which the backend
  // legitimately answers with zero rows, making the table look "cleared" until something
  // resets the page (a hard refresh resets currentPage back to 1, which is why that
  // "fixes" it). Self-correct instead of requiring a refresh.
  const loadRequests = async (pageToLoad = currentPage) => {
    setLoading(true);
    setError('');

    try {
      const params = {
        statuses: 'Pending',
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
      console.error('Error loading pending demands:', requestError);
      setError('Failed to load pending demands.');
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
        statuses: 'Pending',
        branchId: filters.branchId || undefined,
        requestedStoreId: filters.requestedStoreId || undefined,
        stockTypeId: filters.stockTypeId || undefined,
        search: searchTerm.trim() || undefined,
        pageNumber: 1,
        pageSize: Math.max(totalCount, 1)
      });
      allRequests = response.items;
    } catch (exportError) {
      console.error('Error exporting pending demands:', exportError);
      setError('Failed to export pending demands.');
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
    link.download = 'pending-demands.csv';
    link.click();
    URL.revokeObjectURL(url);
  };

  // "Print" - the full "Demand Request" report: RIC letterhead, a DR-Number/Stock
  // Type/Requested Date/Requested By/Request Status/From Store/To Store/Approved
  // Date/Issued Date header grid, an items table with Requested/Approved/Issued/
  // Remaining quantities, a Demand Notes section, a Sign/Stamp/Name/Designation/
  // Department/Date signature block, and a "computer generated document" footer.
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

  const openDetailsModal = async (requestId) => {
    setShowDetailsModal(true);
    setDetailsLoading(true);

    try {
      const details = await demandRequestApi.getById(requestId);
      setSelectedRequest(details);
    } catch (detailsError) {
      console.error('Error loading pending demand details:', detailsError);
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

  const openUpdateModal = async (requestId) => {
    setShowUpdateModal(true);
    setUpdateLoading(true);
    setUpdateSearchTerm('');
    setNewItemId('');
    setNewItemQuantity('');

    try {
      const details = await demandRequestApi.getById(requestId);
      setUpdateRequest(details);
      setUpdateIndentNo(details.indentNo || '');
      setUpdateDemandNotes(details.remarks || '');
      setUpdateItems(details.items.map((item) => ({
        id: item.id,
        itemId: item.itemId,
        medicineId: item.medicineId,
        subServiceId: item.subServiceId,
        itemName: item.itemName || 'Unassigned Item',
        availableInRequestingStore: item.availableQuantityInRequestingStore,
        requestedQuantity: item.requestedQuantity,
        availableInRequestedStore: item.availableQuantityInRequestedStore,
        approvedQuantity: item.approvedQuantity ?? item.requestedQuantity,
        remarks: item.remarks || ''
      })));
    } catch (updateError) {
      console.error('Error loading demand for update:', updateError);
      setUpdateRequest(null);
      setError('Failed to load demand details.');
    } finally {
      setUpdateLoading(false);
    }
  };

  const closeUpdateModal = () => {
    setShowUpdateModal(false);
    setUpdateSubmitting(false);
    setUpdateRequest(null);
    setUpdateItems([]);
    setUpdateIndentNo('');
    setUpdateDemandNotes('');
    setUpdateSearchTerm('');
    setNewItemId('');
    setNewItemQuantity('');
  };

  const handleApprovedQuantityChange = (index, value) => {
    setUpdateItems((current) => current.map((item, itemIndex) => (
      itemIndex === index ? { ...item, approvedQuantity: value } : item
    )));
  };

  const handleItemRemarksChange = (index, value) => {
    setUpdateItems((current) => current.map((item, itemIndex) => (
      itemIndex === index ? { ...item, remarks: value } : item
    )));
  };

  const handleAddItem = async () => {
    if (!newItemId || !newItemQuantity || Number(newItemQuantity) <= 0) {
      alert('Select an item and enter a requested quantity.');
      return;
    }

    const newProduct = parseProductOptionValue(newItemId);

    if (updateItems.some((item) =>
      (newProduct.itemId != null && item.itemId === newProduct.itemId) ||
      (newProduct.medicineId != null && item.medicineId === newProduct.medicineId) ||
      (newProduct.subServiceId != null && item.subServiceId === newProduct.subServiceId)
    )) {
      alert('This item is already part of the demand.');
      return;
    }

    const item = findProductRow(lookups.items, newProduct);
    const quantity = Number(newItemQuantity);

    let availableInRequestingStore = 0;
    let availableInRequestedStore = 0;

    // transferInventoryApi.getAvailableQuantity only supports a real ItemId - Medicine/
    // Disposable rows show 0 available here until that endpoint is extended.
    if (newProduct.itemId) {
      try {
        [availableInRequestingStore, availableInRequestedStore] = await Promise.all([
          updateRequest?.requestingStoreId
            ? transferInventoryApi.getAvailableQuantity(updateRequest.requestingStoreId, newProduct.itemId)
            : Promise.resolve(0),
          transferInventoryApi.getAvailableQuantity(updateRequest.requestedStoreId, newProduct.itemId)
        ]);
      } catch (availabilityError) {
        console.error('Error loading available quantity for new item:', availabilityError);
      }
    }

    setUpdateItems((current) => [
      ...current,
      {
        id: null,
        itemId: newProduct.itemId,
        medicineId: newProduct.medicineId,
        subServiceId: newProduct.subServiceId,
        itemName: item?.name || 'Unassigned Item',
        availableInRequestingStore,
        requestedQuantity: quantity,
        availableInRequestedStore,
        approvedQuantity: quantity,
        remarks: ''
      }
    ]);

    setNewItemId('');
    setNewItemQuantity('');
  };

  const handleCancelAddItem = () => {
    setNewItemId('');
    setNewItemQuantity('');
  };

  const buildUpdatePayload = () => ({
    indentNo: updateIndentNo || null,
    demandNotes: updateDemandNotes || null,
    items: updateItems.map((item) => ({
      id: item.id || null,
      itemId: item.itemId || null,
      medicineId: item.medicineId || null,
      subServiceId: item.subServiceId || null,
      requestedQuantity: item.requestedQuantity,
      approvedQuantity: Number(item.approvedQuantity) || 0,
      remarks: item.remarks || null
    }))
  });

  const handleSaveUpdate = async () => {
    if (!updateRequest) {
      return;
    }

    setUpdateSubmitting(true);

    try {
      await demandRequestApi.update(updateRequest.demandRequestId, buildUpdatePayload());
      closeUpdateModal();
      await loadRequests();
    } catch (saveError) {
      console.error('Error saving demand request:', saveError);
      alert(saveError.response?.data?.message || 'Failed to save demand request.');
      setUpdateSubmitting(false);
    }
  };

  const handleApprove = async () => {
    if (!updateRequest) {
      return;
    }

    setUpdateSubmitting(true);

    try {
      await demandRequestApi.approve(updateRequest.demandRequestId, buildUpdatePayload());
      closeUpdateModal();
      await loadRequests();
    } catch (approveError) {
      console.error('Error approving demand request:', approveError);
      alert(approveError.response?.data?.message || 'Failed to approve demand request.');
      setUpdateSubmitting(false);
    }
  };

  const handleReject = async () => {
    if (!updateRequest) {
      return;
    }

    setUpdateSubmitting(true);

    try {
      await demandRequestApi.reject(updateRequest.demandRequestId, { remarks: updateDemandNotes || null });
      closeUpdateModal();
      await loadRequests();
    } catch (rejectError) {
      console.error('Error rejecting demand request:', rejectError);
      alert(rejectError.response?.data?.message || 'Failed to reject demand request.');
      setUpdateSubmitting(false);
    }
  };

  const filteredUpdateItems = useMemo(() => {
    const normalizedSearch = updateSearchTerm.trim().toLowerCase();

    if (!normalizedSearch) {
      return updateItems;
    }

    return updateItems.filter((item) => (item.itemName || '').toLowerCase().includes(normalizedSearch));
  }, [updateItems, updateSearchTerm]);

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
              Pending Demands
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
              Pending Demands
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
            <div className="px-4 pb-4 text-sm text-slate-500">Loading pending demands...</div>
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
                              <button
                                type="button"
                                onClick={() => openUpdateModal(request.demandRequestId)}
                                className="transition hover:text-indigo-600"
                                title="Edit"
                              >
                                <PencilSquareIcon className="h-5 w-5" />
                              </button>
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
                                onClick={() => openLifeCycleModal(request)}
                                className="transition hover:text-indigo-600"
                                title="Demand Life Cycle"
                              >
                                <Squares2X2Icon className="h-5 w-5" />
                              </button>
                              <button
                                type="button"
                                onClick={() => openDetailsModal(request.demandRequestId)}
                                className="transition hover:text-indigo-600"
                                title="Open"
                              >
                                <EyeIcon className="h-5 w-5" />
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
                <h3 className="text-lg font-semibold text-slate-900">Pending Demand Details</h3>
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

      {showUpdateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
          <div className="max-h-[90vh] w-full max-w-7xl overflow-hidden rounded-md bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
              <h3 className="text-xl font-medium text-slate-700">Update Demand</h3>
              <button type="button" onClick={closeUpdateModal} className="rounded-md p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            <div className="max-h-[calc(90vh-72px)] overflow-y-auto px-6 py-5">
              {updateLoading ? (
                <div className="text-sm text-slate-500">Loading demand...</div>
              ) : !updateRequest ? (
                <div className="text-sm text-slate-500">Demand details are unavailable.</div>
              ) : (
                <div className="space-y-5">
                  <div>
                    <span className="text-base font-semibold text-slate-900">Demand Request No. </span>
                    <span className="rounded bg-rose-600 px-2 py-1 text-base font-semibold text-white">{updateRequest.drNo}</span>
                  </div>

                  <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
                    <div>
                      <label className="mb-2 block text-sm font-medium text-slate-700">Stock Type<span className="text-rose-500">*</span></label>
                      <select
                        value={updateRequest.stockTypeId || ''}
                        disabled
                        className="w-full cursor-not-allowed rounded-md border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-500 outline-none"
                      >
                        <option value="">{updateRequest.stockTypeName || 'All'}</option>
                      </select>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
                    <div>
                      <label className="mb-2 block text-sm font-medium text-slate-700">Item<span className="text-rose-500">*</span></label>
                      <select
                        value={newItemId}
                        onChange={(event) => setNewItemId(event.target.value)}
                        className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                      >
                        <option value="">Search Item</option>
                        {lookups.items.map((lookupItem) => (
                          <option key={productOptionValue(lookupItem)} value={productOptionValue(lookupItem)}>
                            {lookupItem.sourceType === 'Item' ? lookupItem.name : `${lookupItem.name} (${lookupItem.sourceType})`}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label className="mb-2 block text-sm font-medium text-slate-700">Requested Quantity<span className="text-rose-500">*</span></label>
                      <input
                        type="number"
                        min="1"
                        value={newItemQuantity}
                        onChange={(event) => setNewItemQuantity(event.target.value)}
                        className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                      />
                    </div>
                  </div>

                  <div className="flex justify-end gap-2">
                    <button
                      type="button"
                      onClick={handleAddItem}
                      className="rounded-md bg-indigo-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-indigo-700"
                    >
                      Add
                    </button>
                    <button
                      type="button"
                      onClick={handleCancelAddItem}
                      className="rounded-md border border-slate-200 px-5 py-2.5 text-sm font-medium text-slate-700 transition hover:bg-slate-50"
                    >
                      Cancel
                    </button>
                  </div>

                  <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
                    <div>
                      <div className="text-sm font-semibold text-slate-700">Requesting Store</div>
                      <div className="mt-1 text-sm text-slate-700">
                        ({updateRequest.requestingBranchName}){updateRequest.requestingStoreName || '-'}
                      </div>
                    </div>
                    <div>
                      <div className="text-sm font-semibold text-slate-700">Requested Store</div>
                      <div className="mt-1 text-sm text-slate-700">
                        ({updateRequest.requestingBranchName}){updateRequest.requestedStoreName}
                      </div>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
                    <div>
                      <label className="mb-2 block text-sm font-medium text-slate-700">Demand Notes</label>
                      <textarea
                        value={updateDemandNotes}
                        onChange={(event) => setUpdateDemandNotes(event.target.value)}
                        rows={2}
                        className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                      />
                    </div>
                    <div>
                      <label className="mb-2 block text-sm font-medium text-slate-700">Indent Number</label>
                      <input
                        type="text"
                        placeholder="Indent Number"
                        value={updateIndentNo}
                        onChange={(event) => setUpdateIndentNo(event.target.value)}
                        className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                      />
                    </div>
                  </div>

                  <div className="flex justify-end">
                    <label className="flex items-center gap-2 text-sm text-slate-600">
                      <span>Search:</span>
                      <input
                        type="text"
                        value={updateSearchTerm}
                        onChange={(event) => setUpdateSearchTerm(event.target.value)}
                        className="rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400 md:w-56"
                      />
                    </label>
                  </div>

                  <div className="overflow-x-auto border border-slate-200">
                    <table className="min-w-full text-sm">
                      <thead>
                        <tr className="bg-slate-50 text-left text-slate-700">
                          <th className="border-b border-slate-200 px-4 py-3 font-semibold">Sr.</th>
                          <th className="border-b border-slate-200 px-4 py-3 font-semibold">Items, Brand ( Model )</th>
                          <th className="border-b border-slate-200 px-4 py-3 text-center font-semibold">Available Quantity in Requesting Store</th>
                          <th className="border-b border-slate-200 px-4 py-3 text-center font-semibold">Requested Quantity</th>
                          <th className="border-b border-slate-200 px-4 py-3 text-center font-semibold">Available Quantity in Requested Store</th>
                          <th className="border-b border-slate-200 px-4 py-3 text-center font-semibold">Approved Quantity</th>
                          <th className="border-b border-slate-200 px-4 py-3 font-semibold">Remarks</th>
                        </tr>
                      </thead>
                      <tbody>
                        {filteredUpdateItems.length === 0 ? (
                          <tr>
                            <td colSpan="7" className="px-4 py-10 text-center text-slate-500">No items found.</td>
                          </tr>
                        ) : (
                          filteredUpdateItems.map((item, index) => (
                            <tr key={item.id ?? `new-${productOptionValue(item)}`} className="odd:bg-slate-50/60">
                              <td className="border-b border-slate-200 px-4 py-3">{index + 1}</td>
                              <td className="border-b border-slate-200 px-4 py-3 text-sky-700">{item.itemName}</td>
                              <td className="border-b border-slate-200 px-4 py-3 text-center">{item.availableInRequestingStore}</td>
                              <td className="border-b border-slate-200 px-4 py-3 text-center">{item.requestedQuantity}</td>
                              <td className="border-b border-slate-200 px-4 py-3 text-center">{item.availableInRequestedStore}</td>
                              <td className="border-b border-slate-200 px-4 py-3">
                                <input
                                  type="number"
                                  min="0"
                                  value={item.approvedQuantity}
                                  onChange={(event) => handleApprovedQuantityChange(index, event.target.value)}
                                  className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400"
                                />
                              </td>
                              <td className="border-b border-slate-200 px-4 py-3">
                                <input
                                  type="text"
                                  placeholder="Remarks"
                                  value={item.remarks}
                                  onChange={(event) => handleItemRemarksChange(index, event.target.value)}
                                  className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400"
                                />
                              </td>
                            </tr>
                          ))
                        )}
                      </tbody>
                    </table>
                  </div>

                  <div className="text-sm text-slate-600">Showing 1 to {filteredUpdateItems.length} of {filteredUpdateItems.length} entries</div>

                  <div className="flex justify-end gap-2 border-t border-slate-100 pt-5">
                    <button
                      type="button"
                      onClick={handleReject}
                      disabled={updateSubmitting}
                      className="rounded-md bg-rose-500 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-rose-600 disabled:cursor-not-allowed disabled:opacity-70"
                    >
                      Reject
                    </button>
                    <button
                      type="button"
                      onClick={handleSaveUpdate}
                      disabled={updateSubmitting}
                      className="rounded-md bg-indigo-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-70"
                    >
                      Save
                    </button>
                    <button
                      type="button"
                      onClick={handleApprove}
                      disabled={updateSubmitting}
                      className="rounded-md bg-indigo-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-70"
                    >
                      Approve
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
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-center text-[28px] leading-none text-slate-700">
                            <span className="text-base">{entry.status}</span>
                          </td>
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

export default PendingDemandsPage;