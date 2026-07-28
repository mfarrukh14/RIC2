import React, { useState, useEffect } from 'react';
import inventoryApi from '../services/inventoryApi';
import BranchField from './BranchField';
import { useSession } from '../context/SessionContext';

const InventoryFormPage = ({ inventory, onSave, onCancel }) => {
  const { session } = useSession();
  const [lookupData, setLookupData] = useState({
    vendors: [],
    stores: [],
    stockTypes: [],
    items: [],
    manufacturers: [],
    branches: []
  });

  const [formData, setFormData] = useState({
    vendorId: '',
    storeId: '',
    branchId: '',
    stockTypeId: '',
    vendorInvoiceNumber: '',
    vendorInvoiceTimestamp: '',
    itemId: '',
    manufacturerId: '',
    mfgDate: '',
    expiryDate: '',
    noOfBoxes: '',
    noOfPackets: '',
    itemsPerPacket: '',
    totalItems: '',
    packQuantity: '',
    unitBuyingPrice: '',
    totalBuyingPrice: '',
    advanceTaxPercentage: '',
    advanceTaxAmount: '',
    discount: false,
    discountAmount: '',
    retailCharges: false,
    retailChargesAmount: '',
    gstCharges: false,
    gstChargesAmount: '',
    unitSellingPrice: '',
    totalSellingPrice: '',
    registrationNumber: '',
    batch: '',
    lotNumber: ''
  });

  const [profitMargin, setProfitMargin] = useState(0);
  const [profitPerItem, setProfitPerItem] = useState(0);

  // Tracks the header/detail row this form is actually writing to, so a retry after a
  // failed submit (e.g. the detail insert fails validation) updates the same records
  // instead of creating a new orphaned header every attempt.
  const [savedInventoryId, setSavedInventoryId] = useState(null);
  const [savedDetailId, setSavedDetailId] = useState(null);

  useEffect(() => {
    fetchLookupData();
  }, []);

  // New inventory entries belong to the logged-in user's own branch.
  useEffect(() => {
    if (!inventory && session?.branchId) {
      setFormData((prev) => ({ ...prev, branchId: session.branchId }));
    }
  }, [inventory, session?.branchId]);

  // Default new entries to the "Regular" stock type once the real list loads,
  // instead of faking it with a duplicate placeholder option.
  useEffect(() => {
    if (!inventory && !formData.stockTypeId && lookupData.stockTypes.length > 0) {
      const regular = lookupData.stockTypes.find((t) => t.name?.trim().toLowerCase() === 'regular');
      if (regular) {
        setFormData((prev) => ({ ...prev, stockTypeId: prev.stockTypeId || regular.id }));
      }
    }
  }, [inventory, lookupData.stockTypes]);

  useEffect(() => {
    if (!inventory) return;

    // The row passed in from the list only has header fields - fetch the full
    // record (with its detail line) so editing doesn't wipe out the item/quantity/
    // pricing data the user already entered when this inventory was created.
    let cancelled = false;
    (async () => {
      try {
        const full = await inventoryApi.getById(inventory.id);
        if (cancelled) return;

        const detail = full.details?.[0] || null;
        setSavedInventoryId(full.id);
        setSavedDetailId(detail?.id || null);

        setFormData({
          vendorId: full.vendorId || '',
          storeId: full.storeId || '',
          branchId: full.branchId || '',
          stockTypeId: full.stockTypeId || '',
          vendorInvoiceNumber: full.vendorInvoiceNumber || '',
          vendorInvoiceTimestamp: full.vendorInvoiceTimestamp ?
            new Date(full.vendorInvoiceTimestamp).toISOString().split('T')[0] : '',
          itemId: detail?.itemId || '',
          manufacturerId: detail?.manufacturerId || '',
          mfgDate: detail?.mfgDate ? new Date(detail.mfgDate).toISOString().split('T')[0] : '',
          expiryDate: detail?.expiryDate ? new Date(detail.expiryDate).toISOString().split('T')[0] : '',
          noOfBoxes: detail?.noOfBoxes ?? '',
          noOfPackets: detail?.noOfPackets ?? '',
          itemsPerPacket: detail?.itemsPerPacket ?? '',
          totalItems: detail?.totalItems ?? '',
          packQuantity: detail?.packQuantity ?? '',
          unitBuyingPrice: detail?.unitBuyingPrice ?? '',
          totalBuyingPrice: detail?.totalBuyingPrice ?? '',
          advanceTaxPercentage: detail?.advanceTaxPercentage ?? '',
          advanceTaxAmount: detail?.advanceTaxAmount ?? '',
          discount: detail?.discount || false,
          discountAmount: detail?.discountAmount ?? '',
          retailCharges: detail?.retailCharges || false,
          retailChargesAmount: detail?.retailChargesAmount ?? '',
          gstCharges: detail?.gstCharges || false,
          gstChargesAmount: detail?.gstChargesAmount ?? '',
          unitSellingPrice: detail?.unitSellingPrice ?? '',
          totalSellingPrice: detail?.totalSellingPrice ?? '',
          registrationNumber: full.registrationNumber || '',
          batch: full.batch || '',
          lotNumber: full.lotNumber || ''
        });
      } catch (err) {
        console.error('Error loading inventory details:', err);
      }
    })();

    return () => { cancelled = true; };
  }, [inventory]);

  useEffect(() => {
    calculateTotals();
  }, [
    formData.noOfBoxes,
    formData.noOfPackets,
    formData.itemsPerPacket,
    formData.unitBuyingPrice,
    formData.advanceTaxPercentage,
    formData.discountAmount,
    formData.retailChargesAmount,
    formData.gstChargesAmount,
    formData.unitSellingPrice
  ]);

  const fetchLookupData = async () => {
    try {
      const data = await inventoryApi.getLookupData();
      setLookupData(data);
    } catch (err) {
      console.error('Error fetching lookup data:', err);
    }
  };

  const calculateTotals = () => {
    const boxes = parseFloat(formData.noOfBoxes) || 0;
    const packets = parseFloat(formData.noOfPackets) || 0;
    const itemsPerPacket = parseFloat(formData.itemsPerPacket) || 0;
    const unitBuyingPrice = parseFloat(formData.unitBuyingPrice) || 0;
    const unitSellingPrice = parseFloat(formData.unitSellingPrice) || 0;

    // Calculate total items
    const totalItems = boxes * packets * itemsPerPacket;
    
    // Calculate total buying price
    let totalBuying = totalItems * unitBuyingPrice;

    // Apply advance tax
    const advanceTaxPct = parseFloat(formData.advanceTaxPercentage) || 0;
    const advanceTaxAmt = (totalBuying * advanceTaxPct) / 100;
    totalBuying += advanceTaxAmt;

    // Apply discount
    if (formData.discount) {
      const discountAmt = parseFloat(formData.discountAmount) || 0;
      totalBuying -= discountAmt;
    }

    // Apply retail charges
    if (formData.retailCharges) {
      const retailChargesAmt = parseFloat(formData.retailChargesAmount) || 0;
      totalBuying += retailChargesAmt;
    }

    // Apply GST charges
    if (formData.gstCharges) {
      const gstChargesAmt = parseFloat(formData.gstChargesAmount) || 0;
      totalBuying += gstChargesAmt;
    }

    // Calculate total selling price
    const totalSelling = totalItems * unitSellingPrice;

    // Calculate profit
    const profit = totalSelling - totalBuying;
    const profitPerItemCalc = totalItems > 0 ? profit / totalItems : 0;
    const profitMarginCalc = totalBuying > 0 ? (profit / totalBuying) * 100 : 0;

    setFormData(prev => ({
      ...prev,
      totalItems: totalItems.toString(),
      totalBuyingPrice: totalBuying.toFixed(2),
      advanceTaxAmount: advanceTaxAmt.toFixed(2),
      totalSellingPrice: totalSelling.toFixed(2)
    }));

    setProfitPerItem(profitPerItemCalc);
    setProfitMargin(profitMarginCalc);
  };

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    try {
      // First create or update the inventory header
      let inventoryId;
      
      const headerData = {
        vendorId: parseInt(formData.vendorId),
        storeId: parseInt(formData.storeId),
        branchId: parseInt(formData.branchId),
        stockTypeId: parseInt(formData.stockTypeId),
        vendorInvoiceNumber: formData.vendorInvoiceNumber,
        vendorInvoiceTimestamp: formData.vendorInvoiceTimestamp ? new Date(formData.vendorInvoiceTimestamp).toISOString() : null
      };

      // Reuse the header this form already wrote (editing an existing inventory, or a
      // prior submit attempt in this session that got far enough to create one) instead
      // of creating a new one every time - otherwise a retry after a failed detail insert
      // leaves behind an orphaned duplicate header with no items.
      const existingInventoryId = inventory?.id || savedInventoryId;

      if (existingInventoryId) {
        await inventoryApi.update(existingInventoryId, headerData);
        inventoryId = existingInventoryId;
      } else {
        const result = await inventoryApi.create(headerData);
        inventoryId = result.id;
        setSavedInventoryId(inventoryId);
      }

      // Then create the detail line item
      const detailData = {
        inventoryId: inventoryId,
        itemId: parseInt(formData.itemId),
        manufacturerId: formData.manufacturerId ? parseInt(formData.manufacturerId) : null,
        mfgDate: formData.mfgDate || null,
        expiryDate: formData.expiryDate || null,
        noOfBoxes: formData.noOfBoxes ? parseInt(formData.noOfBoxes) : null,
        noOfPackets: formData.noOfPackets ? parseInt(formData.noOfPackets) : null,
        itemsPerPacket: formData.itemsPerPacket ? parseInt(formData.itemsPerPacket) : null,
        totalItems: formData.totalItems ? parseInt(formData.totalItems) : null,
        packQuantity: formData.packQuantity ? parseInt(formData.packQuantity) : null,
        unitBuyingPrice: formData.unitBuyingPrice ? parseFloat(formData.unitBuyingPrice) : null,
        totalBuyingPrice: formData.totalBuyingPrice ? parseFloat(formData.totalBuyingPrice) : null,
        advanceTaxPercentage: formData.advanceTaxPercentage ? parseFloat(formData.advanceTaxPercentage) : null,
        advanceTaxAmount: formData.advanceTaxAmount ? parseFloat(formData.advanceTaxAmount) : null,
        discount: formData.discount,
        discountAmount: formData.discountAmount ? parseFloat(formData.discountAmount) : null,
        retailCharges: formData.retailCharges,
        retailChargesAmount: formData.retailChargesAmount ? parseFloat(formData.retailChargesAmount) : null,
        gstCharges: formData.gstCharges,
        gstChargesAmount: formData.gstChargesAmount ? parseFloat(formData.gstChargesAmount) : null,
        unitSellingPrice: formData.unitSellingPrice ? parseFloat(formData.unitSellingPrice) : null,
        totalSellingPrice: formData.totalSellingPrice ? parseFloat(formData.totalSellingPrice) : null,
        profitMarginPerItem: profitMargin,
        profitPerItem: profitPerItem
      };

      const existingDetailId = savedDetailId;
      if (existingDetailId) {
        await inventoryApi.updateDetail(existingDetailId, detailData);
      } else {
        const detailResult = await inventoryApi.createDetail(detailData);
        setSavedDetailId(detailResult.id);
      }

      onSave();
    } catch (err) {
      console.error('Error saving inventory:', err);
      const errorMessage = err.response?.data?.message || err.message || 'Failed to save inventory. Please try again.';
      alert(errorMessage);
    }
  };

  return (
    <div className="bg-white rounded-lg shadow-lg p-6">
      <h2 className="text-2xl font-bold text-gray-800 mb-6">
        {inventory ? 'Edit Inventory' : 'Add Inventory'}
      </h2>

      <form onSubmit={handleSubmit}>
        {/* Store - Top Right */}
        <div className="mb-6">
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
            <option value="">Select Store</option>
            {lookupData.stores.map((store) => (
              <option key={store.storeId} value={store.storeId}>
                {store.storeName}
              </option>
            ))}
          </select>
        </div>

        {/* Row 1: Vendor, Branch and Stock Type */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Vendor<span className="text-red-500">*</span>
            </label>
            <select
              name="vendorId"
              value={formData.vendorId}
              onChange={handleChange}
              required
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Vendor</option>
              {lookupData.vendors.map((vendor) => (
                <option key={vendor.id} value={vendor.id}>
                  {vendor.name}
                </option>
              ))}
            </select>
          </div>

          {/* Branch - locked to the logged-in user's own branch */}
          <BranchField />

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
              <option value="">Select Stock Type</option>
              {lookupData.stockTypes.map((type) => (
                <option key={type.id} value={type.id}>
                  {type.name}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Row 2: Vendor Invoice No and Date */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Vendor Invoice No
            </label>
            <input
              type="text"
              name="vendorInvoiceNumber"
              value={formData.vendorInvoiceNumber}
              onChange={handleChange}
              placeholder="Vendor Invoice Number"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Vendor Invoice Date
            </label>
            <input
              type="date"
              name="vendorInvoiceTimestamp"
              value={formData.vendorInvoiceTimestamp}
              onChange={handleChange}
              placeholder="DD/MM/YYYY"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        {/* Row 3: Item and Manufacturer */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
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
              <option value="">Search Item</option>
              {lookupData.items.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Manufacturer<span className="text-red-500">*</span>
            </label>
            <select
              name="manufacturerId"
              value={formData.manufacturerId}
              onChange={handleChange}
              required
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Manufacturer</option>
              {lookupData.manufacturers.map((manufacturer) => (
                <option key={manufacturer.id} value={manufacturer.id}>
                  {manufacturer.name}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Row 4: Mfg Date and Expiry Date */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Mfg Date<span className="text-red-500">*</span>
            </label>
            <input
              type="date"
              name="mfgDate"
              value={formData.mfgDate}
              onChange={handleChange}
              required
              placeholder="DD/MM/YYYY"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Expiry Date<span className="text-red-500">*</span>
            </label>
            <input
              type="date"
              name="expiryDate"
              value={formData.expiryDate}
              onChange={handleChange}
              required
              placeholder="DD/MM/YYYY"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        {/* Row 5: No of Boxes and No of Packets */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              No of Boxes<span className="text-red-500">*</span>
            </label>
            <input
              type="number"
              name="noOfBoxes"
              value={formData.noOfBoxes}
              onChange={handleChange}
              required
              placeholder="No of Boxes"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              No of Packets<span className="text-red-500">*</span>
            </label>
            <input
              type="number"
              name="noOfPackets"
              value={formData.noOfPackets}
              onChange={handleChange}
              required
              placeholder="No of Packets"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        {/* Row 6: Items Per Packet and Total Items */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Items Per Packet<span className="text-red-500">*</span>
            </label>
            <input
              type="number"
              name="itemsPerPacket"
              value={formData.itemsPerPacket}
              onChange={handleChange}
              required
              placeholder="Item Per Packet"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Total Items
            </label>
            <input
              type="text"
              name="totalItems"
              value={formData.totalItems}
              readOnly
              placeholder="Total Items"
              className="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-100"
            />
          </div>
        </div>

        {/* Row 7: Pack Quantity and Unit Buying Price */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Pack Quantity
            </label>
            <input
              type="number"
              name="packQuantity"
              value={formData.packQuantity}
              onChange={handleChange}
              placeholder="0"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Unit Buying Price
            </label>
            <input
              type="number"
              step="0.01"
              name="unitBuyingPrice"
              value={formData.unitBuyingPrice}
              onChange={handleChange}
              placeholder="0"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        {/* Row 8: Advance Tax % and Amount */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Advance Tax %
            </label>
            <input
              type="number"
              step="0.01"
              name="advanceTaxPercentage"
              value={formData.advanceTaxPercentage}
              onChange={handleChange}
              placeholder="Advance Tax Percentage"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Advance Tax Amount
            </label>
            <input
              type="text"
              name="advanceTaxAmount"
              value={formData.advanceTaxAmount}
              readOnly
              placeholder="0"
              className="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-100"
            />
          </div>
        </div>

        {/* Row 9: Discount Radio Buttons */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Discount
            </label>
            <div className="flex items-center gap-6">
              <label className="flex items-center">
                <input
                  type="radio"
                  name="discount"
                  checked={formData.discount === true}
                  onChange={() => setFormData(prev => ({ ...prev, discount: true }))}
                  className="mr-2"
                />
                <span className="text-sm">Yes</span>
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="discount"
                  checked={formData.discount === false}
                  onChange={() => setFormData(prev => ({ ...prev, discount: false }))}
                  className="mr-2"
                />
                <span className="text-sm">No</span>
              </label>
            </div>
          </div>

          <div>
            {/* Profit Display */}
            <div className="text-center">
              <p className="text-red-500 font-bold text-lg">
                Profit Margin Per Item: {profitMargin.toFixed(2)}%
              </p>
              <p className="text-red-500 font-bold text-lg">
                Profit Per Item: {profitPerItem.toFixed(2)}
              </p>
            </div>
          </div>
        </div>

        {/* Row 10: Retail Charges and GST Charges */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Retail Charges
            </label>
            <div className="flex items-center gap-6">
              <label className="flex items-center">
                <input
                  type="radio"
                  name="retailCharges"
                  checked={formData.retailCharges === true}
                  onChange={() => setFormData(prev => ({ ...prev, retailCharges: true }))}
                  className="mr-2"
                />
                <span className="text-sm">Yes</span>
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="retailCharges"
                  checked={formData.retailCharges === false}
                  onChange={() => setFormData(prev => ({ ...prev, retailCharges: false }))}
                  className="mr-2"
                />
                <span className="text-sm">No</span>
              </label>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              GST Charges
            </label>
            <div className="flex items-center gap-6">
              <label className="flex items-center">
                <input
                  type="radio"
                  name="gstCharges"
                  checked={formData.gstCharges === true}
                  onChange={() => setFormData(prev => ({ ...prev, gstCharges: true }))}
                  className="mr-2"
                />
                <span className="text-sm">Yes</span>
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="gstCharges"
                  checked={formData.gstCharges === false}
                  onChange={() => setFormData(prev => ({ ...prev, gstCharges: false }))}
                  className="mr-2"
                />
                <span className="text-sm">No</span>
              </label>
            </div>
          </div>
        </div>

        {/* Row 11: Unit Selling Price and Total Selling Price */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Unit Selling Price<span className="text-red-500">*</span>
            </label>
            <input
              type="number"
              step="0.01"
              name="unitSellingPrice"
              value={formData.unitSellingPrice}
              onChange={handleChange}
              required
              placeholder="Unit Selling Price"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Total Selling Price
            </label>
            <input
              type="text"
              name="totalSellingPrice"
              value={formData.totalSellingPrice}
              readOnly
              placeholder="0"
              className="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-100"
            />
          </div>
        </div>

        {/* Row 12: Total Buying Price (Full Width) */}
        <div className="mb-4">
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Total Buying Price<span className="text-red-500">*</span>
          </label>
          <input
            type="text"
            name="totalBuyingPrice"
            value={formData.totalBuyingPrice}
            readOnly
            placeholder="0"
            className="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-100"
          />
        </div>

        {/* Row 13: Registration Number and Batch */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Registration Number
            </label>
            <input
              type="text"
              name="registrationNumber"
              value={formData.registrationNumber}
              onChange={handleChange}
              placeholder="Registration Number"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Batch
            </label>
            <input
              type="text"
              name="batch"
              value={formData.batch}
              onChange={handleChange}
              placeholder="Batch"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        {/* Row 14: Lot Number */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Lot Number
          </label>
          <input
            type="text"
            name="lotNumber"
            value={formData.lotNumber}
            onChange={handleChange}
            placeholder="Lot Number"
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        {/* Action Buttons */}
        <div className="flex justify-end gap-3">
          <button
            type="button"
            className="px-6 py-2 bg-teal-600 text-white rounded-md hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-teal-500"
          >
            Preview
          </button>
          <button
            type="submit"
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            Add
          </button>
          <button
            type="button"
            onClick={onCancel}
            className="px-6 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
};

export default InventoryFormPage;
