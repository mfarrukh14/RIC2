import React,{ useState, useEffect } from 'react';

const RackForm = ({ rack, stores, onSubmit, onCancel }) => {
  const [formData, setFormData] = useState({
    name: '',
    storeId: '',
    description: '',
    location: '',
    numberOfRows: '',
    numberOfCols: '',
    numberOfDraws: '',
    branchId: 1,
    isActive: true
  });

  const [errors, setErrors] = useState({});

  useEffect(() => {
    if (rack) {
      setFormData({
        name: rack.name || '',
        storeId: rack.storeId || '',
        description: rack.description || '',
        location: rack.location || '',
        numberOfRows: rack.numberOfRows || '',
        numberOfCols: rack.numberOfCols || '',
        numberOfDraws: rack.numberOfDraws || '',
        branchId: rack.branchId || 1,
        isActive: rack.isActive !== undefined ? rack.isActive : true
      });
    }
  }, [rack]);

  const validate = () => {
    const newErrors = {};

    if (!formData.name.trim()) {
      newErrors.name = 'Name is required';
    }

    if (!formData.storeId) {
      newErrors.storeId = 'Store is required';
    }

    if (!formData.numberOfRows || formData.numberOfRows < 0) {
      newErrors.numberOfRows = 'Number of Rows is required and must be positive';
    }

    if (!formData.numberOfCols || formData.numberOfCols < 0) {
      newErrors.numberOfCols = 'Number of Columns is required and must be positive';
    }

    if (!formData.numberOfDraws || formData.numberOfDraws < 0) {
      newErrors.numberOfDraws = 'Number of Drawers is required and must be positive';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    
    if (validate()) {
      onSubmit({
        ...formData,
        storeId: Number(formData.storeId),
        branchId: Number(formData.branchId || 1),
        numberOfRows: parseInt(formData.numberOfRows),
        numberOfCols: parseInt(formData.numberOfCols),
        numberOfDraws: parseInt(formData.numberOfDraws)
      });
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

  return (
    <form onSubmit={handleSubmit} className="space-y-6 bg-white p-6 rounded-lg shadow">
      <div className="flex items-center mb-4">
        <input
          type="checkbox"
          id="isActive"
          name="isActive"
          checked={formData.isActive}
          onChange={handleChange}
          className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
        />
        <label htmlFor="isActive" className="ml-2 text-sm text-gray-700">
          Active
        </label>
      </div>

      <div className="grid grid-cols-2 gap-6">
        {/* Name */}
        <div>
          <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-1">
            Name<span className="text-red-500">*</span>
          </label>
          <input
            type="text"
            id="name"
            name="name"
            value={formData.name}
            onChange={handleChange}
            placeholder="Rack Name"
            className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
              errors.name ? 'border-red-500' : 'border-gray-300'
            }`}
          />
          {errors.name && <p className="mt-1 text-sm text-red-500">{errors.name}</p>}
        </div>

        {/* Store */}
        <div>
          <label htmlFor="storeId" className="block text-sm font-medium text-gray-700 mb-1">
            Store<span className="text-red-500">*</span>
          </label>
          <select
            id="storeId"
            name="storeId"
            value={formData.storeId}
            onChange={handleChange}
            className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
              errors.storeId ? 'border-red-500' : 'border-gray-300'
            }`}
          >
            <option value="">Select Store</option>
            {stores.map((store) => (
              <option key={store.id} value={store.id}>
                {store.name}
              </option>
            ))}
          </select>
          {errors.storeId && <p className="mt-1 text-sm text-red-500">{errors.storeId}</p>}
        </div>

        {/* Location */}
        <div>
          <label htmlFor="location" className="block text-sm font-medium text-gray-700 mb-1">
            Location<span className="text-red-500">*</span>
          </label>
          <input
            type="text"
            id="location"
            name="location"
            value={formData.location}
            onChange={handleChange}
            placeholder="Rack Location"
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        {/* Number of Rows */}
        <div>
          <label htmlFor="numberOfRows" className="block text-sm font-medium text-gray-700 mb-1">
            No Of Rows<span className="text-red-500">*</span>
          </label>
          <input
            type="number"
            id="numberOfRows"
            name="numberOfRows"
            value={formData.numberOfRows}
            onChange={handleChange}
            placeholder="No Of Rows"
            className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
              errors.numberOfRows ? 'border-red-500' : 'border-gray-300'
            }`}
          />
          {errors.numberOfRows && <p className="mt-1 text-sm text-red-500">{errors.numberOfRows}</p>}
        </div>

        {/* Number of Columns */}
        <div>
          <label htmlFor="numberOfCols" className="block text-sm font-medium text-gray-700 mb-1">
            No Of Columns<span className="text-red-500">*</span>
          </label>
          <input
            type="number"
            id="numberOfCols"
            name="numberOfCols"
            value={formData.numberOfCols}
            onChange={handleChange}
            placeholder="Columns"
            className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
              errors.numberOfCols ? 'border-red-500' : 'border-gray-300'
            }`}
          />
          {errors.numberOfCols && <p className="mt-1 text-sm text-red-500">{errors.numberOfCols}</p>}
        </div>

        {/* Number of Drawers (with Custom radio option) */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            <input
              type="radio"
              name="drawerMode"
              checked={true}
              readOnly
              className="mr-2"
            />
            Custom
          </label>
          <input
            type="number"
            id="numberOfDraws"
            name="numberOfDraws"
            value={formData.numberOfDraws}
            onChange={handleChange}
            placeholder="Drawers"
            className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
              errors.numberOfDraws ? 'border-red-500' : 'border-gray-300'
            }`}
          />
          {errors.numberOfDraws && <p className="mt-1 text-sm text-red-500">{errors.numberOfDraws}</p>}
        </div>
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
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      {/* Buttons */}
      <div className="flex justify-end space-x-3">
        <button
          type="button"
          onClick={onCancel}
          className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
        >
          Cancel
        </button>
        <button
          type="submit"
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
        >
          Submit
        </button>
      </div>
    </form>
  );
};

export default RackForm;
