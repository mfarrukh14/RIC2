import React, { useCallback, useState, useEffect } from 'react';
import { FiPlus, FiEdit2, FiTrash2, FiSearch, FiPrinter, FiCornerUpLeft } from 'react-icons/fi';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import inventoryApi from '../services/inventoryApi';
import InventoryFormPage from '../components/InventoryFormPage';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';

const InventoryListPage = ({ onReturnInventory }) => {
  const [vendors, setVendors] = useState([]);
  const [stores, setStores] = useState([]);

  // Filters
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [selectedVendor, setSelectedVendor] = useState('');
  const [selectedStore, setSelectedStore] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [selectedInventory, setSelectedInventory] = useState(null);

  const fetchPage = useCallback(async (params) => {
    const data = await inventoryApi.getAll(params);
    return { items: data.items || [], totalCount: data.totalCount || 0 };
  }, []);

  const {
    items: inventories,
    totalCount,
    currentPage,
    pageSize: entriesPerPage,
    setPageSize: setEntriesPerPage,
    goToPage,
    loading,
    error,
    reload: reloadInventories,
  } = usePagedList(
    fetchPage,
    {
      searchTerm,
      vendorId: selectedVendor || null,
      storeId: selectedStore || null,
      dateFrom: dateFrom || null,
      dateTo: dateTo || null,
    },
    { initialPageSize: 10 }
  );

  useEffect(() => {
    fetchLookupData();
  }, []);

  const fetchLookupData = async () => {
    try {
      const lookupData = await inventoryApi.getLookupData();
      setVendors(lookupData.vendors);
      setStores(lookupData.stores);
    } catch (err) {
      console.error('Error fetching lookup data:', err);
    }
  };

  const handleAddNew = () => {
    setSelectedInventory(null);
    setShowForm(true);
  };

  const handleEdit = (inventory) => {
    setSelectedInventory(inventory);
    setShowForm(true);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this inventory?')) {
      return;
    }

    try {
      await inventoryApi.delete(id);
      await reloadInventories();
    } catch (err) {
      console.error('Error deleting inventory:', err);
      alert('Failed to delete inventory. Please try again.');
    }
  };

  // Prints this Add Inventory record - RIC letterhead, header fields, and an item
  // table pulled from the record's full detail lines.
  const handlePrint = async (inventory) => {
    let full;
    try {
      full = await inventoryApi.getById(inventory.id);
    } catch (err) {
      console.error('Error loading inventory for print:', err);
      alert('Failed to load this inventory record for printing.');
      return;
    }

    const doc = new jsPDF();
    const pageWidth = doc.internal.pageSize.width;

    try {
      const logoImg = new Image();
      logoImg.src = '/logo.jpg';
      await new Promise((resolve) => {
        logoImg.onload = () => {
          doc.addImage(logoImg, 'JPEG', 14, 10, 18, 18);
          resolve();
        };
        logoImg.onerror = () => resolve();
      });
    } catch (logoError) {
      console.error('Logo load error:', logoError);
    }

    doc.setFontSize(15);
    doc.setFont('helvetica', 'bold');
    doc.text('Rawalpindi Institute of Cardiology', pageWidth / 2, 16, { align: 'center' });

    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    doc.text('Rawal Road', pageWidth / 2, 22, { align: 'center' });
    doc.text('Email: info@ric.gov.pk, Ph: 051928111-9', pageWidth / 2, 27, { align: 'center' });

    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('Add Inventory', pageWidth / 2, 36, { align: 'center' });

    autoTable(doc, {
      startY: 42,
      body: [
        ['Vendor Invoice No', full.vendorInvoiceNumber || '-', 'Vendor', full.vendorName || '-'],
        ['Store', full.storeName || '-', 'Stock Type', full.stockTypeName || '-'],
        ['Date & Time', formatDate(full.createdOn), '', '']
      ],
      theme: 'grid',
      styles: { fontSize: 9, cellPadding: 3, lineColor: [0, 0, 0], lineWidth: 0.1 },
      columnStyles: {
        0: { fontStyle: 'bold', cellWidth: 40 },
        1: { cellWidth: 55 },
        2: { fontStyle: 'bold', cellWidth: 40 },
        3: { cellWidth: 55 }
      }
    });

    const itemsBody = (full.details || []).map((detail, index) => [
      index + 1,
      detail.itemName || 'Unassigned Item',
      detail.totalItems ?? 0,
      detail.unitBuyingPrice ?? 0,
      detail.unitSellingPrice ?? 0,
      detail.expiryDate ? formatDate(detail.expiryDate) : '-'
    ]);

    autoTable(doc, {
      startY: doc.lastAutoTable.finalY + 6,
      head: [['Sr.', 'Item', 'Total Items', 'Unit Buying Price', 'Unit Selling Price', 'Expiry Date']],
      body: itemsBody,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 2, lineColor: [0, 0, 0], lineWidth: 0.1 },
      headStyles: { fillColor: [255, 255, 255], textColor: [0, 0, 0], fontStyle: 'bold', halign: 'center' },
      columnStyles: {
        0: { cellWidth: 10, halign: 'center' },
        2: { halign: 'right' },
        3: { halign: 'right' },
        4: { halign: 'right' }
      }
    });

    const now = new Date();
    const dateStr = now.toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' });
    const timeStr = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
    doc.setFontSize(8);
    doc.setFont('helvetica', 'normal');
    doc.text(`${dateStr}   ${timeStr}`, 14, doc.internal.pageSize.height - 10);
    doc.text('Page 1 of 1', pageWidth - 14, doc.internal.pageSize.height - 10, { align: 'right' });

    doc.save(`AddInventory_${full.vendorInvoiceNumber || full.id}.pdf`);
  };

  const handleReturnInventory = (inventory) => {
    if (!onReturnInventory) return;
    onReturnInventory({ storeId: inventory.storeId });
  };

  const handleCancelForm = () => {
    setShowForm(false);
    setSelectedInventory(null);
  };

  const handleSaveForm = async () => {
    setShowForm(false);
    setSelectedInventory(null);
    await reloadInventories();
  };

  const formatDate = (dateString) => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleString();
  };

  return (
    <div className="p-6">
      {showForm ? (
        <InventoryFormPage 
          inventory={selectedInventory}
          onSave={handleSaveForm}
          onCancel={handleCancelForm}
        />
      ) : (
        <>
          {/* Header */}
          <div className="mb-6 flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-800">Add Inventory</h1>
        <button
          onClick={handleAddNew}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          <FiPlus className="h-5 w-5" />
          Add Inventory
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-4 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Date Range
            </label>
            <div className="flex gap-2">
              <input
                type="date"
                value={dateFrom}
                onChange={(e) => setDateFrom(e.target.value)}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <span className="flex items-center">-</span>
              <input
                type="date"
                value={dateTo}
                onChange={(e) => setDateTo(e.target.value)}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Vendor
            </label>
            <select
              value={selectedVendor}
              onChange={(e) => setSelectedVendor(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Vendor</option>
              {vendors.map((vendor) => (
                <option key={vendor.id} value={vendor.id}>
                  {vendor.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Store
            </label>
            <select
              value={selectedStore}
              onChange={(e) => setSelectedStore(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Store</option>
              {stores.map((store) => (
                <option key={store.storeId} value={store.storeId}>
                  {store.storeName}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Search
            </label>
            <div className="relative">
              <FiSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Search..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>
        </div>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-md">
          Failed to fetch inventories. Please try again.
        </div>
      )}

      {/* Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Invoice Number
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Stock Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Vendor
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Store
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Items (Quantity)
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date &amp; Time
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {inventories.length === 0 ? (
                <tr>
                  <td colSpan="7" className="px-6 py-4 text-center text-sm text-gray-500">
                    {loading ? 'Loading...' : 'No data available in table'}
                  </td>
                </tr>
              ) : (
                inventories.map((inventory) => (
                  <tr key={inventory.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {inventory.vendorInvoiceNumber || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {inventory.stockTypeName || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {inventory.vendorName || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {inventory.storeName || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {inventory.totalQuantity || 0}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(inventory.createdOn)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button
                        onClick={() => handleEdit(inventory)}
                        className="text-indigo-600 hover:text-indigo-900 mr-4"
                        title="Edit"
                      >
                        <FiEdit2 className="h-5 w-5" />
                      </button>
                      <button
                        onClick={() => handlePrint(inventory)}
                        className="text-emerald-600 hover:text-emerald-900 mr-4"
                        title="Print"
                      >
                        <FiPrinter className="h-5 w-5" />
                      </button>
                      <button
                        onClick={() => handleReturnInventory(inventory)}
                        className="text-amber-600 hover:text-amber-900 mr-4"
                        title="Return Inventory"
                      >
                        <FiCornerUpLeft className="h-5 w-5" />
                      </button>
                      <button
                        onClick={() => handleDelete(inventory.id)}
                        className="text-red-600 hover:text-red-900"
                        title="Delete"
                      >
                        <FiTrash2 className="h-5 w-5" />
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
        </>
      )}
    </div>
  );
};

export default InventoryListPage;
