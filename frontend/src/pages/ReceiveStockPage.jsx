import React, { useEffect, useMemo, useState } from 'react';
import {
  ArrowDownTrayIcon,
  ClipboardDocumentListIcon,
  EyeIcon,
  InformationCircleIcon,
  PencilSquareIcon,
  Squares2X2Icon,
  XMarkIcon
} from '@heroicons/react/24/outline';
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

const ReceiveStockPage = () => {
  const { session } = useSession();
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submittingReceive, setSubmittingReceive] = useState(false);
  const [error, setError] = useState('');
  const [entriesPerPage, setEntriesPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [detailsLoading, setDetailsLoading] = useState(false);
  const [showUpdateModal, setShowUpdateModal] = useState(false);
  const [lifeCycleEntries, setLifeCycleEntries] = useState([]);
  const [lifeCycleLoading, setLifeCycleLoading] = useState(false);
  const [showLifeCycleModal, setShowLifeCycleModal] = useState(false);
  const [lifeCycleRequest, setLifeCycleRequest] = useState(null);
  const [lifeCycleSearchTerm, setLifeCycleSearchTerm] = useState('');
  const [lifeCycleEntriesPerPage, setLifeCycleEntriesPerPage] = useState(10);
  const [lifeCyclePage, setLifeCyclePage] = useState(1);
  const [receiveIndentNo, setReceiveIndentNo] = useState('');
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
    loadRequests();
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
      console.error('Error loading receive stock lookups:', lookupError);
      setError('Failed to load filter options.');
    }
  };

  const loadRequests = async () => {
    setLoading(true);
    setError('');

    try {
      const data = await demandRequestApi.getAll();
      setRequests(data);
    } catch (requestError) {
      console.error('Error loading receive stock data:', requestError);
      setError('Failed to load receive stock records.');
    } finally {
      setLoading(false);
    }
  };

  const filteredRequests = useMemo(() => {
    const issuedOnly = requests.filter((request) => (request.status || '').toLowerCase() === 'issued');

    return issuedOnly.filter((request) => {
      const matchesBranch = !filters.branchId || String(request.branchId) === String(filters.branchId);
      const matchesStore = !filters.requestingStoreId || String(request.requestingStoreId) === String(filters.requestingStoreId);
      const matchesStockType = !filters.stockTypeId || String(request.stockTypeId) === String(filters.stockTypeId);
      const matchesSearch = !searchTerm.trim() || [
        request.drNo,
        request.indentNo,
        request.requestedStoreName,
        request.itemSummary,
        request.status
      ].some((value) => (value || '').toLowerCase().includes(searchTerm.trim().toLowerCase()));

      return matchesBranch && matchesStore && matchesStockType && matchesSearch;
    });
  }, [filters.branchId, filters.requestingStoreId, filters.stockTypeId, requests, searchTerm]);

  useEffect(() => {
    setCurrentPage(1);
  }, [entriesPerPage, filters.branchId, filters.requestingStoreId, filters.stockTypeId, searchTerm]);

  const totalPages = Math.max(1, Math.ceil(filteredRequests.length / entriesPerPage));
  const startIndex = (currentPage - 1) * entriesPerPage;
  const pageItems = filteredRequests.slice(startIndex, startIndex + entriesPerPage);

  const handleFilterChange = (event) => {
    const { name, value } = event.target;
    setFilters((current) => ({
      ...current,
      [name]: value
    }));
  };

  const exportCsv = () => {
    const rows = filteredRequests.map((request) => [
      `${request.drNo} / ${request.indentNo || ''}`,
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
    link.download = 'receive-stock.csv';
    link.click();
    URL.revokeObjectURL(url);
  };

  const openUpdateModal = async (requestId) => {
    setShowUpdateModal(true);
    setDetailsLoading(true);
    setReceiveIndentNo('');

    try {
      const details = await demandRequestApi.getById(requestId);
      setSelectedRequest(details);
      setReceiveIndentNo(details.indentNo || '');
    } catch (detailsError) {
      console.error('Error loading receive stock details:', detailsError);
      setSelectedRequest(null);
      setError('Failed to load request details.');
    } finally {
      setDetailsLoading(false);
    }
  };

  const closeUpdateModal = () => {
    setShowUpdateModal(false);
    setSelectedRequest(null);
    setReceiveIndentNo('');
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
      console.error('Error loading receive stock life cycle:', lifeCycleError);
      setLifeCycleEntries([]);
      setError('Failed to load receive stock history.');
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

  const handleReceiveStock = async () => {
    if (!selectedRequest) {
      return;
    }

    setSubmittingReceive(true);
    setError('');

    try {
      await demandRequestApi.receive(selectedRequest.demandRequestId, {
        indentNo: receiveIndentNo || null
      });
      closeUpdateModal();
      await loadRequests();
    } catch (receiveError) {
      console.error('Error receiving stock:', receiveError);
      setError('Failed to receive stock.');
    } finally {
      setSubmittingReceive(false);
    }
  };

  const showingFrom = filteredRequests.length === 0 ? 0 : startIndex + 1;
  const showingTo = Math.min(startIndex + entriesPerPage, filteredRequests.length);

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-6 py-3">
            <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
              Receive Stock
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
              Receive Stock
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
                {[10, 25, 50].map((size) => (
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
            <div className="px-4 pb-4 text-sm text-slate-500">Loading receive stock records...</div>
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
                            <div className="text-base text-sky-700">{request.drNo} /</div>
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
                          <td className="border-b border-slate-200 px-6 py-8 align-middle text-blue-700">{request.status}</td>
                          <td className="border-b border-slate-200 px-6 py-8 align-middle">
                            <div className="flex items-center justify-center gap-3 text-indigo-400">
                              <button type="button" onClick={() => openUpdateModal(request.demandRequestId)} className="transition hover:text-indigo-600" title="Update Request">
                                <PencilSquareIcon className="h-5 w-5" />
                              </button>
                              <button type="button" onClick={() => openUpdateModal(request.demandRequestId)} className="text-emerald-600 transition hover:text-emerald-700" title="Open Request">
                                <EyeIcon className="h-5 w-5" />
                              </button>
                              <button type="button" onClick={() => openLifeCycleModal(request)} className="text-slate-900 transition hover:text-indigo-600" title="Receive Stock History">
                                <Squares2X2Icon className="h-5 w-5" />
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
                <div>Showing {showingFrom} to {showingTo} of {filteredRequests.length} entries</div>
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

      {showUpdateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
          <div className="max-h-[92vh] w-full max-w-[1800px] overflow-hidden rounded-md bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
              <h3 className="text-[18px] font-medium text-slate-700">Update Request</h3>
              <button type="button" onClick={closeUpdateModal} className="rounded-md p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600"><XMarkIcon className="h-5 w-5" /></button>
            </div>

            <div className="max-h-[calc(92vh-72px)] overflow-y-auto px-6 py-5">
              {detailsLoading ? (
                <div className="text-sm text-slate-500">Loading request details...</div>
              ) : !selectedRequest ? (
                <div className="text-sm text-slate-500">Request details are unavailable.</div>
              ) : (
                <div className="space-y-8">
                  <div className="grid grid-cols-1 gap-x-10 gap-y-8 lg:grid-cols-2">
                    <div className="space-y-8">
                      <div className="grid grid-cols-[260px_1fr] gap-4">
                        <div className="font-semibold text-slate-900">Requesting Store:</div>
                        <div className="text-slate-800">{selectedRequest.requestingStoreName || selectedRequest.requestedStoreName}</div>
                      </div>
                      <div className="grid grid-cols-[260px_1fr] gap-4">
                        <div className="font-semibold text-slate-900">Demand Notes:</div>
                        <div className="text-slate-800">{selectedRequest.remarks || ''}</div>
                      </div>
                      <div className="grid grid-cols-[260px_1fr] gap-4">
                        <div className="font-semibold text-slate-900">Delivery Person:</div>
                        <div className="text-slate-800"></div>
                      </div>
                      <div className="grid grid-cols-[260px_1fr] gap-4">
                        <div className="font-semibold text-slate-900">Contact No:</div>
                        <div className="text-slate-800"></div>
                      </div>
                    </div>

                    <div className="space-y-8">
                      <div className="grid grid-cols-[260px_1fr] gap-4">
                        <div className="font-semibold text-slate-900">Requested Store:</div>
                        <div className="text-slate-800">{selectedRequest.requestedStoreName}</div>
                      </div>
                      <div className="grid grid-cols-[260px_1fr] gap-4">
                        <div className="font-semibold text-slate-900">Vehicle No:</div>
                        <div className="text-slate-800"></div>
                      </div>
                      <div className="grid grid-cols-[260px_1fr] gap-4">
                        <div className="font-semibold text-slate-900">Detail:</div>
                        <div className="text-slate-800"></div>
                      </div>
                    </div>
                  </div>

                  <div className="flex justify-end">
                    <label className="flex items-center gap-2 text-sm text-slate-700">
                      <span>Search:</span>
                      <input type="text" className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400 md:w-44" />
                    </label>
                  </div>

                  <div className="overflow-x-auto border border-slate-200">
                    <table className="min-w-full text-sm">
                      <thead>
                        <tr className="bg-white text-slate-900">
                          <th className="border-b border-r border-slate-200 px-4 py-4 text-center font-semibold">Sr#</th>
                          <th className="border-b border-r border-slate-200 px-4 py-4 text-center font-semibold">Items, Brand ( Model )</th>
                          <th className="border-b border-r border-slate-200 px-4 py-4 text-center font-semibold">Location</th>
                          <th className="border-b border-r border-slate-200 px-4 py-4 text-center font-semibold">Approved Quantity</th>
                          <th className="border-b border-r border-slate-200 px-4 py-4 text-center font-semibold">Issued Quantity</th>
                          <th className="border-b border-r border-slate-200 px-4 py-4 text-center font-semibold">Remaining Quantity</th>
                          <th className="border-b border-slate-200 px-4 py-4 text-center font-semibold">Remarks</th>
                        </tr>
                      </thead>
                      <tbody>
                        {selectedRequest.items.map((item, index) => (
                          <tr key={item.id} className="odd:bg-slate-50/60">
                            <td className="border-b border-r border-slate-200 px-4 py-4 text-center">{index + 1}</td>
                            <td className="border-b border-r border-slate-200 px-4 py-4">{item.itemName || 'Unassigned Item'}</td>
                            <td className="border-b border-r border-slate-200 px-4 py-4"></td>
                            <td className="border-b border-r border-slate-200 px-4 py-4 text-center">{item.approvedQuantity ?? item.requestedQuantity}</td>
                            <td className="border-b border-r border-slate-200 px-4 py-4 text-center">{item.issuedQuantity ?? item.approvedQuantity ?? item.requestedQuantity}</td>
                            <td className="border-b border-r border-slate-200 px-4 py-4 text-center">{item.remainingQuantity ?? 0}</td>
                            <td className="border-b border-slate-200 px-4 py-4">{item.remarks || ''}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  <div className="grid grid-cols-1 gap-4 lg:grid-cols-[260px_minmax(0,1fr)] lg:items-center">
                    <label className="text-sm font-medium text-slate-700">Indent Number</label>
                    <input
                      type="text"
                      value={receiveIndentNo}
                      onChange={(event) => setReceiveIndentNo(event.target.value)}
                      placeholder="Indent Number"
                      className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                    />
                  </div>

                  <div className="flex justify-end">
                    <button type="button" onClick={handleReceiveStock} disabled={submittingReceive} className="rounded-md bg-indigo-600 px-6 py-3 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60">
                      {submittingReceive ? 'Receiving...' : 'Receive Stock'}
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
                <h3 className="text-[18px] font-medium text-slate-700">Receive Stock</h3>
              </div>
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
                      <tr><td colSpan="3" className="px-6 py-10 text-center text-slate-500">Loading receive stock history...</td></tr>
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

export default ReceiveStockPage;