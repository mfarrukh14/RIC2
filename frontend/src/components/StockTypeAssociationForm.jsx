import React, { useState, useEffect } from 'react';
import { XMarkIcon } from '@heroicons/react/24/outline';
import stockTypeAssociationsApi from '../services/stockTypeAssociationsApi';
import inventoryApi from '../services/inventoryApi';
import stockTypesApi from '../services/stockTypesApi';

const StockTypeAssociationForm = ({ association, onSave, onCancel, isEditing = false }) => {
  const [formData, setFormData] = useState({
    pharmacyStoreId: '',
    stockTypes: '',
    patientTypes: 1, // Default to Regular
  });
  const [stores, setStores] = useState([]);
  const [stockTypes, setStockTypes] = useState([]);
  const [loading, setLoading] = useState(false);
  const [loadingData, setLoadingData] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadLookupData();
  }, []);

  useEffect(() => {
    if (association) {
      setFormData({
        pharmacyStoreId: association.pharmacyStoreId || '',
        stockTypes: association.stockTypes || '',
        patientTypes: association.patientTypes || 1,
      });
    }
  }, [association]);

  const loadLookupData = async () => {
    try {
      setLoadingData(true);
      
      // Load inventory lookup data (includes stores)
      const lookupData = await inventoryApi.getLookupData();
      setStores(lookupData.stores || []);
      
      // Load stock types
      const stockTypesData = await stockTypesApi.getAllStockTypes();
      setStockTypes(stockTypesData || []);
      
      setError(null);
    } catch (err) {
      setError('Failed to load lookup data: ' + (err.response?.data || err.message));
      console.error('Error loading lookup data:', err);
    } finally {
      setLoadingData(false);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'patientTypes' ? parseInt(value) : (name === 'pharmacyStoreId' || name === 'stockTypes' ? parseInt(value) : value)
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      if (isEditing && association) {
        await stockTypeAssociationsApi.updateStockTypeAssociation(association.id, formData);
      } else {
        await stockTypeAssociationsApi.createStockTypeAssociation(formData);
      }
      onSave();
    } catch (err) {
      const errorMessage = err.response?.data?.message || 
                          err.response?.data || 
                          err.message || 
                          'An error occurred';
      setError(errorMessage);
      console.error('Error saving stock type association:', err);
    } finally {
      setLoading(false);
    }
  };

  if (loadingData) {
    return (
      <div className="bg-white shadow-sm rounded-lg">
        <div className="flex justify-center items-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white shadow-sm rounded-lg">
      {/* Header */}
      <div className="px-6 py-4 border-b border-gray-200 flex justify-between items-center">
        <h2 className="text-2xl font-bold text-gray-900">
          {isEditing ? 'Edit' : 'Add'} Stock Type Association
        </h2>
        <button
          onClick={onCancel}
          className="text-gray-400 hover:text-gray-600 transition-colors"
          title="Close"
        >
          <XMarkIcon className="w-6 h-6" />
        </button>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="px-6 py-6">
        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-red-600">{error}</p>
          </div>
        )}

        <div className="grid grid-cols-1 gap-6">
          {/* Store Dropdown */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Store <span className="text-red-500">*</span>
            </label>
            <select
              name="pharmacyStoreId"
              value={formData.pharmacyStoreId}
              onChange={handleChange}
              required
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="">Select Store</option>
              {stores.map((store) => (
                <option key={store.id} value={store.id}>
                  {store.name}
                </option>
              ))}
            </select>
          </div>

          {/* Stock Types Dropdown */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Stock Types <span className="text-red-500">*</span>
            </label>
            <select
              name="stockTypes"
              value={formData.stockTypes}
              onChange={handleChange}
              required
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="">Select Stock Type</option>
              {stockTypes.map((stockType) => (
                <option key={stockType.id} value={stockType.id}>
                  {stockType.name}
                </option>
              ))}
            </select>
          </div>

          {/* Patient Types Radio Buttons */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Patient Types
            </label>
            <div className="flex gap-6">
              <label className="flex items-center">
                <input
                  type="radio"
                  name="patientTypes"
                  value="1"
                  checked={formData.patientTypes === 1}
                  onChange={handleChange}
                  className="mr-2 h-4 w-4 text-blue-600 focus:ring-blue-500"
                />
                <span className="text-sm text-gray-700">Regular</span>
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="patientTypes"
                  value="2"
                  checked={formData.patientTypes === 2}
                  onChange={handleChange}
                  className="mr-2 h-4 w-4 text-blue-600 focus:ring-blue-500"
                />
                <span className="text-sm text-gray-700">Entitle</span>
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="patientTypes"
                  value="3"
                  checked={formData.patientTypes === 3}
                  onChange={handleChange}
                  className="mr-2 h-4 w-4 text-blue-600 focus:ring-blue-500"
                />
                <span className="text-sm text-gray-700">Panel</span>
              </label>
            </div>
          </div>
        </div>

        {/* Form Actions */}
        <div className="mt-8 flex justify-end gap-3">
          <button
            type="button"
            onClick={onCancel}
            className="px-6 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={loading}
            className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:bg-blue-300 disabled:cursor-not-allowed"
          >
            {loading ? 'Saving...' : 'Submit'}
          </button>
        </div>
      </form>
    </div>
  );
};

export default StockTypeAssociationForm;
