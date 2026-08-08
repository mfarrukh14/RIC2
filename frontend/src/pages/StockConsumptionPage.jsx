import React,{ useCallback, useState, useEffect } from 'react';
import { PlusIcon, PencilIcon, TrashIcon, XMarkIcon } from '@heroicons/react/24/outline';
import {
  getAllStockConsumptions,
  createStockConsumption,
  updateStockConsumption,
  deleteStockConsumption,
  getStockConsumptionById
} from '../services/stockConsumptionApi';
import { getAllStores } from '../services/storeApi';
import itemApi from '../services/itemApi';
import stockApi from '../services/stockApi';
import { stockTypesApi } from '../services/stockTypesApi';
import { productOptionValue, parseProductOptionValue } from '../utils/productKey';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';

const StockConsumptionPage = () => {
  const [stores, setStores] = useState([]);
  const [items, setItems] = useState([]);
  const [stockTypes, setStockTypes] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [error, setError] = useState(null);

  const [searchTerm, setSearchTerm] = useState('');

  const fetchPage = useCallback(async (params) => {
    const data = await getAllStockConsumptions(params);
    return { items: data.items || [], totalCount: data.totalCount || 0 };
  }, []);

  const {
    items: consumptions,
    totalCount,
    currentPage,
    pageSize,
    setPageSize,
    goToPage,
    loading,
    reload: loadConsumptions,
  } = usePagedList(fetchPage, { searchTerm }, { initialPageSize: 10 });

  const [submitting, setSubmitting] = useState(false);
  const [itemQuantities, setItemQuantities] = useState({});

  const [formData, setFormData] = useState({
    storeId: '',
    branchId: 1,
    remarks: '',
    details: [
      {
        itemId: '',
        medicineId: '',
        subServiceId: '',
        stockTypeId: '',
        quantity: '',
        storeId: ''
      }
    ]
  });

  useEffect(() => {
    loadLookups();
  }, []);

  // Consumption is an outbound action (using up stock) - the item dropdown
  // should only offer items actually on hand at the selected store, with
  // their live quantity shown inline (e.g. "Syringe 10ml - 8").
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

  const loadLookups = async () => {
    try {
      const [storesData, itemsData, stockTypesData] = await Promise.all([
        getAllStores(),
        itemApi.getAllWithMedicines(),
        stockTypesApi.getAllStockTypes()
      ]);
      setStores(storesData);
      setItems(itemsData);
      setStockTypes(stockTypesData);
    } catch (err) {
      setError('Failed to load data: ' + err.message);
    }
  };

  const resetForm = () => {
    setFormData({
      storeId: '',
      branchId: 1,
      remarks: '',
      details: [
        {
          itemId: '',
          medicineId: '',
          subServiceId: '',
          stockTypeId: '',
          quantity: '',
          storeId: ''
        }
      ]
    });
    setEditingId(null);
    setShowForm(false);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const filteredItems = items.filter(item => {
    if (!item.isActive) return false;
    if (!formData.storeId || item.itemId == null) return true;
    return (itemQuantities[item.itemId] ?? 0) > 0;
  });

  const handleDetailChange = (index, field, value) => {
    const newDetails = [...formData.details];
    if (field === 'itemId') {
      newDetails[index] = { ...newDetails[index], ...parseProductOptionValue(value) };
    } else {
      newDetails[index] = {
        ...newDetails[index],
        [field]: field === 'stockTypeId' ? parseInt(value) : value
      };
    }
    setFormData(prev => ({
      ...prev,
      details: newDetails
    }));
  };

  const addDetailRow = () => {
    setFormData(prev => ({
      ...prev,
      details: [
        ...prev.details,
        {
          itemId: '',
          medicineId: '',
          subServiceId: '',
          stockTypeId: '',
          quantity: '',
          storeId: formData.storeId
        }
      ]
    }));
  };

  const removeDetailRow = (index) => {
    if (formData.details.length > 1) {
      const newDetails = formData.details.filter((_, i) => i !== index);
      setFormData(prev => ({
        ...prev,
        details: newDetails
      }));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);

    try {
      const payload = {
        storeId: parseInt(formData.storeId),
        branchId: parseInt(formData.branchId),
        // TODO: this used to be derived from the picked item's itemTypeId, but
        // itemApi.getAllWithMedicines() doesn't return that field (it wasn't
        // meaningful for Medicine/Disposable rows anyway) - confirm with backend
        // whether Type still needs real per-item classification here.
        type: 0,
        remarks: formData.remarks,
        details: formData.details.map(detail => ({
          itemId: detail.itemId || null,
          medicineId: detail.medicineId || null,
          subServiceId: detail.subServiceId || null,
          stockTypeId: parseInt(detail.stockTypeId),
          quantity: parseFloat(detail.quantity),
          type: 0
        }))
      };

      if (editingId) {
        await updateStockConsumption(editingId, payload);
      } else {
        await createStockConsumption(payload);
      }

      await loadConsumptions();
      resetForm();
    } catch (err) {
      setError('Failed to save: ' + (err.response?.data?.message || err.message));
    } finally {
      setSubmitting(false);
    }
  };

  const handleEdit = async (id) => {
    try {
      const data = await getStockConsumptionById(id);
      setFormData({
        storeId: data.storeId,
        branchId: data.branchId,
        remarks: data.remarks || '',
        details: data.details.map(d => ({
          itemId: d.itemId,
          medicineId: d.medicineId,
          subServiceId: d.subServiceId,
          stockTypeId: d.stockTypeId,
          quantity: d.quantity,
          storeId: d.storeId
        }))
      });
      setEditingId(id);
      setShowForm(true);
    } catch (err) {
      setError('Failed to load consumption: ' + err.message);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this stock consumption?')) {
      try {
        await deleteStockConsumption(id);
        await loadConsumptions();
      } catch (err) {
        setError('Failed to delete: ' + err.message);
      }
    }
  };

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Stock Consumption</h1>
        {!showForm && (
          <button
            onClick={() => setShowForm(true)}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2"
          >
            <PlusIcon className="h-5 w-5" />
            Add Stock Consumption
          </button>
        )}
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
          {error}
        </div>
      )}

      {showForm && (
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-semibold text-gray-800">
              {editingId ? 'Edit Stock Consumption' : 'New Stock Consumption'}
            </h2>
            <button
              onClick={resetForm}
              className="text-gray-500 hover:text-gray-700"
            >
              <XMarkIcon className="h-6 w-6" />
            </button>
          </div>

          <form onSubmit={handleSubmit}>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Store <span className="text-red-500">*</span>
                </label>
                <select
                  name="storeId"
                  value={formData.storeId}
                  onChange={handleInputChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Select Store</option>
                  {stores.map(store => (
                    <option key={store.storeId} value={store.storeId}>
                      {store.storeName}
                    </option>
                  ))}
                </select>
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Remarks
                </label>
                <textarea
                  name="remarks"
                  value={formData.remarks}
                  onChange={handleInputChange}
                  rows="3"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>

            <div className="mb-4">
              <div className="flex justify-between items-center mb-3">
                <h3 className="text-lg font-semibold text-gray-800">Details</h3>
                <button
                  type="button"
                  onClick={addDetailRow}
                  className="bg-green-600 text-white px-3 py-1 rounded hover:bg-green-700 flex items-center gap-1 text-sm"
                >
                  <PlusIcon className="h-4 w-4" />
                  Add Item
                </button>
              </div>

              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Item</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Stock Type</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Quantity</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {formData.details.map((detail, index) => (
                      <tr key={index}>
                        <td className="px-4 py-3">
                          <select
                            value={productOptionValue(detail)}
                            onChange={(e) => handleDetailChange(index, 'itemId', e.target.value)}
                            required
                            className="w-full px-2 py-1 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                          >
                            <option value="">Select Item</option>
                            {filteredItems.map(item => {
                              const label = item.sourceType === 'Item' ? item.name : `${item.name} (${item.sourceType})`;
                              const qty = item.itemId != null ? itemQuantities[item.itemId] ?? 0 : null;
                              return (
                                <option key={productOptionValue(item)} value={productOptionValue(item)}>
                                  {formData.storeId && qty !== null ? `${label} - ${qty}` : label}
                                </option>
                              );
                            })}
                          </select>
                        </td>
                        <td className="px-4 py-3">
                          <select
                            value={detail.stockTypeId}
                            onChange={(e) => handleDetailChange(index, 'stockTypeId', e.target.value)}
                            required
                            className="w-full px-2 py-1 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                          >
                            <option value="">Select Stock Type</option>
                            {stockTypes.map(type => (
                              <option key={type.stockTypeId || type.id} value={type.stockTypeId || type.id}>
                                {type.stockTypeName || type.name}
                              </option>
                            ))}
                          </select>
                        </td>
                        <td className="px-4 py-3">
                          <input
                            type="number"
                            value={detail.quantity}
                            onChange={(e) => handleDetailChange(index, 'quantity', e.target.value)}
                            required
                            min="0.01"
                            step="0.01"
                            className="w-full px-2 py-1 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                          />
                        </td>
                        <td className="px-4 py-3">
                          {formData.details.length > 1 && (
                            <button
                              type="button"
                              onClick={() => removeDetailRow(index)}
                              className="text-red-600 hover:text-red-800"
                            >
                              <TrashIcon className="h-5 w-5" />
                            </button>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="flex justify-end gap-3 mt-6">
              <button
                type="button"
                onClick={resetForm}
                className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={submitting}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
              >
                {submitting ? 'Saving...' : editingId ? 'Update' : 'Save'}
              </button>
            </div>
          </form>
        </div>
      )}

      {!showForm && (
        <div className="bg-white rounded-lg shadow-md overflow-hidden">
          <div className="flex justify-end px-4 py-3 border-b border-gray-200">
            <input
              type="text"
              placeholder="Search..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 w-64"
            />
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Store
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Item
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Type
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Stock Type
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Quantity
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Created By
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Date
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {loading ? (
                  <tr>
                    <td colSpan="8" className="px-6 py-4 text-center text-gray-500">
                      Loading...
                    </td>
                  </tr>
                ) : consumptions.length === 0 ? (
                  <tr>
                    <td colSpan="8" className="px-6 py-4 text-center text-gray-500">
                      No stock consumptions found
                    </td>
                  </tr>
                ) : (
                  consumptions.map((consumption) => (
                    <tr key={consumption.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {consumption.storeName}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {consumption.itemName}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {consumption.type}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {consumption.stockType}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {consumption.quantity}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {consumption.createdBy}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {new Date(consumption.createdOn).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <button
                          onClick={() => handleEdit(consumption.id)}
                          className="text-blue-600 hover:text-blue-900 mr-3"
                        >
                          <PencilIcon className="h-5 w-5" />
                        </button>
                        <button
                          onClick={() => handleDelete(consumption.id)}
                          className="text-red-600 hover:text-red-900"
                        >
                          <TrashIcon className="h-5 w-5" />
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
          <Pagination
            currentPage={currentPage}
            pageSize={pageSize}
            totalCount={totalCount}
            onPageChange={goToPage}
            onPageSizeChange={setPageSize}
          />
        </div>
      )}
    </div>
  );
};

export default StockConsumptionPage;
