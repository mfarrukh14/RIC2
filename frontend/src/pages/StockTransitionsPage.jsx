import React, { useEffect, useMemo, useState } from 'react';
import {
  ArrowDownTrayIcon,
  ClipboardDocumentListIcon,
  InformationCircleIcon,
  PencilSquareIcon,
  XMarkIcon
} from '@heroicons/react/24/outline';
import transferInventoryApi from '../services/transferInventoryApi';
import Pagination from '../components/Pagination';

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

function normalizeTransitionRecords(records) {
  const grouped = new Map();

  records
    .filter((record) => record.isActive)
    .forEach((record) => {
      const storeName = record.toStoreName || record.fromStoreName || 'Unknown Store';
      const itemName = record.itemName || 'Unknown Item';
      const stockTypeName = record.stockTypeName || 'Regular';
      const key = `${storeName}__${itemName}__${stockTypeName}`;

      if (!grouped.has(key)) {
        grouped.set(key, {
          id: key,
          storeName,
          itemName,
          stockTypeName,
          totalItemsInTransition: 0,
          records: []
        });
      }

      const group = grouped.get(key);
      group.totalItemsInTransition += Number(record.quantity || 0);
      group.records.push(record);
    });

  return Array.from(grouped.values()).sort((left, right) => {
    const storeSort = left.storeName.localeCompare(right.storeName);
    if (storeSort !== 0) {
      return storeSort;
    }

    return left.itemName.localeCompare(right.itemName);
  });
}

const StockTransitionsPage = () => {
  const [transitions, setTransitions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [entriesPerPage, setEntriesPerPage] = useState(5);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedGroup, setSelectedGroup] = useState(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [modalSearchTerm, setModalSearchTerm] = useState('');
  const [modalEntriesPerPage, setModalEntriesPerPage] = useState(10);
  const [modalCurrentPage, setModalCurrentPage] = useState(1);

  useEffect(() => {
    loadTransitions();
  }, []);

  // The store+item+stockType grouping below needs every transfer record, not
  // just one page of them, so this pulls every page from the (now paginated)
  // API back-to-back into one array before grouping/re-paginating client-side.
  const loadTransitions = async () => {
    setLoading(true);
    setError('');

    try {
      const pageSize = 200;
      let page = 1;
      let all = [];
      let totalCount = Infinity;

      while (all.length < totalCount) {
        const data = await transferInventoryApi.getAll({ pageNumber: page, pageSize });
        const items = data.items || [];
        totalCount = data.totalCount || 0;
        all = all.concat(items);
        if (items.length === 0) {
          break;
        }
        page += 1;
      }

      setTransitions(normalizeTransitionRecords(all));
    } catch (requestError) {
      console.error('Error loading stock transitions:', requestError);
      setError('Failed to load stock transitions.');
    } finally {
      setLoading(false);
    }
  };

  const filteredTransitions = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase();

    if (!normalizedSearch) {
      return transitions;
    }

    return transitions.filter((transition) => [
      transition.storeName,
      transition.itemName,
      transition.stockTypeName,
      String(transition.totalItemsInTransition)
    ].some((value) => (value || '').toLowerCase().includes(normalizedSearch)));
  }, [searchTerm, transitions]);

  useEffect(() => {
    setCurrentPage(1);
  }, [entriesPerPage, searchTerm]);

  const startIndex = (currentPage - 1) * entriesPerPage;
  const pageItems = filteredTransitions.slice(startIndex, startIndex + entriesPerPage);

  const exportCsv = () => {
    const csv = [
      ['Store', 'Item', 'Stock Type', 'Total Item In Transition'],
      ...filteredTransitions.map((transition) => [
        transition.storeName,
        transition.itemName,
        transition.stockTypeName,
        transition.totalItemsInTransition
      ])
    ]
      .map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(','))
      .join('\n');

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'stock-transitions.csv';
    link.click();
    URL.revokeObjectURL(url);
  };

  const openDetailsModal = (transitionGroup) => {
    setSelectedGroup(transitionGroup);
    setModalSearchTerm('');
    setModalEntriesPerPage(10);
    setModalCurrentPage(1);
    setShowDetailsModal(true);
  };

  const closeDetailsModal = () => {
    setSelectedGroup(null);
    setModalSearchTerm('');
    setModalCurrentPage(1);
    setShowDetailsModal(false);
  };

  const filteredModalRecords = useMemo(() => {
    if (!selectedGroup) {
      return [];
    }

    const normalizedSearch = modalSearchTerm.trim().toLowerCase();
    if (!normalizedSearch) {
      return selectedGroup.records;
    }

    return selectedGroup.records.filter((record) => [
      record.drNo,
      record.fromStoreName,
      record.toStoreName,
      record.itemName,
      formatDateTime(record.transferDate || record.createdOn),
      String(record.quantity || '')
    ].some((value) => (value || '').toLowerCase().includes(normalizedSearch)));
  }, [modalSearchTerm, selectedGroup]);

  useEffect(() => {
    setModalCurrentPage(1);
  }, [modalEntriesPerPage, modalSearchTerm, selectedGroup]);

  const modalStartIndex = (modalCurrentPage - 1) * modalEntriesPerPage;
  const modalPageItems = filteredModalRecords.slice(modalStartIndex, modalStartIndex + modalEntriesPerPage);

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="flex flex-col gap-4 border-b border-slate-100 px-4 py-3 lg:flex-row lg:items-center lg:justify-between">
            <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
              <ClipboardDocumentListIcon className="h-5 w-5 text-indigo-500" />
              Stock Transitions
              <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
            </h1>

            <button
              type="button"
              onClick={exportCsv}
              className="inline-flex items-center gap-2 rounded-md border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50"
            >
              <ArrowDownTrayIcon className="h-4 w-4 text-indigo-500" />
              Export
            </button>
          </div>

          <div className="flex flex-col gap-3 px-4 py-4 md:flex-row md:items-center md:justify-end">
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
            <div className="px-4 pb-4 text-sm text-slate-500">Loading stock transitions...</div>
          ) : (
            <>
              <div className="overflow-x-auto px-4">
                <table className="min-w-full border-separate border-spacing-0 text-sm">
                  <thead>
                    <tr className="text-left text-slate-700">
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Store</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Item</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 font-semibold">Stock Type</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 text-center font-semibold">Total Item In Transition</th>
                      <th className="border-y border-slate-200 bg-white px-6 py-4 text-center font-semibold">Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    {pageItems.length === 0 ? (
                      <tr>
                        <td colSpan="5" className="border-b border-slate-200 px-4 py-12 text-center text-slate-500">
                          No data available in table
                        </td>
                      </tr>
                    ) : (
                      pageItems.map((transition) => (
                        <tr key={transition.id} className="text-slate-700">
                          <td className="border-b border-slate-200 px-6 py-5 align-middle">{transition.storeName}</td>
                          <td className="border-b border-slate-200 px-6 py-5 align-middle">{transition.itemName}</td>
                          <td className="border-b border-slate-200 px-6 py-5 align-middle text-center">{transition.stockTypeName}</td>
                          <td className="border-b border-slate-200 px-6 py-5 align-middle text-center">{transition.totalItemsInTransition}</td>
                          <td className="border-b border-slate-200 px-6 py-5 align-middle">
                            <div className="flex items-center justify-center text-indigo-400">
                              <button
                                type="button"
                                onClick={() => openDetailsModal(transition)}
                                className="transition hover:text-indigo-600"
                                title="View transition details"
                              >
                                <PencilSquareIcon className="h-5 w-5" />
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                  <tfoot>
                    <tr className="text-left text-slate-700">
                      <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Store</th>
                      <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Item</th>
                      <th className="border-b border-slate-200 bg-white px-6 py-4 font-semibold">Stock Type</th>
                      <th className="border-b border-slate-200 bg-white px-6 py-4 text-center font-semibold">Total Item In Transition</th>
                      <th className="border-b border-slate-200 bg-white px-6 py-4 text-center font-semibold">Action</th>
                    </tr>
                  </tfoot>
                </table>
              </div>

              <Pagination
                currentPage={currentPage}
                pageSize={entriesPerPage}
                totalCount={filteredTransitions.length}
                onPageChange={setCurrentPage}
                onPageSizeChange={setEntriesPerPage}
              />
            </>
          )}
        </section>
      </div>

      {showDetailsModal && selectedGroup && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
          <div className="max-h-[90vh] w-full max-w-[1800px] overflow-hidden rounded-md bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
              <div>
                <h3 className="text-[18px] font-medium text-slate-700">Stock Transition Detail</h3>
              </div>
              <button type="button" onClick={closeDetailsModal} className="rounded-md p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            <div className="max-h-[calc(90vh-72px)] overflow-y-auto px-6 py-5">
              <div className="mb-5 flex flex-col gap-3 md:flex-row md:items-center md:justify-end">
                <label className="flex items-center gap-2 text-sm text-slate-700">
                  <span>Search:</span>
                  <input
                    type="text"
                    value={modalSearchTerm}
                    onChange={(event) => setModalSearchTerm(event.target.value)}
                    className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none transition focus:border-indigo-400 md:w-44"
                  />
                </label>
              </div>

              <div className="overflow-x-auto border border-slate-200">
                <table className="min-w-full text-sm">
                  <thead>
                    <tr className="bg-white text-slate-900">
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">DR-Number</th>
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Requesting Store</th>
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Requested Store</th>
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Item Name</th>
                      <th className="border-b border-r border-slate-200 px-6 py-4 text-center font-semibold">Quantity</th>
                      <th className="border-b border-slate-200 px-6 py-4 text-center font-semibold">Date &amp; Time</th>
                    </tr>
                  </thead>
                  <tbody>
                    {modalPageItems.length === 0 ? (
                      <tr>
                        <td colSpan="6" className="px-6 py-10 text-center text-slate-500">No transaction details found.</td>
                      </tr>
                    ) : (
                      modalPageItems.map((record) => (
                        <tr key={record.id} className="odd:bg-slate-50/60">
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-center text-sky-700">{record.drNo || '-'}</td>
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-slate-700">{record.fromStoreName || '-'}</td>
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-slate-700">{record.toStoreName || '-'}</td>
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-slate-700">{record.itemName || '-'}</td>
                          <td className="border-b border-r border-slate-200 px-6 py-4 text-center text-slate-700">{record.quantity}</td>
                          <td className="border-b border-slate-200 px-6 py-4 text-slate-700">{formatDateTime(record.transferDate || record.createdOn)}</td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>

              <Pagination
                currentPage={modalCurrentPage}
                pageSize={modalEntriesPerPage}
                totalCount={filteredModalRecords.length}
                onPageChange={setModalCurrentPage}
                onPageSizeChange={setModalEntriesPerPage}
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default StockTransitionsPage;