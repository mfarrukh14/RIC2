import React, { useCallback, useState, useEffect } from 'react';
import contingentBillsApi from '../services/contingentBillsApi';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';

const ContingentBillsPage = () => {
  const [showForm, setShowForm] = useState(false);
  const [editingBill, setEditingBill] = useState(null);

  const [lookupData, setLookupData] = useState({
    financialYears: [],
    purchaseOrderTypes: [],
    vendors: [],
    branches: [],
    departments: []
  });

  // Filter states
  const [filters, setFilters] = useState({
    budgetSetupId: '',
    vendorId: '',
    financialYearId: '',
    poType: '',
    status: '',
    dateStart: '',
    dateEnd: ''
  });

  // Form data
  const [formData, setFormData] = useState({
    financialYearId: '',
    poType: '',
    poDate: '',
    mS: '',
    billNo: '',
    billDate: '',
    billAmount: '',
    budgetHead: '',
    budgetAllotment: '',
    totalPreviousBill: '',
    availableBalance: '',
    netPayment: '',
    totalUptoDate: '',
    taxAmount: '',
    grandTotal: '',
    remarks: '',
    stamp1: '',
    stamp2: '',
    stamp3: '',
    stamp4: '',
    stamp5: '',
    stamp6: '',
    preAuditedAmount: '',
    displayStampFormatForAuditSection: false,
    registerPageNo: '',
    tokenNo: '',
    serialNumber: '',
    date: ''
  });

  const [searchTerm, setSearchTerm] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('Pending');
  const [submittedFilters, setSubmittedFilters] = useState({
    budgetSetupId: '',
    vendorId: '',
    financialYearId: '',
    poType: '',
    status: '',
    dateStart: '',
    dateEnd: ''
  });
  const [formLoading, setFormLoading] = useState(false);
  const [formError, setFormError] = useState(null);

  const fetchPage = useCallback(async (params) => {
    const data = await contingentBillsApi.getAll(params);
    return { items: data.items || [], totalCount: data.totalCount || 0 };
  }, []);

  const {
    items: bills,
    totalCount,
    currentPage,
    pageSize: entriesPerPage,
    setPageSize: setEntriesPerPage,
    goToPage,
    loading,
    error,
    reload: reloadBills,
  } = usePagedList(fetchPage, { ...submittedFilters, searchTerm }, { initialPageSize: 10 });

  useEffect(() => {
    fetchLookupData();
  }, []);

  const fetchLookupData = async () => {
    try {
      const data = await contingentBillsApi.getLookupData();
      setLookupData(data);
    } catch (err) {
      console.error('Error fetching lookup data:', err);
    }
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setFilters(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleAdd = () => {
    setEditingBill(null);
    setFormData({
      financialYearId: '',
      poType: '',
      poDate: '',
      mS: '',
      billNo: '',
      billDate: '',
      billAmount: '',
      budgetHead: '',
      budgetAllotment: '',
      totalPreviousBill: '',
      availableBalance: '',
      netPayment: '',
      totalUptoDate: '',
      taxAmount: '',
      grandTotal: '',
      remarks: '',
      stamp1: '',
      stamp2: '',
      stamp3: '',
      stamp4: '',
      stamp5: '',
      stamp6: '',
      preAuditedAmount: '',
      displayStampFormatForAuditSection: false,
      registerPageNo: '',
      tokenNo: '',
      serialNumber: '',
      date: ''
    });
    setShowForm(true);
  };

  const handleCancel = () => {
    setShowForm(false);
    setEditingBill(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    try {
      setFormLoading(true);

      const submitData = {
        financialYearId: parseInt(formData.financialYearId),
        purchaseOrderTypeId: parseInt(formData.poType),
        purchaseOrderDate: formData.poDate,
        vendorId: parseInt(formData.mS),
        billNo: formData.billNo,
        billDate: formData.billDate,
        billAmount: parseFloat(formData.billAmount) || 0,
        budgetSetupId: formData.budgetHead,
        budgetAllotment: parseFloat(formData.budgetAllotment) || 0,
        totalPreviousBill: parseFloat(formData.totalPreviousBill) || 0,
        availableBalance: parseFloat(formData.availableBalance) || 0,
        netPayment: parseFloat(formData.netPayment) || 0,
        totalUptoDate: parseFloat(formData.totalUptoDate) || 0,
        taxAmount: parseFloat(formData.taxAmount) || 0,
        grandTotal: parseFloat(formData.grandTotal) || 0,
        remarks: formData.remarks,
        stamp1: formData.stamp1,
        stamp2: formData.stamp2,
        stamp3: formData.stamp3,
        stamp4: formData.stamp4,
        stamp5: formData.stamp5,
        stamp6: formData.stamp6,
        preAuditedAmount: parseFloat(formData.preAuditedAmount) || 0,
        displayStampFormatForAuditSection: formData.displayStampFormatForAuditSection,
        registerPageNo: formData.registerPageNo,
        tokenNo: formData.tokenNo,
        srno: formData.serialNumber,
        auditDate: formData.date,
        branchId: 1
      };

      if (editingBill) {
        await contingentBillsApi.update(editingBill.id, submitData);
      } else {
        await contingentBillsApi.create(submitData);
      }

      setShowForm(false);
      await reloadBills();
      setFormError(null);
    } catch (err) {
      console.error('Error saving bill:', err);
      setFormError('Failed to save contingent bill. Please try again.');
    } finally {
      setFormLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this contingent bill?')) {
      return;
    }

    try {
      await contingentBillsApi.delete(id);
      await reloadBills();
    } catch (err) {
      console.error('Error deleting bill:', err);
      alert('Failed to delete contingent bill. Please try again.');
    }
  };

  const handleSearch = () => {
    setSubmittedFilters({ ...filters });
  };

  // If showing form, render the form page
  if (showForm) {
    return (
      <div className="p-6">
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-gray-800">
            Add Contingent Bill
          </h1>
        </div>

        {formError && (
          <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-md">
            {formError}
          </div>
        )}

        <div className="bg-white rounded-lg shadow p-6">
          <form onSubmit={handleSubmit}>
            {/* Contingent Form Section */}
            <div className="mb-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4">Contingent Form</h2>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                {/* Financial Year */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Financial Year <span className="text-red-500">*</span>
                  </label>
                  <select
                    name="financialYearId"
                    value={formData.financialYearId}
                    onChange={handleInputChange}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Select Financial Year</option>
                    {lookupData.financialYears.map((year) => (
                      <option key={year.id} value={year.id}>
                        {year.name}
                      </option>
                    ))}
                  </select>
                </div>

                {/* PO Type */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    PO Type <span className="text-red-500">*</span>
                  </label>
                  <select
                    name="poType"
                    value={formData.poType}
                    onChange={handleInputChange}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Select Purchase Order Type</option>
                    {lookupData.purchaseOrderTypes.map((type) => (
                      <option key={type.id} value={type.id}>
                        {type.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                {/* PO No. */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    PO No. <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="billNo"
                    value={formData.billNo}
                    onChange={handleInputChange}
                    required
                    placeholder="Please Enter PO No."
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                {/* PO Date */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    PO Date <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="date"
                    name="poDate"
                    value={formData.poDate}
                    onChange={handleInputChange}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                {/* M/S */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    M/S <span className="text-red-500">*</span>
                  </label>
                  <select
                    name="mS"
                    value={formData.mS}
                    onChange={handleInputChange}
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

                {/* Budget Head */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Budget Head <span className="text-red-500">*</span>
                  </label>
                  <select
                    name="budgetHead"
                    value={formData.budgetHead}
                    onChange={handleInputChange}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Select Budget Head</option>
                    {lookupData.departments.map((dept) => (
                      <option key={dept.id} value={dept.id}>
                        {dept.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                {/* Bill No / Vendor Invoice No */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Bill No. / Vendor Invoice No <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="billNo"
                    value={formData.billNo}
                    onChange={handleInputChange}
                    required
                    placeholder="Please Enter Bill Number"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                {/* Bill Date / Vendor Invoice Date */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Bill Date / Vendor Invoice Date <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="date"
                    name="billDate"
                    value={formData.billDate}
                    onChange={handleInputChange}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                {/* Bill Amount */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Bill Amount
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    name="billAmount"
                    value={formData.billAmount}
                    onChange={handleInputChange}
                    placeholder="Please Enter Bill Amount"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                {/* Budget Allotment */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Budget Allotment
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    name="budgetAllotment"
                    value={formData.budgetAllotment}
                    onChange={handleInputChange}
                    placeholder="Please Enter Budget Allotment"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                {/* Total Upto Date */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Total Upto Date
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    name="totalUptoDate"
                    value={formData.totalUptoDate}
                    onChange={handleInputChange}
                    placeholder="Please Enter Total Upto Date"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                {/* Tax Amount */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Tax Amount
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    name="taxAmount"
                    value={formData.taxAmount}
                    onChange={handleInputChange}
                    placeholder="Please Enter Tax Amount"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                {/* Total Previous Bill */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Total Previous Bill
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    name="totalPreviousBill"
                    value={formData.totalPreviousBill}
                    onChange={handleInputChange}
                    placeholder="Please Enter Total Previous Bill"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                {/* Grand Total */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Grand Total
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    name="grandTotal"
                    value={formData.grandTotal}
                    onChange={handleInputChange}
                    placeholder="Please Enter Grand Total"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                {/* Available Balance */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Available Balance
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    name="availableBalance"
                    value={formData.availableBalance}
                    onChange={handleInputChange}
                    placeholder="Please Enter Available Balance"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                {/* Net Payment */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Net Payment
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    name="netPayment"
                    value={formData.netPayment}
                    onChange={handleInputChange}
                    placeholder="Please Enter Net Payment"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              {/* Remarks */}
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Remarks
                </label>
                <textarea
                  name="remarks"
                  value={formData.remarks}
                  onChange={handleInputChange}
                  rows="3"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              {/* Stamps */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Stamp 1
                  </label>
                  <select
                    name="stamp1"
                    value={formData.stamp1}
                    onChange={handleInputChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Select Stamp Configuration</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Stamp 2
                  </label>
                  <select
                    name="stamp2"
                    value={formData.stamp2}
                    onChange={handleInputChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Select Stamp Configuration</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Stamp 3
                  </label>
                  <select
                    name="stamp3"
                    value={formData.stamp3}
                    onChange={handleInputChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Select Stamp Configuration</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Stamp 4
                  </label>
                  <select
                    name="stamp4"
                    value={formData.stamp4}
                    onChange={handleInputChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Select Stamp Configuration</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Stamp 5
                  </label>
                  <select
                    name="stamp5"
                    value={formData.stamp5}
                    onChange={handleInputChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Select Stamp Configuration</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Stamp 6
                  </label>
                  <select
                    name="stamp6"
                    value={formData.stamp6}
                    onChange={handleInputChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Select Stamp Configuration</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                {/* Pre Audited Amount */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Pre Audited Amount
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    name="preAuditedAmount"
                    value={formData.preAuditedAmount}
                    onChange={handleInputChange}
                    placeholder="Please Enter Pre Audited Amount"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                {/* Stamp Format in Audit Section */}
                <div className="flex items-center pt-7">
                  <input
                    type="checkbox"
                    name="displayStampFormatForAuditSection"
                    checked={formData.displayStampFormatForAuditSection}
                    onChange={handleInputChange}
                    className="mr-2"
                  />
                  <label className="text-sm font-medium text-gray-700">
                    Stamp Format in Audit Section
                  </label>
                </div>
              </div>
            </div>

            {/* Register and Token No Section */}
            <div className="mb-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4">Register and Token No</h2>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                {/* Register Page */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Register Page
                  </label>
                  <input
                    type="text"
                    name="registerPageNo"
                    value={formData.registerPageNo}
                    onChange={handleInputChange}
                    placeholder="Enter Register Page"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                {/* Serial Number */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Serial Number
                  </label>
                  <input
                    type="text"
                    name="serialNumber"
                    value={formData.serialNumber}
                    onChange={handleInputChange}
                    placeholder="Please Enter Serial Number"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                {/* Token No */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Token No.
                  </label>
                  <input
                    type="text"
                    name="tokenNo"
                    value={formData.tokenNo}
                    onChange={handleInputChange}
                    placeholder="Enter Token No"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                {/* Date */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Date
                  </label>
                  <input
                    type="date"
                    name="date"
                    value={formData.date}
                    onChange={handleInputChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
            </div>

            {/* Forward Section would go here - shown in images but collapsed */}

            {/* Action Buttons */}
            <div className="flex justify-end gap-2 mt-6">
              <button
                type="button"
                onClick={handleCancel}
                className="px-6 py-2 text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={formLoading}
                className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-gray-400"
              >
                {formLoading ? 'Saving...' : 'Submit'}
              </button>
            </div>
          </form>
        </div>
      </div>
    );
  }

  // Main list view
  return (
    <div className="p-6">
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-800 flex items-center">
          <span className="mr-2">📄</span>
          Contingent Bills
          <span className="ml-2 text-blue-600 cursor-pointer">ⓘ</span>
        </h1>
        <div className="flex gap-2">
          <button className="px-4 py-2 bg-white border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 flex items-center gap-2">
            <span>⬇️</span>
            Export
          </button>
          <button
            onClick={handleAdd}
            className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 flex items-center gap-2"
          >
            <span className="text-xl">+</span>
            Add Contingent Bill
          </button>
        </div>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-md">
          Failed to fetch contingent bills. Please try again.
        </div>
      )}

      {/* Filters Section */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Budget Head
            </label>
            <select
              name="budgetSetupId"
              value={filters.budgetSetupId}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Budget Head</option>
              {lookupData.departments.map((dept) => (
                <option key={dept.id} value={dept.id}>
                  {dept.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Vendor
            </label>
            <select
              name="vendorId"
              value={filters.vendorId}
              onChange={handleFilterChange}
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

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              PO Type
            </label>
            <select
              name="poType"
              value={filters.poType}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Purchase Order Type</option>
              {lookupData.purchaseOrderTypes.map((type) => (
                <option key={type.id} value={type.id}>
                  {type.name}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Financial Year
            </label>
            <select
              name="financialYearId"
              value={filters.financialYearId}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Financial Year</option>
              {lookupData.financialYears.map((year) => (
                <option key={year.id} value={year.id}>
                  {year.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Contingent Bill Status
            </label>
            <select
              name="status"
              value={filters.status}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Status</option>
              <option value="Pending">Pending</option>
              <option value="Processed">Processed</option>
              <option value="Closed">Closed</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Date Range
            </label>
            <input
              type="text"
              value={`${filters.dateStart || '07-09-2025'} - ${filters.dateEnd || '06-10-2025'}`}
              readOnly
              className="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50"
            />
          </div>
        </div>

        <div className="flex justify-end">
          <button
            onClick={handleSearch}
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            Search
          </button>
        </div>

        {/* Status Radio Buttons */}
        <div className="flex items-center gap-6 mt-4">
          <label className="flex items-center">
            <input
              type="radio"
              name="statusFilter"
              value="Pending"
              checked={selectedStatus === 'Pending'}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="mr-2"
            />
            <span className="text-sm text-gray-700">Pending</span>
          </label>
          <label className="flex items-center">
            <input
              type="radio"
              name="statusFilter"
              value="Processed"
              checked={selectedStatus === 'Processed'}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="mr-2"
            />
            <span className="text-sm text-gray-700">Processed</span>
          </label>
          <label className="flex items-center">
            <input
              type="radio"
              name="statusFilter"
              value="Closed"
              checked={selectedStatus === 'Closed'}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="mr-2"
            />
            <span className="text-sm text-gray-700">Closed</span>
          </label>
        </div>
      </div>

      {/* Table Controls */}
      <div className="mb-4 flex justify-end items-center">
        <div className="flex items-center gap-2">
          <span className="text-sm text-gray-700">Search:</span>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                  Contingent Bill No
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                  Financial Year
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                  Budget Head Name
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                  Vendor Name
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                  PO Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                  Bill Amount
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                  Action On
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                  Action
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {loading ? (
                <tr>
                  <td colSpan="9" className="px-6 py-4 text-center text-sm text-gray-500">
                    Loading...
                  </td>
                </tr>
              ) : bills.length === 0 ? (
                <tr>
                  <td colSpan="9" className="px-6 py-8 text-center">
                    <div className="text-gray-500 mb-2">No data available in table</div>
                  </td>
                </tr>
              ) : (
                bills.map((bill) => (
                  <tr key={bill.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-900">
                      {bill.billNo || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {bill.financialYearName || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {bill.budgetSetupName || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {bill.vendorName || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {bill.purchaseOrderTypeName || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {bill.billAmount || '0.00'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {bill.createdOn ? new Date(bill.createdOn).toLocaleDateString() : '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {bill.contingentBillStatusId || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm">
                      <button
                        onClick={() => handleDelete(bill.id)}
                        className="text-red-600 hover:text-red-800"
                        title="Delete"
                      >
                        🗑️
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Pagination
        currentPage={currentPage}
        pageSize={entriesPerPage}
        totalCount={totalCount}
        onPageChange={goToPage}
        onPageSizeChange={setEntriesPerPage}
      />
    </div>
  );
};

export default ContingentBillsPage;
