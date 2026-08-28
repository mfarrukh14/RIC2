import React, { useEffect, useMemo, useState } from 'react';
import {
  ArrowDownTrayIcon,
  ClipboardDocumentListIcon,
  InformationCircleIcon,
  PrinterIcon,
  QuestionMarkCircleIcon,
  Squares2X2Icon,
  XMarkIcon
} from '@heroicons/react/24/outline';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
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
    case 'received':
      return 'text-emerald-700';
    case 'issued':
      return 'text-blue-700';
    default:
      return 'text-slate-700';
  }
}

const ReceivedStockStatusPage = () => {
  const { session } = useSession();
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [entriesPerPage, setEntriesPerPage] = useState(5);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [showHistoryModal, setShowHistoryModal] = useState(false);
  const [historyEntries, setHistoryEntries] = useState([]);
  const [historyLoading, setHistoryLoading] = useState(false);
  const [historySearchTerm, setHistorySearchTerm] = useState('');
  const [historyEntriesPerPage, setHistoryEntriesPerPage] = useState(10);
  const [historyPage, setHistoryPage] = useState(1);
  const [lifeCycleEntries, setLifeCycleEntries] = useState([]);
  const [lifeCycleLoading, setLifeCycleLoading] = useState(false);
  const [showLifeCycleModal, setShowLifeCycleModal] = useState(false);
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
    requestingStoreId: '',
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
      console.error('Error loading received stock lookups:', lookupError);
      setError('Failed to load filter options.');
    }
  };

  const loadRequests = async () => {
    setLoading(true);
    setError('');

    try {
      const response = await demandRequestApi.getAll({
        statuses: 'Received',
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
      console.error('Error loading received stock records:', requestError);
      setError('Failed to load received stock records.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadRequests();
  }, [entriesPerPage, currentPage, filters.branchId, filters.requestingStoreId, filters.stockTypeId, searchTerm]);

  useEffect(() => {
    setCurrentPage(1);
  }, [entriesPerPage, filters.branchId, filters.requestingStoreId, filters.stockTypeId, searchTerm]);

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
        statuses: 'Received',
        branchId: filters.branchId || undefined,
        requestingStoreId: filters.requestingStoreId || undefined,
        stockTypeId: filters.stockTypeId || undefined,
        search: searchTerm.trim() || undefined,
        pageNumber: 1,
        pageSize: Math.max(totalCount, 1)
      });
      allRequests = response.items;
    } catch (exportError) {
      console.error('Error exporting received stock records:', exportError);
      setError('Failed to export received stock records.');
      return;
    }

    const rows = allRequests.map((request) => [
      request.drNo,
      request.stockTypeName || '',
      request.requestedStoreName || '',
      request.itemSummary || '',
      formatDateTime(request.createdOn),
      request.status
    ]);

    const csv = [
      ['DR-NO. / INDENT NO.', 'Stock Type', 'Requested Store', 'Items', 'Date & Time', 'Status'],
      ...rows
    ]
      .map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(','))
      .join('\n');

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'received-stock-status.csv';
    link.click();
    URL.revokeObjectURL(url);
  };

  // "Print" - the same "Demand Request" report layout used across the demand
  // lifecycle pages (RIC letterhead, header grid, items table, notes, signature
  // block) instead of a raw browser full-page print of the on-screen table.
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
    doc.text('Received Stock', pageWidth / 2, 36, { align: 'center' });

    const dateOnly = (value) => (value ? new Date(value).toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' }) : '-');

    const headerRows = [
      ['DR-Number', details.drNo || '-', 'Stock Type', details.stockTypeName || 'All'],
      ['Requested Date', dateOnly(details.createdOn), 'Requested By', details.requestedByName || '-'],
      ['Request Status', details.status || '-', 'From Store', details.requestingStoreName || '-'],
      ['To Store', details.requestedStoreName || '-', 'Approved Date', dateOnly(details.approvedDate)],
      ['Issued Date', dateOnly(details.issuedDate), 'Received Date', dateOnly(details.receivedDate)]
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

    const now = new Date();
    const dateStr = now.toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' });
    const timeStr = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
    doc.setFontSize(8);
    doc.setFont('helvetica', 'normal');
    doc.text(`${dateStr}   ${timeStr}`, 14, doc.internal.pageSize.height - 10);
    doc.text('Page 1 of 1', pageWidth - 14, doc.internal.pageSize.height - 10, { align: 'right' });

    doc.save(`ReceivedStock_${details.drNo}.pdf`);
  };

  const openHistoryModal = async (requestId) => {
    setShowHistoryModal(true);
    setHistoryLoading(true);
    setHistorySearchTerm('');
    setHistoryPage(1);

    try {
      const [details, logEntries] = await Promise.all([
        demandRequestApi.getById(requestId),
        demandRequestApi.getItemLogs(requestId)
      ]);
      setSelectedRequest(details);
      setHistoryEntries(logEntries);
    } catch (detailsError) {
      console.error('Error loading received stock detail history:', detailsError);
      setSelectedRequest(null);
      setHistoryEntries([]);
      setError('Failed to load received stock history.');
    } finally {
      setHistoryLoading(false);
    }
  };

  const closeHistoryModal = () => {
    setShowHistoryModal(false);
    setSelectedRequest(null);
    setHistoryEntries([]);
    setHistorySearchTerm('');
    setHistoryPage(1);
  };

  const openLifeCycleModal = async (request) => {
    setShowLifeCycleModal(true);
    setLifeCycleLoading(true);
    setLifeCycleSearchTerm('');
    setLifeCyclePage(1);

    try {
      const entries = await demandRequestApi.getLifeCycle(request.demandRequestId);
      setLifeCycleEntries(entries);
    } catch (lifeCycleError) {
      console.error('Error loading received stock lifecycle:', lifeCycleError);
      setLifeCycleEntries([]);
      setError('Failed to load demand lifecycle.');
    } finally {
      setLifeCycleLoading(false);
    }
  };

  const closeLifeCycleModal = () => {
    setShowLifeCycleModal(false);
    setLifeCycleEntries([]);
    setLifeCycleSearchTerm('');
    setLifeCyclePage(1);
  };

  const filteredHistoryItems = useMemo(() => {
    const normalizedSearch = historySearchTerm.trim().toLowerCase();
    if (!normalizedSearch) {
      return historyEntries;
    }

    return historyEntries.filter((entry) => [
      entry.itemName,
      entry.actionType,
      entry.actionBy,
      String(entry.quantity ?? ''),
      String(entry.issuedQuantity ?? ''),
      String(entry.receivedQuantity ?? ''),
      String(entry.remainingQuantity ?? '')
    ].some((value) => (value || '').toLowerCase().includes(normalizedSearch)));
  }, [historySearchTerm, historyEntries]);

  useEffect(() => {
    setHistoryPage(1);
  }, [historyEntriesPerPage, historySearchTerm, showHistoryModal]);

  const historyTotalPages = Math.max(1, Math.ceil(filteredHistoryItems.length / historyEntriesPerPage));
  const historyStartIndex = (historyPage - 1) * historyEntriesPerPage;
  const currentHistoryItems = filteredHistoryItems.slice(historyStartIndex, historyStartIndex + historyEntriesPerPage);
  const historyShowingFrom = filteredHistoryItems.length === 0 ? 0 : historyStartIndex + 1;
  const historyShowingTo = Math.min(historyStartIndex + historyEntriesPerPage, filteredHistoryItems.length);

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
              Received Stock Status
              <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
            </h1>
          </div>

          <div className="grid grid-cols-1 gap-x-4 gap-y-6 px-6 py-5 lg:grid-cols-2">
            {/* Branch - locked to the logged-in user's own branch */}
            <BranchField />

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Store</label>
              <select
                name="requestingStoreId"
                value={filters.requestingStoreId}
                onChange={handleFilterChange}
                className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
              >
                <option value="">All</option>
                {lookups.stores.map((store) => (
                  <option key={store.storeId} value={store.storeId}>{store.storeName}</option>
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
                  <option key={stockType.id} value={stockType.id}>{stockType.name}</option>
                ))}
              </select>
            </div>
          </div>
        </section>

        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="flex flex-col gap-4 border-b border-slate-100 px-4 py-3 lg:flex-row lg:items-center lg:justify-between">
            <h2 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
              <ClipboardDocumentListIcon className="h-5 w-5 text-indigo-500" />
              Received Stock
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
              <select value={entriesPerPage} onChange={(event) => setEntriesPerPage(Number(event.target.value))} className="rounded-md border border-slate-200 px-2 py-1 text-sm">
                {[5, 10, 25, 50].map((size) => <option key={size} value={size}>{size}</option>)}
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
            <div className="px-4 pb-4 text-sm text-slate-500">Loading received stock records...</div>
          ) : (
            <>
              <div className="overflow-x-auto px-4">
                <table className="min-w-full border-separate border-spacing-0 text-sm">
                  <thead>
                    <tr className="text-left text-slate-700">
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">DR-NO. / Indent NO.</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Stock Type</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Requested Store</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Items</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Date &amp; Time</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Status</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    {pageItems.length === 0 ? (
                      <tr>
                        <td colSpan="7" className="border-b border-slate-200 px-4 py-12 text-center text-slate-500">No data available in table</td>
                      </tr>
                    ) : (
                      pageItems.map((request) => (
                        <tr key={request.demandRequestId} className="text-slate-700">
                          <td className="border-b border-slate-200 px-6 py-8 align-middle text-center">
                            <div className="text-base text-sky-700">{request.drNo}</div>
                            <div className="text-base text-slate-700">{request.indentNo || '-'}</div>
                          </td>
                          <td className="border-b border-slate-200 px-6 py-8 align-middle">{request.stockTypeName || 'All'}</td>
                          <td className="border-b border-slate-200 px-6 py-8 align-middle">{request.requestedStoreName}</td>
                          <td className="border-b border-slate-200 px-6 py-8 align-middle">
                            <div className="max-w-[620px] truncate" title={request.itemSummary || ''}>
                              {request.itemSummary || `${request.itemsCount} item${request.itemsCount === 1 ? '' : 's'}`}
                            </div>
                          </td>
                          <td className="border-b border-slate-200 px-6 py-8 align-middle">{formatDateTime(request.createdOn)}</td>
                          <td className={`border-b border-slate-200 px-6 py-8 align-middle ${statusClasses(request.status)}`}>{request.status}</td>
                          <td className="border-b border-slate-200 px-6 py-8 align-middle">
                            <div className="flex flex-col items-center gap-2">
                              <button type="button" onClick={() => handlePrintDemandRequest(request)} className="text-emerald-600 transition hover:text-emerald-700" title="Print">
                                <PrinterIcon className="h-5 w-5" />
                              </button>
                              <button type="button" onClick={() => openLifeCycleModal(request)} className="text-indigo-500 transition hover:text-indigo-700" title="Demand Life Cycle">
                                <Squares2X2Icon className="h-5 w-5" />
                              </button>
                              <button type="button" onClick={() => openHistoryModal(request.demandRequestId)} className="text-blue-500 transition hover:text-blue-700" title="Demand Life Cycle History">
                                <QuestionMarkCircleIcon className="h-5 w-5" />
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
                      <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Requested Store</th>
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
                  <button type="button" onClick={() => setCurrentPage((page) => Math.max(page - 1, 1))} disabled={currentPage === 1} className="rounded-md border border-slate-200 px-3 py-2 disabled:cursor-not-allowed disabled:opacity-50">‹</button>
                  <span className="rounded-md bg-indigo-600 px-3 py-2 text-white">{currentPage}</span>
                  <button type="button" onClick={() => setCurrentPage((page) => Math.min(page + 1, totalPages))} disabled={currentPage === totalPages} className="rounded-md border border-slate-200 px-3 py-2 disabled:cursor-not-allowed disabled:opacity-50">›</button>
                </div>
              </div>
            </>
          )}
        </section>
      </div>

      {showHistoryModal && (
        <div className="fixed inset-0 z-[60] flex items-start justify-center bg-slate-900/40 p-4 pt-6">
          <div className="w-full max-w-[1800px] overflow-hidden rounded-md border border-slate-200 bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
              <h3 className="text-[18px] font-medium text-slate-700">Demand Life Cycle History</h3>
              <button type="button" onClick={closeHistoryModal} className="rounded-md p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600"><XMarkIcon className="h-5 w-5" /></button>
            </div>

            <div className="px-6 py-4">
              <div className="mb-5 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
                <div className="flex items-center gap-2 text-sm text-slate-700">
                  <span>Show</span>
                  <select value={historyEntriesPerPage} onChange={(event) => setHistoryEntriesPerPage(Number(event.target.value))} className="rounded-md border border-slate-200 px-3 py-2 text-sm outline-none">
                    {[10, 25, 50].map((size) => <option key={size} value={size}>{size}</option>)}
                  </select>
                  <span>entries</span>
                </div>

                <div className="flex items-center gap-4">
                  <button type="button" onClick={() => selectedRequest && handlePrintDemandRequest(selectedRequest)} className="text-emerald-600 transition hover:text-emerald-700" title="Print">
                    <PrinterIcon className="h-5 w-5" />
                  </button>
                  <label className="flex items-center gap-2 text-sm text-slate-700">
                    <span>Search:</span>
                    <input type="text" value={historySearchTerm} onChange={(event) => setHistorySearchTerm(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400 md:w-56" />
                  </label>
                </div>
              </div>

              <div className="overflow-x-auto border border-slate-200">
                <table className="min-w-full text-sm">
                  <thead>
                    <tr className="bg-white text-slate-900">
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Date Time</th>
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Item</th>
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Action</th>
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Quantity</th>
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Issued Quantity</th>
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Received Quantity</th>
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Remaining Quantity</th>
                      <th className="border-b border-slate-200 px-6 py-4 text-center font-semibold">Entered By</th>
                    </tr>
                  </thead>
                  <tbody>
                    {historyLoading ? (
                      <tr><td colSpan="8" className="px-6 py-10 text-center text-slate-500">Loading received stock item history...</td></tr>
                    ) : currentHistoryItems.length === 0 ? (
                      <tr><td colSpan="8" className="px-6 py-10 text-center text-slate-500">No data available in table</td></tr>
                    ) : (
                      currentHistoryItems.map((entry) => (
                        <tr key={entry.id} className="odd:bg-slate-50/60">
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-center">{formatDateTime(entry.createdOn)}</td>
                          <td className="border-b border-r border-slate-200 px-6 py-4">{entry.itemName || 'Unassigned Item'}</td>
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-center">{entry.actionType}</td>
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-center">{entry.quantity}</td>
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-center">{entry.issuedQuantity ?? 0}</td>
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-center">{entry.receivedQuantity ?? 0}</td>
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-center">{entry.remainingQuantity ?? 0}</td>
                          <td className="border-b border-slate-200 px-6 py-4 text-center">{entry.actionBy || 'System'}</td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>

              <div className="mt-5 flex flex-col gap-3 text-sm text-slate-600 md:flex-row md:items-center md:justify-between">
                <div>Showing {historyShowingFrom} to {historyShowingTo} of {filteredHistoryItems.length} entries</div>
                <div className="flex items-center gap-1.5">
                  <button type="button" onClick={() => setHistoryPage((page) => Math.max(page - 1, 1))} disabled={historyPage === 1} className="rounded bg-slate-100 px-3 py-2 text-slate-500 disabled:cursor-not-allowed disabled:opacity-50">‹</button>
                  <span className="rounded bg-indigo-500 px-3 py-2 text-white">{historyPage}</span>
                  <button type="button" onClick={() => setHistoryPage((page) => Math.min(page + 1, historyTotalPages))} disabled={historyPage === historyTotalPages} className="rounded bg-slate-100 px-3 py-2 text-slate-500 disabled:cursor-not-allowed disabled:opacity-50">›</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {showLifeCycleModal && (
        <div className="fixed inset-0 z-[60] flex items-start justify-center bg-slate-900/40 p-4 pt-6">
          <div className="w-full max-w-7xl overflow-hidden rounded-md border border-slate-200 bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
              <h3 className="text-[18px] font-medium text-slate-700">Demand Life Cycle</h3>
              <button type="button" onClick={closeLifeCycleModal} className="rounded-md p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600"><XMarkIcon className="h-5 w-5" /></button>
            </div>

            <div className="px-6 py-4">
              <div className="mb-5 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
                <div className="flex items-center gap-2 text-sm text-slate-700">
                  <span>Show</span>
                  <select value={lifeCycleEntriesPerPage} onChange={(event) => setLifeCycleEntriesPerPage(Number(event.target.value))} className="rounded-md border border-slate-200 px-3 py-2 text-sm outline-none">
                    {[10, 25, 50].map((size) => <option key={size} value={size}>{size}</option>)}
                  </select>
                  <span>entries</span>
                </div>

                <label className="flex items-center gap-2 text-sm text-slate-700">
                  <span>Search:</span>
                  <input type="text" value={lifeCycleSearchTerm} onChange={(event) => setLifeCycleSearchTerm(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400 md:w-56" />
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
                      <tr><td colSpan="3" className="px-6 py-10 text-center text-slate-500">Loading demand lifecycle...</td></tr>
                    ) : currentLifeCycleEntries.length === 0 ? (
                      <tr><td colSpan="3" className="px-6 py-10 text-center text-slate-500">No lifecycle entries found.</td></tr>
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
                  <button type="button" onClick={() => setLifeCyclePage((page) => Math.max(page - 1, 1))} disabled={lifeCyclePage === 1} className="rounded bg-slate-100 px-3 py-2 text-slate-500 disabled:cursor-not-allowed disabled:opacity-50">‹</button>
                  <span className="rounded bg-indigo-500 px-3 py-2 text-white">{lifeCyclePage}</span>
                  <button type="button" onClick={() => setLifeCyclePage((page) => Math.min(page + 1, lifeCycleTotalPages))} disabled={lifeCyclePage === lifeCycleTotalPages} className="rounded bg-slate-100 px-3 py-2 text-slate-500 disabled:cursor-not-allowed disabled:opacity-50">›</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ReceivedStockStatusPage;