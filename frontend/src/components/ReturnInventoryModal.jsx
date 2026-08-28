import React, { useState, useEffect } from 'react';
import { XMarkIcon } from '@heroicons/react/24/outline';
import inventoryApi from '../services/inventoryApi';
import returnInventoryApi from '../services/returnInventoryApi';

// Return Inventory modal launched from Add Inventory's row action - lets the
// user check any of that invoice's line items, cap the return at what's still
// available (received minus already returned), and submit them all as one
// batch return. Replaces the old full-page redirect to ReturnInventoryPage,
// matching the legacy system's invoice-scoped modal.
const ReturnInventoryModal = ({ isOpen, onClose, inventory, onSuccess }) => {
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [invoiceNo, setInvoiceNo] = useState('');
  const [items, setItems] = useState([]);
  const [adjustmentRemarks, setAdjustmentRemarks] = useState('');
  const [adjustmentAmount, setAdjustmentAmount] = useState('');

  useEffect(() => {
    if (!isOpen || !inventory) return;

    let cancelled = false;
    setLoading(true);
    setError(null);
    setAdjustmentRemarks('');
    setAdjustmentAmount('');

    inventoryApi.getReturnableItems(inventory.id)
      .then((data) => {
        if (cancelled) return;
        setInvoiceNo(data.invoiceNo || '');
        setItems((data.items || []).map((item) => ({
          ...item,
          selected: false,
          returnQuantity: ''
        })));
      })
      .catch((err) => {
        console.error('Error loading returnable items:', err);
        if (!cancelled) setError("Failed to load this invoice's items. Please try again.");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => { cancelled = true; };
  }, [isOpen, inventory]);

  if (!isOpen) return null;

  const selectableItems = items.filter((item) => item.availableQuantity > 0);
  const allSelected = selectableItems.length > 0 && selectableItems.every((item) => item.selected);

  const toggleAll = () => {
    const nextSelected = !allSelected;
    setItems((prev) => prev.map((item) => (
      item.availableQuantity > 0 ? { ...item, selected: nextSelected } : item
    )));
  };

  const toggleItem = (detailId) => {
    setItems((prev) => prev.map((item) => (
      item.inventoryDetailId === detailId ? { ...item, selected: !item.selected } : item
    )));
  };

  const changeReturnQuantity = (detailId, value) => {
    setItems((prev) => prev.map((item) => (
      item.inventoryDetailId === detailId ? { ...item, returnQuantity: value } : item
    )));
  };

  const selectedItems = items.filter((item) => item.selected);
  const totalAmount = selectedItems.reduce((sum, item) => {
    const qty = Number(item.returnQuantity) || 0;
    return sum + qty * (item.unitBuyingPrice || 0);
  }, 0);
  const parsedAdjustment = adjustmentAmount === '' ? 0 : Number(adjustmentAmount) || 0;
  const returnAmount = totalAmount + parsedAdjustment;

  const hasInvalidQuantity = selectedItems.some((item) => {
    const qty = Number(item.returnQuantity);
    return !item.returnQuantity || !Number.isFinite(qty) || qty <= 0 || qty > item.availableQuantity;
  });

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (selectedItems.length === 0 || hasInvalidQuantity) return;

    setSubmitting(true);
    setError(null);
    try {
      await returnInventoryApi.createBatch({
        inventoryId: inventory.id,
        storeId: inventory.storeId,
        adjustmentAmount: adjustmentAmount === '' ? null : parsedAdjustment,
        adjustmentRemarks: adjustmentRemarks || null,
        lines: selectedItems.map((item) => ({
          inventoryDetailId: item.inventoryDetailId,
          itemId: item.itemId,
          medicineId: item.medicineId,
          subServiceId: item.subServiceId,
          returnQuantity: Number(item.returnQuantity)
        }))
      });
      onSuccess?.();
      onClose();
    } catch (err) {
      console.error('Error submitting return:', err);
      setError(err.response?.data?.message || 'Failed to submit the return. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-3xl max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between border-b px-6 py-4">
          <h2 className="text-lg font-semibold text-gray-900">Return Inventory/Purchase Order</h2>
          <button type="button" onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <XMarkIcon className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded text-sm">{error}</div>
          )}

          <div className="flex items-center gap-3">
            <span className="text-sm font-medium text-green-700">Invoice No</span>
            <span className="px-3 py-1 bg-red-600 text-white text-sm font-semibold rounded">
              {invoiceNo || '-'}
            </span>
          </div>

          {loading ? (
            <div className="py-8 text-center text-sm text-gray-500">Loading items...</div>
          ) : items.length === 0 ? (
            <div className="py-8 text-center text-sm text-gray-500">This invoice has no line items.</div>
          ) : (
            <div className="overflow-x-auto border border-gray-200 rounded-md">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-3 py-2">
                      <input type="checkbox" checked={allSelected} onChange={toggleAll} disabled={selectableItems.length === 0} />
                    </th>
                    <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
                    <th className="px-3 py-2 text-center text-xs font-medium text-gray-500 uppercase">Received Quantity</th>
                    <th className="px-3 py-2 text-center text-xs font-medium text-gray-500 uppercase">Available Quantity</th>
                    <th className="px-3 py-2 text-center text-xs font-medium text-gray-500 uppercase">Buying Price</th>
                    <th className="px-3 py-2 text-center text-xs font-medium text-gray-500 uppercase">Return Quantity</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {items.map((item) => {
                    const outOfStock = item.availableQuantity <= 0;
                    const qty = Number(item.returnQuantity);
                    const invalid = item.selected && (!item.returnQuantity || !Number.isFinite(qty) || qty <= 0 || qty > item.availableQuantity);
                    return (
                      <tr key={item.inventoryDetailId} className={item.selected ? 'bg-blue-50' : outOfStock ? 'opacity-50' : ''}>
                        <td className="px-3 py-3">
                          <input
                            type="checkbox"
                            checked={item.selected}
                            disabled={outOfStock}
                            onChange={() => toggleItem(item.inventoryDetailId)}
                          />
                        </td>
                        <td className="px-3 py-3 text-sm text-gray-900">{item.itemName || '-'}</td>
                        <td className="px-3 py-3 text-sm text-gray-500 text-center">{item.receivedQuantity}</td>
                        <td className="px-3 py-3 text-sm text-gray-500 text-center">{item.availableQuantity}</td>
                        <td className="px-3 py-3 text-sm text-gray-500 text-center">{(item.unitBuyingPrice ?? 0).toFixed(2)}</td>
                        <td className="px-3 py-3">
                          <input
                            type="number"
                            min="1"
                            max={item.availableQuantity}
                            value={item.returnQuantity}
                            disabled={!item.selected}
                            onChange={(e) => changeReturnQuantity(item.inventoryDetailId, e.target.value)}
                            className={`w-24 px-2 py-1 border rounded-md text-sm text-center ${invalid ? 'border-red-400' : 'border-gray-300'}`}
                          />
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}

          <div className="flex justify-end">
            <div className="w-full max-w-sm space-y-3">
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-700">Total Amount</span>
                <span className="font-medium text-gray-900">{totalAmount.toFixed(2)}</span>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Adjustment Remarks</label>
                <input
                  type="text"
                  value={adjustmentRemarks}
                  onChange={(e) => setAdjustmentRemarks(e.target.value)}
                  placeholder="Adjustment Remarks"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Adjustment Amount</label>
                <input
                  type="number"
                  step="0.01"
                  value={adjustmentAmount}
                  onChange={(e) => setAdjustmentAmount(e.target.value)}
                  placeholder="Adjustment Amount"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm"
                />
              </div>

              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-700">Return Amount</span>
                <span className="font-semibold text-gray-900">{returnAmount.toFixed(2)}</span>
              </div>
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-2 border-t">
            <button type="button" onClick={onClose} className="px-4 py-2 border border-gray-300 rounded-md text-sm text-gray-700 hover:bg-gray-50">
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting || loading || selectedItems.length === 0 || hasInvalidQuantity}
              className="px-6 py-2 bg-indigo-600 text-white rounded-md text-sm hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {submitting ? 'Returning...' : 'Return'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ReturnInventoryModal;
