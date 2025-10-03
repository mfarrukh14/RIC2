import React, { useState, useEffect } from 'react';
import { FiX } from 'react-icons/fi';

const ItemForm = ({ 
  item, 
  onSubmit, 
  onCancel,
  itemTypes,
  brands,
  categories,
  subCategories,
  packings,
  itemUnits,
  prices,
  taxRates,
  taxDescriptions,
  taxTypes
}) => {
  const [showAccountsTax, setShowAccountsTax] = useState(false);
  
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    model: '',
    barCode: '',
    specification: '',
    itemTypeId: '',
    brandId: '',
    packingId: '',
    unitId: '',
    priceId: '',
    categoryId: '',
    subCategoryId: '',
    frequency: '',
    isProduct: false,
    batchExpiryRequired: false,
    descriptionForSale: '',
    saleUnitId: '',
    conversion: '',
    caseContains: '',
    hsCode: '',
    retailPrice: '',
    costMethod: '',
    salesAccountId: '',
    inventoryAccountId: '',
    expenseAccountId: '',
    taxRateId: '',
    taxDescriptionId: '',
    taxTypeId: '',
    colour: '',
    minimumPanicLevel: '',
    isHidePanicFromBill: false,
    quantityPerPacket: '',
    isConsumptionItem: false,
    isFridgeItem: false,
    code: '',
    marketPrice: '',
    minimumOrderPrice: '',
    minimumOrderQuantity: '',
    packageType: '',
    packageSize: '',
    isActive: true,
  });

  useEffect(() => {
    if (item) {
      setFormData({
        name: item.name || '',
        description: item.description || '',
        model: item.model || '',
        barCode: item.barCode || '',
        specification: item.specification || '',
        itemTypeId: item.itemTypeId || '',
        brandId: item.brandId || '',
        packingId: item.packingId || '',
        unitId: item.unitId || '',
        priceId: item.priceId || '',
        categoryId: item.categoryId || '',
        subCategoryId: item.subCategoryId || '',
        frequency: item.frequency || '',
        isProduct: item.isProduct || false,
        batchExpiryRequired: item.batchExpiryRequired || false,
        descriptionForSale: item.descriptionForSale || '',
        saleUnitId: item.saleUnitId || '',
        conversion: item.conversion || '',
        caseContains: item.caseContains || '',
        hsCode: item.hsCode || '',
        retailPrice: item.itemRetailPrice || '',
        costMethod: item.costMethod || '',
        salesAccountId: item.salesAccountId || '',
        inventoryAccountId: item.inventoryAccountId || '',
        expenseAccountId: item.expenseAccountId || '',
        taxRateId: item.taxRateId || '',
        taxDescriptionId: item.taxDescriptionId || '',
        taxTypeId: item.taxTypeId || '',
        colour: item.colour || '',
        minimumPanicLevel: item.minimumPanicLevel || '',
        isHidePanicFromBill: item.isHidePanicFromBill || false,
        quantityPerPacket: item.quantityPerPacket || '',
        isConsumptionItem: item.isConsumptionItem || false,
        isFridgeItem: item.isFridgeItem || false,
        code: item.code || '',
        marketPrice: item.itemMarketPrice || '',
        minimumOrderPrice: item.minimumOrderPrice || '',
        minimumOrderQuantity: item.minimumOrderQuantity || '',
        packageType: item.packageType || '',
        packageSize: item.packageSize || '',
        isActive: item.isActive !== undefined ? item.isActive : true,
      });
    }
  }, [item]);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value,
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    
    // Convert empty strings to null for numeric and foreign key fields
    const cleanedData = {
      ...formData,
      itemTypeId: formData.itemTypeId || null,
      brandId: formData.brandId || null,
      packingId: formData.packingId || null,
      unitId: formData.unitId || null,
      priceId: formData.priceId || null,
      categoryId: formData.categoryId || null,
      subCategoryId: formData.subCategoryId || null,
      saleUnitId: formData.saleUnitId || null,
      salesAccountId: formData.salesAccountId || null,
      inventoryAccountId: formData.inventoryAccountId || null,
      expenseAccountId: formData.expenseAccountId || null,
      taxRateId: formData.taxRateId || null,
      taxDescriptionId: formData.taxDescriptionId || null,
      taxTypeId: formData.taxTypeId || null,
      frequency: formData.frequency || null,
      conversion: formData.conversion || null,
      retailPrice: formData.retailPrice || null,
      marketPrice: formData.marketPrice || null,
      minimumOrderPrice: formData.minimumOrderPrice || null,
      minimumOrderQuantity: formData.minimumOrderQuantity || null,
      minimumPanicLevel: formData.minimumPanicLevel || null,
      quantityPerPacket: formData.quantityPerPacket || null,
      costMethod: formData.costMethod || null,
    };
    
    onSubmit(cleanedData);
  };

  return (
    <div className="bg-white rounded-lg shadow-lg p-6">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-gray-800">
          {item ? 'Edit Item' : 'Add New Item'}
        </h2>
        <button
          onClick={onCancel}
          className="text-gray-500 hover:text-gray-700"
        >
          <FiX className="h-6 w-6" />
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Basic Information */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Item Type
            </label>
            <select
              name="itemTypeId"
              value={formData.itemTypeId}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Item Type</option>
              {itemTypes.map((type) => (
                <option key={type.id} value={type.id}>
                  {type.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Brand
            </label>
            <select
              name="brandId"
              value={formData.brandId}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Brand</option>
              {brands.map((brand) => (
                <option key={brand.id} value={brand.id}>
                  {brand.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Category
            </label>
            <select
              name="categoryId"
              value={formData.categoryId}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Category</option>
              {categories.map((category) => (
                <option key={category.id} value={category.id}>
                  {category.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Sub Category
            </label>
            <select
              name="subCategoryId"
              value={formData.subCategoryId}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Sub Category</option>
              {subCategories.map((subCat) => (
                <option key={subCat.id} value={subCat.id}>
                  {subCat.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Bar Code
            </label>
            <input
              type="text"
              name="barCode"
              value={formData.barCode}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Product <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              name="name"
              value={formData.name}
              onChange={handleChange}
              required
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Model
            </label>
            <input
              type="text"
              name="model"
              value={formData.model}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Packing Type
            </label>
            <select
              name="packingId"
              value={formData.packingId}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Packing</option>
              {packings.map((packing) => (
                <option key={packing.id} value={packing.id}>
                  {packing.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Specification
            </label>
            <input
              type="text"
              name="specification"
              value={formData.specification}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        {/* Description */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Description
          </label>
          <textarea
            name="description"
            value={formData.description}
            onChange={handleChange}
            rows="3"
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        {/* Checkboxes Row 1 */}
        <div className="flex flex-wrap gap-6">
          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              name="isActive"
              checked={formData.isActive}
              onChange={handleChange}
              className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <span className="text-sm font-medium text-gray-700">Active</span>
          </label>

          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              name="batchExpiryRequired"
              checked={formData.batchExpiryRequired}
              onChange={handleChange}
              className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <span className="text-sm font-medium text-gray-700">Batch Expiry Required</span>
          </label>

          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              name="isConsumptionItem"
              checked={formData.isConsumptionItem}
              onChange={handleChange}
              className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <span className="text-sm font-medium text-gray-700">Expensive Item</span>
          </label>

          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              name="isHidePanicFromBill"
              checked={formData.isHidePanicFromBill}
              onChange={handleChange}
              className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <span className="text-sm font-medium text-gray-700">Is Hide Name From Bill</span>
          </label>

          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              name="isFridgeItem"
              checked={formData.isFridgeItem}
              onChange={handleChange}
              className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <span className="text-sm font-medium text-gray-700">Fridge Item</span>
          </label>
        </div>

        {/* Sale & Purchase Information */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Purchase Unit
            </label>
            <select
              name="unitId"
              value={formData.unitId}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Unit</option>
              {itemUnits.map((unit) => (
                <option key={unit.id} value={unit.id}>
                  {unit.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Sale Unit
            </label>
            <select
              name="saleUnitId"
              value={formData.saleUnitId}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Unit</option>
              {itemUnits.map((unit) => (
                <option key={unit.id} value={unit.id}>
                  {unit.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Conversion
            </label>
            <input
              type="number"
              step="0.01"
              name="conversion"
              value={formData.conversion}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Case Contains
            </label>
            <input
              type="text"
              name="caseContains"
              value={formData.caseContains}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              HS Code
            </label>
            <input
              type="text"
              name="hsCode"
              value={formData.hsCode}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Retail Price
            </label>
            <input
              type="number"
              step="0.01"
              name="retailPrice"
              value={formData.retailPrice}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Market Price
            </label>
            <input
              type="number"
              step="0.01"
              name="marketPrice"
              value={formData.marketPrice}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Minimum Order Price
            </label>
            <input
              type="number"
              step="0.01"
              name="minimumOrderPrice"
              value={formData.minimumOrderPrice}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Minimum Order Qty
            </label>
            <input
              type="number"
              step="0.01"
              name="minimumOrderQuantity"
              value={formData.minimumOrderQuantity}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Package Type
            </label>
            <input
              type="text"
              name="packageType"
              value={formData.packageType}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Package Size
            </label>
            <input
              type="text"
              name="packageSize"
              value={formData.packageSize}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Cost Method
            </label>
            <select
              name="costMethod"
              value={formData.costMethod}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Cost Method</option>
              <option value="1">FIFO</option>
              <option value="2">LIFO</option>
              <option value="3">Average</option>
            </select>
          </div>
        </div>

        {/* Accounts & Tax Details - Collapsible Section */}
        <div className="border border-gray-300 rounded-md">
          <button
            type="button"
            onClick={() => setShowAccountsTax(!showAccountsTax)}
            className="w-full px-4 py-3 flex justify-between items-center bg-gray-50 hover:bg-gray-100 transition-colors"
          >
            <span className="font-medium text-gray-700">Accounts & Tax Details</span>
            <svg
              className={`w-5 h-5 transform transition-transform ${
                showAccountsTax ? 'rotate-180' : ''
              }`}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
            </svg>
          </button>

          {showAccountsTax && (
            <div className="p-4 space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    G/L Sales Account
                  </label>
                  <input
                    type="number"
                    name="salesAccountId"
                    value={formData.salesAccountId}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="Account ID"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    G/L Inventory Account
                  </label>
                  <input
                    type="number"
                    name="inventoryAccountId"
                    value={formData.inventoryAccountId}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="Account ID"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    G/L Cost of Sales/Expense Account
                  </label>
                  <input
                    type="number"
                    name="expenseAccountId"
                    value={formData.expenseAccountId}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="Account ID"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Item Sales Tax Type
                  </label>
                  <select
                    name="taxTypeId"
                    value={formData.taxTypeId}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Select Tax Type</option>
                    {taxTypes.map((type) => (
                      <option key={type.id} value={type.id}>
                        {type.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Rate
                  </label>
                  <select
                    name="taxRateId"
                    value={formData.taxRateId}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Select Tax Rate</option>
                    {taxRates.map((rate) => (
                      <option key={rate.id} value={rate.id}>
                        {rate.name} ({rate.rate}%)
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Tax Description
                  </label>
                  <select
                    name="taxDescriptionId"
                    value={formData.taxDescriptionId}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Select Tax Description</option>
                    {taxDescriptions.map((desc) => (
                      <option key={desc.id} value={desc.id}>
                        {desc.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Action Buttons */}
        <div className="flex justify-end space-x-3 pt-4">
          <button
            type="button"
            onClick={onCancel}
            className="px-6 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            Cancel
          </button>
          <button
            type="submit"
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            {item ? 'Update' : 'Save'}
          </button>
        </div>
      </form>
    </div>
  );
};

export default ItemForm;
