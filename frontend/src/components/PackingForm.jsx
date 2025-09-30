import React, { useState, useEffect } from 'react';
import { XMarkIcon } from '@heroicons/react/24/outline';
import { packingApi } from '../services/packingApi';

const PackingForm = ({ packing, onSave, onCancel, isEditing = false }) => {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    pack: '',
    leaf: '',
    numberOfItems: '',
    branchId: 1,
    isActive: true,
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (packing) {
      setFormData({
        name: packing.name || '',
        description: packing.description || '',
        pack: packing.pack || '',
        leaf: packing.leaf || '',
        numberOfItems: packing.numberOfItems || '',
        branchId: packing.branchId || 1,
        isActive: packing.isActive ?? true,
      });
    }
  }, [packing]);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const submitData = {
        ...formData,
        pack: formData.pack ? parseInt(formData.pack) : null,
        leaf: formData.leaf ? parseInt(formData.leaf) : null,
        numberOfItems: formData.numberOfItems ? parseInt(formData.numberOfItems) : null,
      };

      if (isEditing && packing) {
        await packingApi.update(packing.id, submitData);
      } else {
        await packingApi.create(submitData);
      }
      onSave();
    } catch (err) {
      const errorMessage = err.response?.data?.message || 
                          err.response?.data || 
                          err.message || 
                          'An error occurred';
      setError(errorMessage);
      console.error('Error saving packing:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <h1 className="text-2xl font-bold text-gray-900">
              {isEditing ? 'Edit Packing Type' : 'Add Packing Type'}
            </h1>
            <button
              onClick={onCancel}
              className="text-gray-400 hover:text-gray-600 transition-colors"
              title="Close"
            >
              <XMarkIcon className="w-6 h-6" />
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <form onSubmit={handleSubmit} className="">
            {error && (
              <div className="mx-6 mt-6 mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
                {typeof error === 'string' ? error : JSON.stringify(error)}
              </div>
            )}

            <div className="px-6 py-6">
              {/* Active Checkbox */}
              <div className="mb-6">
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    name="isActive"
                    checked={formData.isActive}
                    onChange={handleChange}
                    className="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50"
                  />
                  <span className="ml-2 text-sm font-medium text-gray-700">Active</span>
                </label>
              </div>

              {/* Basic Information Section */}
              <div className="mb-8">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Name *
                    </label>
                    <input
                      type="text"
                      name="name"
                      required
                      value={formData.name}
                      onChange={handleChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="Packing name"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Pack *
                    </label>
                    <input
                      type="number"
                      name="pack"
                      value={formData.pack}
                      onChange={handleChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="Pack quantity"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Leaf *
                    </label>
                    <input
                      type="number"
                      name="leaf"
                      value={formData.leaf}
                      onChange={handleChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="Leaf quantity"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Items Per Leaf *
                    </label>
                    <input
                      type="number"
                      name="numberOfItems"
                      value={formData.numberOfItems}
                      onChange={handleChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="Items per leaf"
                    />
                  </div>
                  <div className="md:col-span-2">
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Description
                    </label>
                    <textarea
                      name="description"
                      rows="4"
                      value={formData.description}
                      onChange={handleChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="Packing description"
                    />
                  </div>
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex justify-end space-x-3 px-6 py-4 bg-gray-50 border-t border-gray-200">
              <button
                type="button"
                onClick={onCancel}
                className="px-6 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                disabled={loading}
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="px-6 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
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

export default PackingForm;