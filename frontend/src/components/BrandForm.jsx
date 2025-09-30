import React, { useState, useEffect } from 'react';
import { XMarkIcon } from '@heroicons/react/24/outline';

const BrandForm = ({ brand, onSave, onCancel, isEditing }) => {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    branchId: '',
    isActive: true
  });
  const [branches, setBranches] = useState([]);
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState({});

  useEffect(() => {
    fetchBranches();
    if (brand) {
      setFormData({
        name: brand.name || '',
        description: brand.description || '',
        branchId: brand.branchId || '',
        isActive: brand.isActive !== undefined ? brand.isActive : true
      });
    }
  }, [brand]);

  const fetchBranches = async () => {
    try {
      // Since we don't have a branches API yet, we'll use mock data
      // In a real application, you would fetch from /api/branches
      setBranches([
        { id: 1, name: 'Main Branch' },
        { id: 2, name: 'Secondary Branch' }
      ]);
    } catch (err) {
      console.error('Error fetching branches:', err);
    }
  };

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
    
    // Clear error when user starts typing
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const validateForm = () => {
    const newErrors = {};
    
    if (!formData.name.trim()) {
      newErrors.name = 'Brand name is required';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    setLoading(true);
    
    try {
      const url = isEditing 
        ? `http://localhost:5000/api/brands/${brand.id}`
        : 'http://localhost:5000/api/brands';
      
      const method = isEditing ? 'PUT' : 'POST';
      
      const requestData = {
        ...(isEditing && { id: brand.id }),
        name: formData.name.trim(),
        description: formData.description.trim() || null,
        branchId: formData.branchId ? parseInt(formData.branchId) : null,
        isActive: formData.isActive,
        ...(isEditing 
          ? { modifiedById: 1 }
          : { createdById: 1 }
        )
      };

      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestData),
      });

      if (response.ok) {
        onSave();
      } else {
        const errorData = await response.text();
        alert(`Failed to ${isEditing ? 'update' : 'create'} brand: ${errorData}`);
      }
    } catch (err) {
      alert(`Error ${isEditing ? 'updating' : 'creating'} brand: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white">
      {/* Header */}
      <div className="px-6 py-4 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">
            {isEditing ? 'Edit Brand' : 'Add Brand'}
          </h2>
          <button
            onClick={onCancel}
            className="text-gray-400 hover:text-gray-600"
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>
      </div>

      {/* Form */}
      <div className="px-6 py-6">
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Active Status */}
          <div className="flex items-center">
            <input
              type="checkbox"
              id="isActive"
              name="isActive"
              checked={formData.isActive}
              onChange={handleChange}
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
            />
            <label htmlFor="isActive" className="ml-2 block text-sm text-gray-900">
              Active
            </label>
          </div>

          {/* Brand Name */}
          <div>
            <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-1">
              Brand Name *
            </label>
            <input
              type="text"
              id="name"
              name="name"
              value={formData.name}
              onChange={handleChange}
              placeholder="Brand"
              className={`block w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                errors.name ? 'border-red-300' : 'border-gray-300'
              }`}
            />
            {errors.name && (
              <p className="mt-1 text-sm text-red-600">{errors.name}</p>
            )}
          </div>

          {/* Description */}
          <div>
            <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-1">
              Description
            </label>
            <textarea
              id="description"
              name="description"
              value={formData.description}
              onChange={handleChange}
              rows={4}
              className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Enter brand description..."
            />
          </div>

          {/* Branch */}
          <div>
            <label htmlFor="branchId" className="block text-sm font-medium text-gray-700 mb-1">
              Branch
            </label>
            <select
              id="branchId"
              name="branchId"
              value={formData.branchId}
              onChange={handleChange}
              className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="">Select a branch (optional)</option>
              {branches.map((branch) => (
                <option key={branch.id} value={branch.id}>
                  {branch.name}
                </option>
              ))}
            </select>
          </div>

          {/* Form Actions */}
          <div className="flex items-center justify-end space-x-3 pt-6">
            <button
              type="button"
              onClick={onCancel}
              className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? (
                <div className="flex items-center">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                  {isEditing ? 'Updating...' : 'Creating...'}
                </div>
              ) : (
                isEditing ? 'Update' : 'Submit'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default BrandForm;