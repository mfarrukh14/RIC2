import React, { useState, useEffect } from 'react';
import inventoryApi from '../services/inventoryApi';
import itemApi from '../services/itemApi';
import BranchField from './BranchField';
import { useSession } from '../context/SessionContext';
import { productOptionValue, parseProductOptionValue, findProductRow } from '../utils/productKey';

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
  const [products, setProducts] = useState([]);

  const [formData, setFormData] = useState({
    vendorId: '',
    storeId: '',
    branchId: '',
    stockTypeId: '',
    vendorInvoiceNumber: '',
    vendorInvoiceTimestamp: '',
    itemId: '',
    medicineId: '',
    subServiceId: '',
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

  // New (non-edit) inventories can hold several item lines under one header, matching
  // the old system's flow of receiving multiple items into a store in a single Add
  // Inventory entry - each line captured here keeps `savedDetailId` so a retry after a
  // partial failure doesn't recreate lines that already saved successfully.
  const [items, setItems] = useState([]);
  const [itemsError, setItemsError] = useState('');
  const [submitting, setSubmitting] = useState(false);

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
          medicineId: detail?.medicineId || '',
          subServiceId: detail?.subServiceId || '',
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
      const [data, unifiedItems] = await Promise.all([
        inventoryApi.getLookupData(),
        itemApi.getAllWithMedicines()
      ]);
      setLookupData(data);
      setProducts((unifiedItems || []).filter((row) => row.isActive));
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

  const ITEM_FIELD_DEFAULTS = {
    itemId: '',
    medicineId: '',
    subServiceId: '',
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
  };

  const buildDetailPayload = (data, margin, perItem) => ({
    itemId: data.itemId ? parseInt(data.itemId) : null,
    medicineId: data.medicineId ? parseInt(data.medicineId) : null,
    subServiceId: data.subServiceId ? parseInt(data.subServiceId) : null,
    manufacturerId: data.manufacturerId ? parseInt(data.manufacturerId) : null,
    mfgDate: data.mfgDate || null,
    expiryDate: data.expiryDate || null,
    noOfBoxes: data.noOfBoxes ? parseInt(data.noOfBoxes) : null,
    noOfPackets: data.noOfPackets ? parseInt(data.noOfPackets) : null,
    itemsPerPacket: data.itemsPerPacket ? parseInt(data.itemsPerPacket) : null,
    totalItems: data.totalItems ? parseInt(data.totalItems) : null,
    packQuantity: data.packQuantity ? parseInt(data.packQuantity) : null,
    unitBuyingPrice: data.unitBuyingPrice ? parseFloat(data.unitBuyingPrice) : null,
    totalBuyingPrice: data.totalBuyingPrice ? parseFloat(data.totalBuyingPrice) : null,
    advanceTaxPercentage: data.advanceTaxPercentage ? parseFloat(data.advanceTaxPercentage) : null,
    advanceTaxAmount: data.advanceTaxAmount ? parseFloat(data.advanceTaxAmount) : null,
    discount: data.discount,
    discountAmount: data.discountAmount ? parseFloat(data.discountAmount) : null,
    retailCharges: data.retailCharges,
    retailChargesAmount: data.retailChargesAmount ? parseFloat(data.retailChargesAmount) : null,
    gstCharges: data.gstCharges,
    gstChargesAmount: data.gstChargesAmount ? parseFloat(data.gstChargesAmount) : null,
    unitSellingPrice: data.unitSellingPrice ? parseFloat(data.unitSellingPrice) : null,
    totalSellingPrice: data.totalSellingPrice ? parseFloat(data.totalSellingPrice) : null,
    profitMarginPerItem: margin,
    profitPerItem: perItem
  });

  // Snapshots the current item draft into the line list (old system's flow: fill an
  // item's details, add it, then move on to the next item under the same invoice/header)
  // and clears just the item-specific fields so the next line starts fresh.
  const addItemToList = () => {
    setItemsError('');

    if ((!formData.itemId && !formData.medicineId && !formData.subServiceId) || !formData.manufacturerId || !formData.mfgDate || !formData.expiryDate ||
        !formData.noOfBoxes || !formData.noOfPackets || !formData.itemsPerPacket || !formData.unitSellingPrice) {
      setItemsError('Please complete the required item fields before adding it to the list.');
      return;
    }

    const selectedItem = findProductRow(products, formData);

    setItems((prev) => [
      ...prev,
      {
        key: `${productOptionValue(formData)}-${Date.now()}`,
        itemName: selectedItem?.name || `Item #${formData.itemId || formData.medicineId || formData.subServiceId}`,
        savedDetailId: null,
        payload: buildDetailPayload(formData, profitMargin, profitPerItem)
      }
    ]);

    setFormData((prev) => ({ ...prev, ...ITEM_FIELD_DEFAULTS }));
    setProfitMargin(0);
    setProfitPerItem(0);
  };

  const removeItemFromList = (key) => {
    setItems((prev) => prev.filter((item) => item.key !== key));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!inventory && items.length === 0) {
      setItemsError('Please add at least one item to the list before submitting.');
      return;
    }

    setSubmitting(true);
    setItemsError('');

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

      if (inventory) {
        // Editing an existing inventory still edits its single detail line in place.
        const detailData = buildDetailPayload(formData, profitMargin, profitPerItem);
        detailData.inventoryId = inventoryId;

        if (savedDetailId) {
          await inventoryApi.updateDetail(savedDetailId, detailData);
        } else {
          const detailResult = await inventoryApi.createDetail(detailData);
          setSavedDetailId(detailResult.id);
        }
      } else {
        // Create every line added to the list under this one header. Lines already
        // saved from a prior partial-failure attempt (savedDetailId set) are skipped so
        // a retry doesn't create duplicates.
        for (let index = 0; index < items.length; index += 1) {
          const item = items[index];
          if (item.savedDetailId) {
            continue;
          }

          try {
            const detailResult = await inventoryApi.createDetail({ ...item.payload, inventoryId });
            setItems((prev) => prev.map((current) => (
              current.key === item.key ? { ...current, savedDetailId: detailResult.id } : current
            )));
          } catch (detailErr) {
            console.error('Error saving inventory item:', detailErr);
            const message = detailErr.response?.data?.message || detailErr.message || 'Failed to save this item.';
            setItemsError(`Failed to save "${item.itemName}": ${message}. Items already saved above were kept - fix this line and submit again.`);
            setSubmitting(false);
            return;
          }
        }
      }

      onSave();
    } catch (err) {
      console.error('Error saving inventory:', err);
      const errorMessage = err.response?.data?.message || err.message || 'Failed to save inventory. Please try again.';
      setItemsError(errorMessage);
      setSubmitting(false);
    }
  };

  return (
    <div className="bg-white rounded-lg shadow-lg p-6">
      <h2 className="text-2xl font-bold text-gray-800 mb-6">
        {inventory ? 'Edit Inventory' : 'Add Inventory'}
      </h2>

      <form onSubmit={handleSubmit}>
        {itemsError && (
          <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-md">
            {itemsError}
          </div>
        )}

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
              value={productOptionValue(formData)}
              onChange={(e) => setFormData(prev => ({ ...prev, ...parseProductOptionValue(e.target.value) }))}
              required={!!inventory || items.length === 0}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Search Item</option>
              {products.map((item) => (
                <option key={productOptionValue(item)} value={productOptionValue(item)}>
                  {item.sourceType === 'Item' ? item.name : `${item.name} (${item.sourceType})`}
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
              required={!!inventory || items.length === 0}
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
              required={!!inventory || items.length === 0}
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
              required={!!inventory || items.length === 0}
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
              required={!!inventory || items.length === 0}
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
              required={!!inventory || items.length === 0}
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
              required={!!inventory || items.length === 0}
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
              required={!!inventory || items.length === 0}
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

        {/* Items list - lets several items be received into this store under one
            header/invoice, instead of only ever accepting a single item. */}
        {!inventory && (
          <div className="mb-6">
            <div className="flex justify-end mb-3">
              <button
                type="button"
                onClick={addItemToList}
                className="px-6 py-2 bg-emerald-600 text-white rounded-md hover:bg-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-emerald-500"
              >
                + Add Item to List
              </button>
            </div>

            <div className="border border-gray-200 rounded-md overflow-hidden">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Item</th>
                    <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Total Items</th>
                    <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Unit Buying Price</th>
                    <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Unit Selling Price</th>
                    <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                    <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Action</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {items.length === 0 ? (
                    <tr>
                      <td colSpan="6" className="px-4 py-4 text-center text-sm text-gray-500">
                        No items added yet
                      </td>
                    </tr>
                  ) : (
                    items.map((item) => (
                      <tr key={item.key}>
                        <td className="px-4 py-2 text-sm text-gray-900">{item.itemName}</td>
                        <td className="px-4 py-2 text-sm text-gray-500">{item.payload.totalItems ?? 0}</td>
                        <td className="px-4 py-2 text-sm text-gray-500">{item.payload.unitBuyingPrice ?? 0}</td>
                        <td className="px-4 py-2 text-sm text-gray-500">{item.payload.unitSellingPrice ?? 0}</td>
                        <td className="px-4 py-2 text-sm">
                          {item.savedDetailId ? (
                            <span className="text-green-600">Saved</span>
                          ) : (
                            <span className="text-gray-500">Pending</span>
                          )}
                        </td>
                        <td className="px-4 py-2 text-sm">
                          <button
                            type="button"
                            onClick={() => removeItemFromList(item.key)}
                            disabled={!!item.savedDetailId}
                            className="text-red-600 hover:text-red-900 disabled:opacity-40 disabled:cursor-not-allowed"
                          >
                            Remove
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

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
            disabled={submitting}
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {submitting ? 'Saving...' : inventory ? 'Update' : 'Submit'}
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
