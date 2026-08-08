import React, { useCallback, useState, useEffect } from 'react';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import returnInventoryApi from '../services/returnInventoryApi';
import stockApi from '../services/stockApi';
import BranchField from '../components/BranchField';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';
import { useSession } from '../context/SessionContext';

const ReturnInventoryPage = ({ prefill, onPrefillConsumed }) => {
  const { session } = useSession();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);

  const [lookupData, setLookupData] = useState({
    branches: [],
    stores: [],
    itemTypes: [],
    vendors: []
  });

  // Items available for the currently selected Store + Item Type, with their
  // live on-hand quantity in that store (so the picker can show "Item - 5 in
  // stock" and the quantity input can be capped before the server round-trip).
  const [storeItems, setStoreItems] = useState([]);
  const [loadingItems, setLoadingItems] = useState(false);

  // Filters / return form - Store, Item Type, Item and Quantity are all
  // required to actually process a return; PO Number / Inventory No. are
  // optional and, when supplied, also reduce the matching Purchase Order /
  // GRN line for the item (in addition to the store's stock).
  const [filters, setFilters] = useState({
    branchId: '',
    storeId: '',
    itemTypeId: '',
    startDate: '',
    endDate: '',
    purchaseOrderNo: '',
    itemId: '',
    inventoryNo: '',
    quantity: '',
    reason: ''
  });

  const fetchReturnsPage = useCallback(async (params) => {
    const data = await returnInventoryApi.getAll(params);
    return { items: data.items || [], totalCount: data.totalCount || 0 };
  }, []);

  const {
    items: returns,
    totalCount,
    currentPage,
    pageSize: entriesPerPage,
    setPageSize: setEntriesPerPage,
    goToPage,
    loading,
    error: returnsError,
    reload: reloadReturns,
  } = usePagedList(fetchReturnsPage, {}, { initialPageSize: 10 });

  useEffect(() => {
    fetchLookupData();
  }, []);

  // Returns are always scoped to the logged-in user's own branch.
  useEffect(() => {
    if (session?.branchId) {
      setFilters((prev) => ({ ...prev, branchId: session.branchId }));
    }
  }, [session?.branchId]);

  // Coming here via Add Inventory's "Return Inventory" row action - pre-select that
  // inventory's store (and item type/item, when the row had exactly one line item).
  useEffect(() => {
    if (!prefill) return;

    setFilters((prev) => ({
      ...prev,
      storeId: prefill.storeId ? String(prefill.storeId) : prev.storeId,
      itemTypeId: prefill.itemTypeId ? String(prefill.itemTypeId) : prev.itemTypeId,
      itemId: prefill.itemId ? String(prefill.itemId) : prev.itemId,
      inventoryNo: prefill.inventoryNo || prev.inventoryNo
    }));

    onPrefillConsumed?.();
  }, [prefill]);

  // Cascading Item picker: only items that actually exist (with stock > 0) in
  // the selected Store, further narrowed by the selected Item Type.
  useEffect(() => {
    if (!filters.storeId) {
      setStoreItems([]);
      return;
    }

    let cancelled = false;
    setLoadingItems(true);
    stockApi.searchStocks({
      storeId: filters.storeId,
      itemTypeId: filters.itemTypeId || null,
      stockAvailability: 'InStock',
      pageSize: 200
    })
      .then((result) => {
        if (cancelled) return;
        const stocks = result?.items || [];
        setStoreItems(stocks);
        // Drop a previously selected item that no longer matches the new Store/Item Type.
        setFilters((prev) => (
          prev.itemId && !(stocks || []).some((s) => String(s.itemId) === String(prev.itemId))
            ? { ...prev, itemId: '' }
            : prev
        ));
      })
      .catch((err) => {
        console.error('Error fetching store items:', err);
        if (!cancelled) setStoreItems([]);
      })
      .finally(() => {
        if (!cancelled) setLoadingItems(false);
      });

    return () => { cancelled = true; };
  }, [filters.storeId, filters.itemTypeId]);

  const fetchLookupData = async () => {
    try {
      const lookup = await returnInventoryApi.getLookupData();
      setLookupData(lookup);
    } catch (err) {
      console.error('Error fetching lookup data:', err);
      setError('Failed to fetch lookup data. Please try again.');
    }
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setFilters(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const selectedStoreItem = storeItems.find((s) => String(s.itemId) === String(filters.itemId));
  const availableQuantity = selectedStoreItem ? selectedStoreItem.totalItems ?? 0 : null;

  const formatDate = (dateString) => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleString('en-US', {
      month: 'short',
      day: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  // Get current date range for default filter
  const getTodayDateRange = () => {
    const today = new Date();
    const start = new Date(today.setHours(0, 0, 0, 0));
    const end = new Date(today.setHours(23, 59, 59, 999));

    return {
      start: start.toISOString().slice(0, 16),
      end: end.toISOString().slice(0, 16)
    };
  };

  useEffect(() => {
    const dateRange = getTodayDateRange();
    setFilters(prev => ({
      ...prev,
      startDate: dateRange.start,
      endDate: dateRange.end
    }));
  }, []);

  const downloadReturnPdf = (returnRecord) => {
    const doc = new jsPDF();
    const pageWidth = doc.internal.pageSize.width;

    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('Return Inventory Wrt Items', pageWidth / 2, 16, { align: 'center' });

    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    doc.text(`Return No: ${returnRecord.inventoryNo || '-'}`, 14, 26);
    doc.text(`Date: ${formatDate(returnRecord.returnDate)}`, pageWidth - 14, 26, { align: 'right' });
    doc.text(`Branch: ${returnRecord.branchName || '-'}`, 14, 32);
    doc.text(`Store: ${returnRecord.storeName || '-'}`, pageWidth - 14, 32, { align: 'right' });

    autoTable(doc, {
      startY: 40,
      head: [['Item', 'Item Type', 'Return Qty', 'PO Number', 'Inventory No.', 'Reason']],
      body: [[
        returnRecord.itemName || '-',
        returnRecord.itemTypeName || '-',
        returnRecord.returnQuantity,
        returnRecord.purchaseOrderNo || '-',
        returnRecord.inventoryNo || '-',
        returnRecord.reason || '-'
      ]],
      theme: 'grid',
      styles: { fontSize: 9, cellPadding: 3 },
      headStyles: { fillColor: [37, 99, 235], textColor: [255, 255, 255] }
    });

    const now = new Date();
    const timestamp = `${String(now.getDate()).padStart(2, '0')}-${String(now.getMonth() + 1).padStart(2, '0')}-${now.getFullYear()}_${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}`;
    doc.save(`ReturnInventory_${returnRecord.inventoryNo || timestamp}.pdf`);
  };

  const handleGenerateReport = async () => {
    setError(null);

    if (!filters.storeId || !filters.itemTypeId || !filters.itemId || !filters.quantity) {
      setError('Store, Item Type, Item and Quantity are required to process a return.');
      return;
    }

    const quantity = parseInt(filters.quantity, 10);
    if (!quantity || quantity < 1) {
      setError('Return quantity must be at least 1.');
      return;
    }

    if (availableQuantity != null && quantity > availableQuantity) {
      setError(`Only ${availableQuantity} unit(s) of this item are available in the selected store.`);
      return;
    }

    try {
      setSubmitting(true);

      const createPayload = {
        storeId: parseInt(filters.storeId, 10),
        itemTypeId: parseInt(filters.itemTypeId, 10),
        itemId: parseInt(filters.itemId, 10),
        returnQuantity: quantity,
        purchaseOrderNo: filters.purchaseOrderNo || null,
        inventoryNo: filters.inventoryNo || null,
        reason: filters.reason || null
      };

      const created = await returnInventoryApi.create(createPayload);

      downloadReturnPdf(created);

      // Refresh the list from the server so it stays consistent with what's displayed.
      await reloadReturns();

      // Reset the per-return inputs (keep Store/Item Type selected for convenience).
      setFilters((prev) => ({
        ...prev,
        itemId: '',
        quantity: '',
        purchaseOrderNo: '',
        inventoryNo: '',
        reason: ''
      }));
    } catch (err) {
      console.error('Error processing return:', err);
      setError(err.response?.data?.message || 'Failed to process return. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading && returns.length === 0) {
    return (
      <div className="flex justify-center items-center h-screen">
        <div className="text-gray-600">Loading...</div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-800 flex items-center">
          <span className="mr-2">↩️</span>
          Return Inventory Wrt Items
          <span className="ml-2 text-blue-600 cursor-pointer">ⓘ</span>
        </h1>
      </div>

      {(error || returnsError) && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-md">
          {error || 'Failed to fetch return inventory records. Please try again.'}
        </div>
      )}

      {/* Filters Section */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
          {/* Branch - locked to the logged-in user's own branch */}
          <BranchField />

          {/* Store - active stores only */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Store<span className="text-red-500">*</span>
            </label>
            <select
              name="storeId"
              value={filters.storeId}
              onChange={handleFilterChange}
              required
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Store</option>
              {lookupData.stores.map((store) => (
                <option key={store.id} value={store.id}>
                  {store.name}
                </option>
              ))}
            </select>
          </div>

          {/* Item Type - active item types only */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Item Type<span className="text-red-500">*</span>
            </label>
            <select
              name="itemTypeId"
              value={filters.itemTypeId}
              onChange={handleFilterChange}
              required
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Item Type</option>
              {lookupData.itemTypes.map((type) => (
                <option key={type.id} value={type.id}>
                  {type.name}
                </option>
              ))}
            </select>
          </div>

          {/* Item - only items in the selected Store + Item Type, with active stock */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Item<span className="text-red-500">*</span>
            </label>
            <select
              name="itemId"
              value={filters.itemId}
              onChange={handleFilterChange}
              required
              disabled={!filters.storeId}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
            >
              <option value="">
                {!filters.storeId ? 'Select a Store first' : loadingItems ? 'Loading items...' : 'Select Item'}
              </option>
              {storeItems.map((stock) => (
                <option key={stock.itemId} value={stock.itemId}>
                  {stock.itemName} ({stock.totalItems ?? 0} in stock)
                </option>
              ))}
            </select>
          </div>

          {/* Quantity */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Return Quantity<span className="text-red-500">*</span>
            </label>
            <input
              type="number"
              name="quantity"
              value={filters.quantity}
              onChange={handleFilterChange}
              min="1"
              max={availableQuantity != null ? availableQuantity : undefined}
              required
              placeholder="Quantity"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            {filters.itemId && (
              <p className="text-xs mt-1 text-gray-500">
                Available in store: {availableQuantity ?? 0}
              </p>
            )}
          </div>

          {/* Date Range Filter */}
          <div className="col-span-2">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Date Range Filter
            </label>
            <div className="flex items-center gap-2">
              <input
                type="datetime-local"
                name="startDate"
                value={filters.startDate}
                onChange={handleFilterChange}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <span className="text-gray-500">-</span>
              <input
                type="datetime-local"
                name="endDate"
                value={filters.endDate}
                onChange={handleFilterChange}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          {/* Purchase Order No */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Purchase Order No.
            </label>
            <input
              type="text"
              name="purchaseOrderNo"
              value={filters.purchaseOrderNo}
              onChange={handleFilterChange}
              placeholder="Optional - PO to return against"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Inventory No */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Inventory No.
            </label>
            <input
              type="text"
              name="inventoryNo"
              value={filters.inventoryNo}
              onChange={handleFilterChange}
              placeholder="Optional - GRN invoice to return against"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Reason */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Reason
            </label>
            <input
              type="text"
              name="reason"
              value={filters.reason}
              onChange={handleFilterChange}
              placeholder="Optional"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        {(filters.purchaseOrderNo || filters.inventoryNo) && (
          <p className="text-xs text-amber-600 mb-4">
            This return will also reduce the remaining quantity on the specified {filters.purchaseOrderNo && 'Purchase Order'}
            {filters.purchaseOrderNo && filters.inventoryNo && ' and '}
            {filters.inventoryNo && 'GRN Invoice'} for this item.
          </p>
        )}

        {/* Generate Report Button */}
        <div className="flex justify-end">
          <button
            onClick={handleGenerateReport}
            disabled={submitting}
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-gray-400"
          >
            {submitting ? 'Processing...' : 'Generate Report'}
          </button>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Serial
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Inventory No.
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  PO Number
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Items
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Return Quantity
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Item Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Vendor
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Store
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Return Date
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {returns.length === 0 ? (
                <tr>
                  <td colSpan="10" className="px-6 py-4 text-center text-sm text-gray-500">
                    {loading ? 'Loading...' : 'No data available in table'}
                  </td>
                </tr>
              ) : (
                returns.map((ret, index) => (
                  <tr key={ret.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {(currentPage - 1) * entriesPerPage + index + 1}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {ret.inventoryNo || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {ret.purchaseOrderNo || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {ret.itemName}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {ret.returnQuantity}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {ret.itemTypeName || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {ret.vendorName || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {ret.storeName || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(ret.returnDate)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button
                        onClick={() => downloadReturnPdf(ret)}
                        className="text-blue-600 hover:text-blue-900"
                        title="Download PDF"
                      >
                        PDF
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Pagination
        currentPage={currentPage}
        pageSize={entriesPerPage}
        totalCount={totalCount}
        onPageChange={goToPage}
        onPageSizeChange={setEntriesPerPage}
      />
    </div>
  );
};

export default ReturnInventoryPage;
