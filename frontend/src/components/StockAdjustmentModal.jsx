import React, { useState, useEffect } from 'react';
import inventoryApi from '../services/inventoryApi';
import stockAdjustmentApi from '../services/stockAdjustmentApi';

const normalizeLookupOptions = (items, idKeys, nameKeys, fallbackLabel) =>
  (items || [])
    .map((item, index) => {
      const id = idKeys.map((key) => item?.[key]).find((value) => value !== null && value !== undefined && value !== '');
      if (id === null || id === undefined || id === '') {
        return null;
      }

      const name = nameKeys.map((key) => item?.[key]).find((value) => value !== null && value !== undefined && value !== '');
      return {
        id,
        name: name ?? `${fallbackLabel} ${index + 1}`,
      };
    })
    .filter(Boolean);

const StockAdjustmentModal = ({ isOpen, onClose, onSubmit, adjustment, stores, branches }) => {
  const [formData, setFormData] = useState({
    storeId: '',
    branchId: '',
    type: 1, // 1 = Less/Decrease, 2 = Issue
    itemId: '',
    stockTypeId: '', // defaults to the real "Regular" stock type once lookup data loads
    quantity: 1,
    saleValue: 0,
    remarks: ''
  });

  const [items, setItems] = useState([]);
  const [stockTypes, setStockTypes] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadLookupData();
  }, []);

  useEffect(() => {
    if (adjustment) {
      // Load existing adjustment data
      setFormData({
        storeId: adjustment.storeId || '',
        branchId: adjustment.branchId || '',
        type: adjustment.type || 1,
        itemId: adjustment.details?.[0]?.itemId || '',
        stockTypeId: adjustment.details?.[0]?.stockTypeId || 1,
        quantity: adjustment.details?.[0]?.quantity || 1,
        saleValue: adjustment.details?.[0]?.saleValue || 0,
        remarks: ''
      });
    } else {
      // Set default branch (first branch if available)
      if (branches && branches.length > 0) {
        setFormData(prev => ({
          ...prev,
          branchId: branches[0].id
        }));
      }
    }
  }, [adjustment, branches]);

  const loadLookupData = async () => {
    try {
      const data = await inventoryApi.getLookupData();
      setItems(normalizeLookupOptions(data.items, ['id', 'itemId'], ['name', 'itemName'], 'Item'));
      const loadedStockTypes = normalizeLookupOptions(data.stockTypes, ['id', 'stockTypeId'], ['name', 'stockTypeName'], 'Stock Type');
      setStockTypes(loadedStockTypes);

      // Default new adjustments to the real "Regular" stock type instead of faking it
      // with a duplicate hardcoded option.
      if (!adjustment) {
        const regular = loadedStockTypes.find((t) => t.name?.trim().toLowerCase() === 'regular');
        if (regular) {
          setFormData((prev) => ({ ...prev, stockTypeId: prev.stockTypeId || regular.id }));
        }
      }
    } catch (err) {
      console.error('Error loading lookup data:', err);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const payload = {
        storeId: formData.storeId,
        branchId: formData.branchId,
        type: parseInt(formData.type),
        details: [
          {
            itemId: parseInt(formData.itemId),
            type: parseInt(formData.type),
            stockTypeId: parseInt(formData.stockTypeId),
            quantity: parseFloat(formData.quantity),
            saleValue: parseFloat(formData.saleValue) || 0,
            remarks: formData.remarks
          }
        ]
      };

      if (adjustment) {
        // Update existing
        await stockAdjustmentApi.update(adjustment.id, {
          ...payload,
          id: adjustment.id
        });
      } else {
        // Create new
        await stockAdjustmentApi.create(payload);
      }

      onSubmit();
    } catch (err) {
      console.error('Error saving stock adjustment:', err);
      setError('Failed to save stock adjustment. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          <h2 className="text-xl font-semibold mb-4">
            {adjustment ? 'Edit Stock Adjustment' : 'Add Stock Adjustment'}
          </h2>

          {error && (
            <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Store - Full Width with Select Dropdown */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Store<span className="text-red-500">*</span>
              </label>
              <select
                name="storeId"
                value={formData.storeId}
                onChange={handleChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Select</option>
                {(stores || []).map(store => (
                  <option key={store.id} value={store.id}>
                    {store.name}
                  </option>
                ))}
              </select>
            </div>

            {/* Item - Full Width with Select Dropdown */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Item<span className="text-red-500">*</span>
              </label>
              <select
                name="itemId"
                value={formData.itemId}
                onChange={handleChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Select</option>
                {items.map(item => (
                  <option key={item.id} value={item.id}>
                    {item.name}
                  </option>
                ))}
              </select>
            </div>

            {/* Type and Stock Type - Side by Side */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Type<span className="text-red-500">*</span>
                </label>
                <select
                  name="type"
                  value={formData.type}
                  onChange={handleChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value={1}>Less/ Decrease/ Issue</option>
                  <option value={2}>Issue</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Stock Type<span className="text-red-500">*</span>
                </label>
                <select
                  name="stockTypeId"
                  value={formData.stockTypeId}
                  onChange={handleChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Select</option>
                  {stockTypes.map(st => (
                    <option key={st.id} value={st.id}>
                      {st.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            {/* Quantity and Sale Value - Side by Side */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Quantity<span className="text-red-500">*</span>
                </label>
                <input
                  type="number"
                  name="quantity"
                  value={formData.quantity}
                  onChange={handleChange}
                  min="1"
                  step="1"
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Sale Value<span className="text-red-500">*</span>
                </label>
                <input
                  type="number"
                  name="saleValue"
                  value={formData.saleValue}
                  onChange={handleChange}
                  min="0"
                  step="0.01"
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>

            {/* Remarks - Full Width */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Remarks
              </label>
              <textarea
                name="remarks"
                value={formData.remarks}
                onChange={handleChange}
                rows="3"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter any remarks..."
              />
            </div>

            {/* Action Buttons */}
            <div className="flex justify-end space-x-3 pt-4">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? 'Saving...' : 'Submit'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default StockAdjustmentModal;
