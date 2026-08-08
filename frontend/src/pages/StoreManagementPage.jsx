import React, { useState, useEffect } from 'react';
import { getAllStores, createStore, updateStore, deleteStore, getStoreLocationLookup } from '../services/storeApi';
import BranchField from '../components/BranchField';
import Pagination from '../components/Pagination';

const StoreManagementPage = () => {
  const [stores, setStores] = useState([]);
  const [locationLookup, setLocationLookup] = useState({ buildings: [], floors: [], rooms: [] });
  const [loading, setLoading] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');

  const [formData, setFormData] = useState({
    storeId: 0,
    storeName: '',
    storeCode: '',
    description: '',
    storeType: '',
    receiptType: 'A4 Paper',
    posType: 'Inventory',
    parentStoreId: '',
    buildingId: '',
    floorId: '',
    roomId: '',
    email: '',
    cellNumber: '',
    queuePatientCallStatusValue: 'At Dispense',
    markTokenAsAutoCollectedOnDispense: false,
    displayRequestsWithoutTokenIssued: false,
    englishNote: '',
    urduNote: '',
    serviceCharges: false,
    gst: false,
    pricingType: 'Branch Wise',
    disableRetailSale: false,
    gstn: '',
    ntn: '',
    dayClosing: 'Store Wise',
    closingCashAccountId: '',
    closingRevenueAccountId: '',
    closingInventoryAccountId: '',
    closingInventoryExpenseAccountId: '',
    closingTaxExpenseAccountId: '',
    payableAccountId: '',
    advanceTaxPercentageAccountId: '',
    revenueDiscountAccountId: '',
    address: '',
    latitude: '',
    longitude: '',
    country: 'Pakistan',
    stateOrProvince: 'Punjab',
    city: 'Rawalpindi',
    storeImage: '',
    isActive: true,
  });

  useEffect(() => {
    fetchStores();
    fetchLocationLookup();
  }, []);

  // getAllStores() (storeApi.js) already normalizes the raw Id/Name/ParentId/... API shape
  // to storeId/storeName/parentStoreName/... that this page's filter, table, and edit form
  // expect (mirroring StoreCreateRequest/StoreUpdateRequest) - no local mapping needed here.
  const fetchStores = async () => {
    setLoading(true);
    try {
      const data = await getAllStores();
      setStores(data || []);
    } catch (error) {
      console.error('Error fetching stores:', error);
      alert('Failed to fetch stores');
    } finally {
      setLoading(false);
    }
  };

  const fetchLocationLookup = async () => {
    try {
      const data = await getStoreLocationLookup();
      setLocationLookup({
        buildings: data?.buildings ?? [],
        floors: data?.floors ?? [],
        rooms: data?.rooms ?? [],
      });
    } catch (error) {
      console.error('Error fetching store location lookup:', error);
      alert('Failed to fetch building, floor, and room lookup data');
    }
  };

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;

    setFormData(prev => ({
      ...prev,
      ...(name === 'buildingId' ? { floorId: '', roomId: '' } : {}),
      ...(name === 'floorId' ? { roomId: '' } : {}),
      ...(name === 'storeType' && value === 'Main Store' ? { parentStoreId: '' } : {}),
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const availableFloors = formData.buildingId
    ? locationLookup.floors.filter((floor) => floor.buildingId === parseInt(formData.buildingId, 10))
    : [];

  const availableRooms = formData.floorId
    ? locationLookup.rooms.filter((room) => room.floorId === parseInt(formData.floorId, 10))
    : formData.buildingId
      ? locationLookup.rooms.filter((room) => room.buildingId === parseInt(formData.buildingId, 10))
      : [];

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!formData.storeName) {
      alert('Please enter store name');
      return;
    }

    try {
      const submitData = {
        ...formData,
        parentStoreId: formData.parentStoreId ? parseInt(formData.parentStoreId) : null,
        buildingId: formData.buildingId ? parseInt(formData.buildingId) : null,
        floorId: formData.floorId ? parseInt(formData.floorId) : null,
        roomId: formData.roomId ? parseInt(formData.roomId) : null,
        closingCashAccountId: formData.closingCashAccountId ? parseInt(formData.closingCashAccountId) : null,
        closingRevenueAccountId: formData.closingRevenueAccountId ? parseInt(formData.closingRevenueAccountId) : null,
        closingInventoryAccountId: formData.closingInventoryAccountId ? parseInt(formData.closingInventoryAccountId) : null,
        closingInventoryExpenseAccountId: formData.closingInventoryExpenseAccountId ? parseInt(formData.closingInventoryExpenseAccountId) : null,
        closingTaxExpenseAccountId: formData.closingTaxExpenseAccountId ? parseInt(formData.closingTaxExpenseAccountId) : null,
        payableAccountId: formData.payableAccountId ? parseInt(formData.payableAccountId) : null,
        advanceTaxPercentageAccountId: formData.advanceTaxPercentageAccountId ? parseInt(formData.advanceTaxPercentageAccountId) : null,
        revenueDiscountAccountId: formData.revenueDiscountAccountId ? parseInt(formData.revenueDiscountAccountId) : null,
      };

      if (editMode) {
        await updateStore(formData.storeId, submitData);
        alert('Store updated successfully');
      } else {
        await createStore(submitData);
        alert('Store created successfully');
      }

      handleCancel();
      fetchStores();
    } catch (error) {
      console.error('Error saving store:', error);
      alert('Failed to save store: ' + (error.response?.data?.message || error.message));
    }
  };

  const handleEdit = (store) => {
    setFormData({
      storeId: store.storeId,
      storeName: store.storeName,
      storeCode: store.storeCode || '',
      description: store.description || '',
      storeType: store.storeType || '',
      receiptType: store.receiptType || 'A4 Paper',
      posType: store.posType || 'Inventory',
      parentStoreId: store.parentStoreId || '',
      buildingId: store.buildingId || '',
      floorId: store.floorId || '',
      roomId: store.roomId || '',
      email: store.email || '',
      cellNumber: store.cellNumber || '',
      queuePatientCallStatusValue: store.queuePatientCallStatusValue || 'At Dispense',
      markTokenAsAutoCollectedOnDispense: store.markTokenAsAutoCollectedOnDispense || false,
      displayRequestsWithoutTokenIssued: store.displayRequestsWithoutTokenIssued || false,
      englishNote: store.englishNote || '',
      urduNote: store.urduNote || '',
      serviceCharges: store.serviceCharges || false,
      gst: store.gst || false,
      pricingType: store.pricingType || 'Branch Wise',
      disableRetailSale: store.disableRetailSale || false,
      gstn: store.gstn || '',
      ntn: store.ntn || '',
      dayClosing: store.dayClosing || 'Store Wise',
      closingCashAccountId: store.closingCashAccountId || '',
      closingRevenueAccountId: store.closingRevenueAccountId || '',
      closingInventoryAccountId: store.closingInventoryAccountId || '',
      closingInventoryExpenseAccountId: store.closingInventoryExpenseAccountId || '',
      closingTaxExpenseAccountId: store.closingTaxExpenseAccountId || '',
      payableAccountId: store.payableAccountId || '',
      advanceTaxPercentageAccountId: store.advanceTaxPercentageAccountId || '',
      revenueDiscountAccountId: store.revenueDiscountAccountId || '',
      address: store.address || '',
      latitude: store.latitude || '',
      longitude: store.longitude || '',
      country: store.country || 'Pakistan',
      stateOrProvince: store.stateOrProvince || 'Punjab',
      city: store.city || 'Rawalpindi',
      storeImage: store.storeImage || '',
      isActive: store.isActive,
    });
    setEditMode(true);
    setShowForm(true);
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this store?')) {
      try {
        await deleteStore(id);
        alert('Store deleted successfully');
        fetchStores();
      } catch (error) {
        console.error('Error deleting store:', error);
        alert('Failed to delete store: ' + (error.response?.data?.message || error.message));
      }
    }
  };

  const handleCancel = () => {
    setFormData({
      storeId: 0,
      storeName: '',
      storeCode: '',
      description: '',
      storeType: '',
      receiptType: 'A4 Paper',
      posType: 'Inventory',
      parentStoreId: '',
      buildingId: '',
      floorId: '',
      roomId: '',
      email: '',
      cellNumber: '',
      queuePatientCallStatusValue: 'At Dispense',
      markTokenAsAutoCollectedOnDispense: false,
      displayRequestsWithoutTokenIssued: false,
      englishNote: '',
      urduNote: '',
      serviceCharges: false,
      gst: false,
      pricingType: 'Branch Wise',
      disableRetailSale: false,
      gstn: '',
      ntn: '',
      dayClosing: 'Store Wise',
      closingCashAccountId: '',
      closingRevenueAccountId: '',
      closingInventoryAccountId: '',
      closingInventoryExpenseAccountId: '',
      closingTaxExpenseAccountId: '',
      payableAccountId: '',
      advanceTaxPercentageAccountId: '',
      revenueDiscountAccountId: '',
      address: '',
      latitude: '',
      longitude: '',
      country: 'Pakistan',
      stateOrProvince: 'Punjab',
      city: 'Rawalpindi',
      storeImage: '',
      isActive: true,
    });
    setEditMode(false);
    setShowForm(false);
  };

  // Pagination
  const filteredStores = stores.filter(store =>
    store.storeName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    store.storeCode?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    store.storeType?.toLowerCase().includes(searchTerm.toLowerCase())
  );
  
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = filteredStores.slice(indexOfFirstItem, indexOfLastItem);

  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, itemsPerPage]);

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="max-w-full mx-auto bg-white rounded-lg shadow-md p-6">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-blue-600 flex items-center gap-2">
            <span>ℹ️</span> Store Management
          </h1>
          {!showForm && (
            <button
              onClick={() => setShowForm(true)}
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 flex items-center gap-2"
            >
              <span>+</span> Add Store
            </button>
          )}
        </div>

        {showForm ? (
          /* Form Section */
          <div className="bg-white">
            <h2 className="text-xl font-semibold mb-4">
              {editMode ? 'Edit Store' : 'Add Store Management'}
            </h2>
            <form onSubmit={handleSubmit}>
              {/* Active Checkbox */}
              <div className="mb-4">
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    name="isActive"
                    checked={formData.isActive}
                    onChange={handleInputChange}
                    className="mr-2 h-4 w-4"
                  />
                  <span className="text-sm font-medium">Active</span>
                </label>
              </div>

              {/* Basic Information */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                {/* Branch - every store belongs to the logged-in user's own branch */}
                <BranchField />

                <div>
                  <label className="block text-sm font-medium mb-2">
                    Store Type<span className="text-red-500">*</span>
                  </label>
                  <select
                    name="storeType"
                    value={formData.storeType}
                    onChange={handleInputChange}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded"
                  >
                    <option value="">Select Store Type</option>
                    <option value="Main Store">Main Store</option>
                    <option value="Sub Store">Sub Store</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">
                    Receipt Type
                  </label>
                  <div className="flex items-center gap-4 mt-2">
                    <label className="flex items-center">
                      <input
                        type="radio"
                        name="receiptType"
                        value="A4 Paper"
                        checked={formData.receiptType === 'A4 Paper'}
                        onChange={handleInputChange}
                        className="mr-2"
                      />
                      <span className="text-sm">A4 Paper</span>
                    </label>
                    <label className="flex items-center">
                      <input
                        type="radio"
                        name="receiptType"
                        value="Thermal Paper"
                        checked={formData.receiptType === 'Thermal Paper'}
                        onChange={handleInputChange}
                        className="mr-2"
                      />
                      <span className="text-sm">Thermal Paper</span>
                    </label>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">
                    POS Type<span className="text-red-500">*</span>
                  </label>
                  <select
                    name="posType"
                    value={formData.posType}
                    onChange={handleInputChange}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded"
                  >
                    <option value="Inventory">Inventory</option>
                    <option value="POS">POS</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">
                    Parent Store{formData.storeType === 'Sub Store' && <span className="text-red-500">*</span>}
                  </label>
                  <select
                    name="parentStoreId"
                    value={formData.parentStoreId}
                    onChange={handleInputChange}
                    disabled={formData.storeType !== 'Sub Store'}
                    required={formData.storeType === 'Sub Store'}
                    className="w-full px-3 py-2 border border-gray-300 rounded disabled:bg-gray-100 disabled:text-gray-400"
                  >
                    <option value="">
                      {formData.storeType === 'Sub Store' ? 'Select Parent Store' : 'Not applicable for Main Store'}
                    </option>
                    {stores.filter(s => s.storeId !== formData.storeId).map(store => (
                      <option key={store.storeId} value={store.storeId}>
                        {store.storeName}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">
                    Building<span className="text-red-500">*</span>
                  </label>
                  <select
                    name="buildingId"
                    value={formData.buildingId}
                    onChange={handleInputChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded"
                  >
                    <option value="">Select Building</option>
                    {locationLookup.buildings.map((building) => (
                      <option key={building.id} value={building.id}>
                        {building.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">
                    Floor<span className="text-red-500">*</span>
                  </label>
                  <select
                    name="floorId"
                    value={formData.floorId}
                    onChange={handleInputChange}
                    disabled={!formData.buildingId}
                    className="w-full px-3 py-2 border border-gray-300 rounded"
                  >
                    <option value="">{formData.buildingId ? 'Select Floor' : 'Select Building First'}</option>
                    {availableFloors.map((floor) => (
                      <option key={floor.id} value={floor.id}>
                        {floor.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">
                    Room<span className="text-red-500">*</span>
                  </label>
                  <select
                    name="roomId"
                    value={formData.roomId}
                    onChange={handleInputChange}
                    disabled={!formData.floorId}
                    className="w-full px-3 py-2 border border-gray-300 rounded"
                  >
                    <option value="">{formData.floorId ? 'Select Room' : 'Select Floor First'}</option>
                    {availableRooms.map((room) => (
                      <option key={room.id} value={room.id}>
                        {room.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">
                    Store<span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="storeName"
                    value={formData.storeName}
                    onChange={handleInputChange}
                    required
                    placeholder="Store Name"
                    className="w-full px-3 py-2 border border-gray-300 rounded"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">
                    Email
                  </label>
                  <input
                    type="email"
                    name="email"
                    value={formData.email}
                    onChange={handleInputChange}
                    placeholder="Enter Email"
                    className="w-full px-3 py-2 border border-gray-300 rounded"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">
                    Cell Number
                  </label>
                  <input
                    type="text"
                    name="cellNumber"
                    value={formData.cellNumber}
                    onChange={handleInputChange}
                    placeholder="Enter Contact Number"
                    className="w-full px-3 py-2 border border-gray-300 rounded"
                  />
                </div>

                <div className="col-span-3">
                  <label className="block text-sm font-medium mb-2">
                    Description
                  </label>
                  <textarea
                    name="description"
                    value={formData.description}
                    onChange={handleInputChange}
                    rows={3}
                    placeholder="Store Description"
                    className="w-full px-3 py-2 border border-gray-300 rounded"
                  />
                </div>
              </div>

              {/* Store Image */}
              <div className="mb-6">
                <label className="block text-sm font-medium mb-2">
                  Store Image <span className="text-blue-500 cursor-pointer">📎</span>
                </label>
              </div>

              {/* Queue Patient Call Status Value */}
              <div className="mb-6">
                <h3 className="text-lg font-semibold mb-4 border-b pb-2">Queue Patient Call Status Value</h3>
                <div className="grid grid-cols-1 gap-4">
                  <div>
                    <select
                      name="queuePatientCallStatusValue"
                      value={formData.queuePatientCallStatusValue}
                      onChange={handleInputChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded"
                    >
                      <option value="At Dispense">At Dispense</option>
                      <option value="Other">Other</option>
                    </select>
                  </div>

                  <div className="flex items-center gap-6">
                    <label className="flex items-center">
                      <input
                        type="checkbox"
                        name="markTokenAsAutoCollectedOnDispense"
                        checked={formData.markTokenAsAutoCollectedOnDispense}
                        onChange={handleInputChange}
                        className="mr-2 h-4 w-4"
                      />
                      <span className="text-sm">Mark Token As Auto Collected On Dispense</span>
                    </label>

                    <label className="flex items-center">
                      <input
                        type="checkbox"
                        name="displayRequestsWithoutTokenIssued"
                        checked={formData.displayRequestsWithoutTokenIssued}
                        onChange={handleInputChange}
                        className="mr-2 h-4 w-4"
                      />
                      <span className="text-sm">Display Requests Without Token Issued In User Pharmacy Queue</span>
                    </label>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium mb-2">English Note</label>
                      <textarea
                        name="englishNote"
                        value={formData.englishNote}
                        onChange={handleInputChange}
                        rows={3}
                        placeholder="English Note"
                        className="w-full px-3 py-2 border border-gray-300 rounded"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium mb-2">Urdu Note اردو نوٹ</label>
                      <textarea
                        name="urduNote"
                        value={formData.urduNote}
                        onChange={handleInputChange}
                        rows={3}
                        placeholder="اردو نوٹ"
                        className="w-full px-3 py-2 border border-gray-300 rounded"
                        dir="rtl"
                      />
                    </div>
                  </div>
                </div>
              </div>

              {/* Day Closing Detail */}
              <div className="mb-6">
                <h3 className="text-lg font-semibold mb-4 border-b pb-2">Day Closing Detail</h3>
                <div className="grid grid-cols-1 gap-4">
                  <div>
                    <label className="block text-sm font-medium mb-2">Day Closing<span className="text-red-500">*</span></label>
                    <select
                      name="dayClosing"
                      value={formData.dayClosing}
                      onChange={handleInputChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded"
                    >
                      <option value="Store Wise">Store Wise</option>
                      <option value="Branch Wise">Branch Wise</option>
                    </select>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium mb-2">Closing Cash Account</label>
                      <select
                        name="closingCashAccountId"
                        value={formData.closingCashAccountId}
                        onChange={handleInputChange}
                        className="w-full px-3 py-2 border border-gray-300 rounded"
                      >
                        <option value="">Select</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium mb-2">Closing Revenue Account</label>
                      <select
                        name="closingRevenueAccountId"
                        value={formData.closingRevenueAccountId}
                        onChange={handleInputChange}
                        className="w-full px-3 py-2 border border-gray-300 rounded"
                      >
                        <option value="">Select</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium mb-2">Closing Inventory Account</label>
                      <select
                        name="closingInventoryAccountId"
                        value={formData.closingInventoryAccountId}
                        onChange={handleInputChange}
                        className="w-full px-3 py-2 border border-gray-300 rounded"
                      >
                        <option value="">Select</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium mb-2">Closing Inventory Expense Account</label>
                      <select
                        name="closingInventoryExpenseAccountId"
                        value={formData.closingInventoryExpenseAccountId}
                        onChange={handleInputChange}
                        className="w-full px-3 py-2 border border-gray-300 rounded"
                      >
                        <option value="">Select</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium mb-2">Closing Tax Expense Account</label>
                      <select
                        name="closingTaxExpenseAccountId"
                        value={formData.closingTaxExpenseAccountId}
                        onChange={handleInputChange}
                        className="w-full px-3 py-2 border border-gray-300 rounded"
                      >
                        <option value="">Select</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium mb-2">Payable Account</label>
                      <select
                        name="payableAccountId"
                        value={formData.payableAccountId}
                        onChange={handleInputChange}
                        className="w-full px-3 py-2 border border-gray-300 rounded"
                      >
                        <option value="">Select</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium mb-2">Advance Tax Percentage Account</label>
                      <select
                        name="advanceTaxPercentageAccountId"
                        value={formData.advanceTaxPercentageAccountId}
                        onChange={handleInputChange}
                        className="w-full px-3 py-2 border border-gray-300 rounded"
                      >
                        <option value="">Select</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium mb-2">Revenue Discount Account</label>
                      <select
                        name="revenueDiscountAccountId"
                        value={formData.revenueDiscountAccountId}
                        onChange={handleInputChange}
                        className="w-full px-3 py-2 border border-gray-300 rounded"
                      >
                        <option value="">Select</option>
                      </select>
                    </div>
                  </div>
                </div>
              </div>

              {/* Address Detail */}
              <div className="mb-6">
                <h3 className="text-lg font-semibold mb-4 border-b pb-2">Address Detail</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="col-span-2">
                    <label className="block text-sm font-medium mb-2">Address</label>
                    <input
                      type="text"
                      name="address"
                      value={formData.address}
                      onChange={handleInputChange}
                      placeholder="Address"
                      className="w-full px-3 py-2 border border-gray-300 rounded"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">Latitude</label>
                    <input
                      type="text"
                      name="latitude"
                      value={formData.latitude}
                      onChange={handleInputChange}
                      placeholder="Latitude"
                      className="w-full px-3 py-2 border border-gray-300 rounded"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">Longitude</label>
                    <input
                      type="text"
                      name="longitude"
                      value={formData.longitude}
                      onChange={handleInputChange}
                      placeholder="Longitude"
                      className="w-full px-3 py-2 border border-gray-300 rounded"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">Country</label>
                    <select
                      name="country"
                      value={formData.country}
                      onChange={handleInputChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded"
                    >
                      <option value="Pakistan">Pakistan</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">State Or Province</label>
                    <select
                      name="stateOrProvince"
                      value={formData.stateOrProvince}
                      onChange={handleInputChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded"
                    >
                      <option value="Punjab">Punjab</option>
                      <option value="Sindh">Sindh</option>
                      <option value="KPK">KPK</option>
                      <option value="Balochistan">Balochistan</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">City</label>
                    <select
                      name="city"
                      value={formData.city}
                      onChange={handleInputChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded"
                    >
                      <option value="Rawalpindi">Rawalpindi</option>
                      <option value="Islamabad">Islamabad</option>
                      <option value="Lahore">Lahore</option>
                      <option value="Karachi">Karachi</option>
                    </select>
                  </div>
                </div>
              </div>

              {/* Additional Settings */}
              <div className="mb-6">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="flex items-center gap-4">
                    <label className="text-sm font-medium">Service Charges</label>
                    <div className="flex gap-3">
                      <label className="flex items-center">
                        <input
                          type="radio"
                          name="serviceCharges"
                          checked={formData.serviceCharges === true}
                          onChange={() => setFormData(prev => ({ ...prev, serviceCharges: true }))}
                          className="mr-1"
                        />
                        <span className="text-sm">Yes</span>
                      </label>
                      <label className="flex items-center">
                        <input
                          type="radio"
                          name="serviceCharges"
                          checked={formData.serviceCharges === false}
                          onChange={() => setFormData(prev => ({ ...prev, serviceCharges: false }))}
                          className="mr-1"
                        />
                        <span className="text-sm">No</span>
                      </label>
                    </div>
                  </div>

                  <div className="flex items-center gap-4">
                    <label className="text-sm font-medium">GST</label>
                    <div className="flex gap-3">
                      <label className="flex items-center">
                        <input
                          type="radio"
                          name="gst"
                          checked={formData.gst === true}
                          onChange={() => setFormData(prev => ({ ...prev, gst: true }))}
                          className="mr-1"
                        />
                        <span className="text-sm">Yes</span>
                      </label>
                      <label className="flex items-center">
                        <input
                          type="radio"
                          name="gst"
                          checked={formData.gst === false}
                          onChange={() => setFormData(prev => ({ ...prev, gst: false }))}
                          className="mr-1"
                        />
                        <span className="text-sm">No</span>
                      </label>
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">Pricing Type<span className="text-red-500">*</span></label>
                    <select
                      name="pricingType"
                      value={formData.pricingType}
                      onChange={handleInputChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded"
                    >
                      <option value="Branch Wise">Branch Wise</option>
                      <option value="Store Wise">Store Wise</option>
                    </select>
                  </div>

                  <div className="flex items-center">
                    <label className="flex items-center">
                      <input
                        type="checkbox"
                        name="disableRetailSale"
                        checked={formData.disableRetailSale}
                        onChange={handleInputChange}
                        className="mr-2 h-4 w-4"
                      />
                      <span className="text-sm">Disable Retail Sale</span>
                    </label>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">GSTN</label>
                    <input
                      type="text"
                      name="gstn"
                      value={formData.gstn}
                      onChange={handleInputChange}
                      placeholder="GSTN"
                      className="w-full px-3 py-2 border border-gray-300 rounded"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">NTN</label>
                    <input
                      type="text"
                      name="ntn"
                      value={formData.ntn}
                      onChange={handleInputChange}
                      placeholder="NTN"
                      className="w-full px-3 py-2 border border-gray-300 rounded"
                    />
                  </div>
                </div>
              </div>

              {/* Form Buttons */}
              <div className="flex justify-end gap-2 mt-6">
                <button
                  type="button"
                  onClick={handleCancel}
                  className="px-6 py-2 border border-gray-300 rounded hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  Submit
                </button>
              </div>
            </form>
          </div>
        ) : (
          /* Table Section */
          <>
            {/* Table Header Info */}
            <div className="flex items-center justify-end mb-4">
              <div>
                <input
                  type="text"
                  placeholder="Search..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="px-3 py-1 border border-gray-300 rounded"
                />
              </div>
            </div>

            {/* Table */}
            {loading ? (
              <div className="text-center py-8">Loading...</div>
            ) : currentItems.length === 0 ? (
              <div className="text-center py-8 text-gray-500">No data available in table</div>
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Store
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Parent Store
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Store Type
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Updated On
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Status
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Action
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {currentItems.map((store) => (
                      <tr key={store.storeId} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {store.storeName}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {store.parentStoreName || '-'}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {store.storeType || '-'}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {store.modifiedOn ? new Date(store.modifiedOn).toLocaleDateString() : '-'}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          {store.isActive ? (
                            <span className="text-green-600">✓</span>
                          ) : (
                            <span className="text-red-600">✗</span>
                          )}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                          <div className="flex gap-2">
                            <button
                              onClick={() => handleEdit(store)}
                              className="text-blue-600 hover:text-blue-900"
                              title="Edit"
                            >
                              ✏️
                            </button>
                            <button
                              onClick={() => handleDelete(store.storeId)}
                              className="text-red-600 hover:text-red-900"
                              title="Delete"
                            >
                              🗑️
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}

            <Pagination
              currentPage={currentPage}
              pageSize={itemsPerPage}
              totalCount={filteredStores.length}
              onPageChange={setCurrentPage}
              onPageSizeChange={setItemsPerPage}
            />
          </>
        )}
      </div>
    </div>
  );
};

export default StoreManagementPage;
