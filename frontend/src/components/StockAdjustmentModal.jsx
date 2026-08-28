import React, { useState, useEffect } from 'react';
import itemApi from '../services/itemApi';
import stockAdjustmentApi from '../services/stockAdjustmentApi';
import stockApi from '../services/stockApi';
import inventoryApi from '../services/inventoryApi';
import { productOptionValue, parseProductOptionValue, quantityForProduct } from '../utils/productKey';

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

const StockAdjustmentModal = ({ isOpen, onClose, onSubmit, adjustment, stores, branches, defaultStoreId }) => {
  const [formData, setFormData] = useState({
    storeId: '',
    branchId: '',
    type: 1, // 1 = Less/Decrease, 2 = Issue
    itemId: '',
    medicineId: '',
    subServiceId: '',
    stockTypeId: '', // defaults to the real "Regular" stock type once lookup data loads
    quantity: 1,
    saleValue: 0,
    remarks: ''
  });

  const [items, setItems] = useState([]);
  const [stockTypes, setStockTypes] = useState([]);
  const [itemQuantities, setItemQuantities] = useState({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadLookupData();
  }, []);

  // Per-store on-hand quantities for the item dropdown (e.g. "Syringe 10ml - 8") -
  // reloads whenever the selected store changes, since quantity is store-specific.
  useEffect(() => {
    if (!formData.storeId) {
      setItemQuantities({});
      return;
    }

    let cancelled = false;
    stockApi.getQuantitiesByStore(formData.storeId)
      .then((data) => {
        if (!cancelled) setItemQuantities(data || {});
      })
      .catch((err) => {
        console.error('Error loading item quantities for store:', err);
        if (!cancelled) setItemQuantities({});
      });

    return () => { cancelled = true; };
  }, [formData.storeId]);

  useEffect(() => {
    if (adjustment) {
      // Load existing adjustment data
      setFormData({
        storeId: adjustment.storeId || '',
        branchId: adjustment.branchId || '',
        type: adjustment.type || 1,
        itemId: adjustment.details?.[0]?.itemId || '',
        medicineId: adjustment.details?.[0]?.medicineId || '',
        subServiceId: adjustment.details?.[0]?.subServiceId || '',
        stockTypeId: adjustment.details?.[0]?.stockTypeId || 1,
        quantity: adjustment.details?.[0]?.quantity || 1,
        saleValue: adjustment.details?.[0]?.saleValue || 0,
        remarks: ''
      });
    } else {
      // New adjustment: default the branch (first branch if available) and carry the
      // last-used store forward so the user isn't asked to re-pick it every time.
      setFormData(prev => ({
        ...prev,
        storeId: defaultStoreId || prev.storeId,
        branchId: (branches && branches.length > 0) ? branches[0].id : prev.branchId
      }));
    }
  }, [adjustment, branches, defaultStoreId]);

  const loadLookupData = async () => {
    try {
      const [unifiedItems, data] = await Promise.all([
        itemApi.getAllWithMedicines(),
        inventoryApi.getLookupData()
      ]);
      setItems((unifiedItems || []).filter((row) => row.isActive));
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

  const handleItemChange = (e) => {
    setFormData(prev => ({ ...prev, ...parseProductOptionValue(e.target.value) }));
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
            itemId: formData.itemId || null,
            medicineId: formData.medicineId || null,
            subServiceId: formData.subServiceId || null,
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

      onSubmit(formData.storeId);
    } catch (err) {
      console.error('Error saving stock adjustment:', err);
      setError(err.response?.data?.message || 'Failed to save stock adjustment. Please try again.');
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
                value={productOptionValue(formData)}
                onChange={handleItemChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Select</option>
                {items
                  .filter((item) => {
                    // Decrease is an outbound action - only show items actually in stock at
                    // the selected store. Increase is inbound (correcting stock upward, often
                    // from zero) so the full active list stays available for that type.
                    if (!formData.storeId || parseInt(formData.type) !== 1) return true;
                    return quantityForProduct(itemQuantities, item) > 0;
                  })
                  .map(item => {
                    const label = item.sourceType === 'Item' ? item.name : `${item.name} (${item.sourceType})`;
                    const qty = quantityForProduct(itemQuantities, item);
                    return (
                      <option key={productOptionValue(item)} value={productOptionValue(item)}>
                        {formData.storeId ? `${label} - ${qty}` : label}
                      </option>
                    );
                  })}
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
                  <option value={1}>Less / Decrease</option>
                  <option value={2}>Issue (Increase)</option>
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
