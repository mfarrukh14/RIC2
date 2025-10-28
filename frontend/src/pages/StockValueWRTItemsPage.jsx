import React,{ useState, useEffect } from 'react';
import { stockValueItemsApi } from '../services/stockValueItemsApi';
import { getAllStores } from '../services/storeApi';
import jsPDF from 'jspdf';
import 'jspdf-autotable';

const StockValueWRTItemsPage = () => {
  const [dateRangeEnabled, setDateRangeEnabled] = useState(false);
  const [startDate, setStartDate] = useState('2025-10-29');
  const [endDate, setEndDate] = useState('2025-10-29');
  const [selectedStore, setSelectedStore] = useState('');
  const [selectedItemType, setSelectedItemType] = useState('all');
  const [stores, setStores] = useState([]);
  const [stockValueItems, setStockValueItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchStores();
    fetchData();
  }, []);

  const fetchStores = async () => {
    try {
      const data = await getAllStores();
      setStores(data);
    } catch (error) {
      console.error('Error fetching stores:', error);
    }
  };

  const fetchData = async () => {
    try {
      setLoading(true);
      const params = {
        store: selectedStore || undefined,
        itemType: selectedItemType === 'all' ? undefined : selectedItemType
      };

      if (dateRangeEnabled && startDate && endDate) {
        params.startDate = new Date(startDate).toISOString();
        params.endDate = new Date(endDate).toISOString();
      }

      const data = await stockValueItemsApi.getAll(params);
      setStockValueItems(data);
    } catch (error) {
      console.error('Error fetching stock value items:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleBatchClick = async (batchNo, itemName) => {
    try {
      const report = await stockValueItemsApi.getGRNReport(batchNo, itemName);
      generatePDF(report);
    } catch (error) {
      console.error('Error fetching GRN report:', error);
      alert('Error generating report');
    }
  };

  const generatePDF = (report) => {
    const doc = new jsPDF();
    
    // Header
    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('Rawalpindi Institute of Cardiology', 105, 20, { align: 'center' });
    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.text('Rawal Road Rawalpindi, Punjab, Pakistan', 105, 26, { align: 'center' });
    doc.text('E-mail: info@ric.gov.pk  Phone: 051028111-5', 105, 31, { align: 'center' });
    
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('Goods Receiving Note', 105, 40, { align: 'center' });

    // GRN Details Table
    const formatDate = (dateStr) => {
      if (!dateStr) return '';
      const date = new Date(dateStr);
      return `${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}-${date.getFullYear()}`;
    };

    const headerData = [
      ['Inventory No:', report.inventoryNo || '', 'PO Number:', report.poNumber || ''],
      ['Entered By:', report.enteredBy || '', 'PO Date:', report.poDate || ''],
      ['Date & Time:', formatDate(report.dateAndTime), 'Manual PO Number:', report.manualPONumber || ''],
      ['Vendor Address:', report.vendorAddress || '', 'Stock Type:', report.stockType || ''],
      ['', '', '', report.regular || ''],
      ['', '', 'Store Name:', report.storeName || ''],
      ['Vendor Email:', report.vendorEmail || '', 'Vendor Contact No:', report.vendorContactNo || '']
    ];

    doc.autoTable({
      startY: 48,
      body: headerData,
      theme: 'plain',
      styles: { fontSize: 8, cellPadding: 2, lineColor: [200, 200, 200], lineWidth: 0.1 },
      columnStyles: {
        0: { fontStyle: 'bold', cellWidth: 35 },
        1: { cellWidth: 60 },
        2: { fontStyle: 'bold', cellWidth: 35 },
        3: { cellWidth: 50 }
      }
    });

    // Items Table
    const itemsData = report.items.map((item, index) => [
      index + 1,
      item.items || '',
      item.mfr || '',
      item.mfgDate ? formatDate(item.mfgDate) : '',
      item.expDate ? formatDate(item.expDate) : '',
      item.batchNo || '',
      item.boxes || 0,
      item.packs || 0,
      item.qtyPerPack || 0,
      item.totalQty || 0,
      item.packQty || 0,
      item.totalPrice?.toFixed(2) || '0.00',
      item.unitPrice?.toFixed(2) || '0.00',
      item.advanceTax?.toFixed(2) || '0.00',
      item.advanceTaxAmount?.toFixed(2) || '0.00',
      item.unitSalePrice?.toFixed(2) || '0.00',
      item.retailCharges?.toFixed(2) || '0.00',
      item.retailChargesAmount?.toFixed(2) || '0.00',
      item.gstCharges?.toFixed(2) || '0.00',
      item.gstChargesAmount?.toFixed(2) || '0.00',
      item.totalSalePrice?.toFixed(2) || '0.00',
      item.margin?.toFixed(2) || '0.00',
      item.amount?.toFixed(2) || '0.00',
      item.discount?.toFixed(2) || '0.00',
      item.total?.toFixed(2) || '0.00'
    ]);

    doc.autoTable({
      startY: doc.lastAutoTable.finalY + 5,
      head: [[
        'Sr',
        'Items',
        'Mfr',
        'Mfg Date',
        'Exp. Date',
        'Batch No.',
        'Boxes',
        'Packs',
        'Qty/ Pack',
        'Total Qty',
        'Pack Qty',
        'Total Price',
        'Unit Price',
        'Advance Tax %',
        'Advance Tax Amount',
        'Unit Sale Price',
        'Retail Charges',
        'Retail Charges Amount',
        'GST Charges',
        'GST Charges Amount',
        'Total Sale Price',
        'Margin %',
        'Amount',
        'Discount',
        'Total'
      ]],
      body: itemsData,
      theme: 'plain',
      styles: { fontSize: 6, cellPadding: 1, lineColor: [200, 200, 200], lineWidth: 0.1 },
      headStyles: { fillColor: [240, 240, 240], textColor: 0, fontStyle: 'bold', lineColor: [200, 200, 200], lineWidth: 0.1 },
      columnStyles: {
        0: { cellWidth: 8 },
        1: { cellWidth: 20 },
        2: { cellWidth: 15 }
      },
      margin: { left: 5, right: 5 }
    });

    // Totals
    const totalsY = doc.lastAutoTable.finalY + 5;
    doc.setFontSize(9);
    doc.setFont('helvetica', 'bold');
    doc.text(`Amount: ${report.subTotal?.toFixed(2) || '0.00'}`, 14, totalsY);
    doc.text(`Discount: ${report.discount?.toFixed(2) || '0.00'}`, 14, totalsY + 5);
    doc.text(`Total: ${report.total?.toFixed(2) || '0.00'}`, 14, totalsY + 10);

    // Footer
    doc.setFontSize(8);
    doc.setFont('helvetica', 'italic');
    doc.text('This is a computer generated document, therefore signatures are not required.', 105, doc.internal.pageSize.height - 10, { align: 'center' });
    doc.setFont('helvetica', 'normal');
    const now = new Date();
    doc.text(`${formatDate(now)} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`, 14, doc.internal.pageSize.height - 10);

    // Save PDF
    doc.save(`InventoryReport_${report.inventoryNo || 'GRN'}.pdf`);
  };

  const handleGenerate = () => {
    fetchData();
  };

  const filteredItems = stockValueItems.filter(item =>
    item.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    item.batchNo?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = filteredItems.slice(indexOfFirstItem, indexOfLastItem);
  const totalPages = Math.ceil(filteredItems.length / itemsPerPage);

  // Calculate totals
  const totals = filteredItems.reduce((acc, item) => ({
    totalItems: acc.totalItems + item.totalItems,
    unitPurchaseRate: acc.unitPurchaseRate + parseFloat(item.unitPurchaseRate),
    totalPurchaseRate: acc.totalPurchaseRate + parseFloat(item.totalPurchaseRate),
    unitSaleRate: acc.unitSaleRate + parseFloat(item.unitSaleRate),
    totalSaleRate: acc.totalSaleRate + parseFloat(item.totalSaleRate)
  }), {
    totalItems: 0,
    unitPurchaseRate: 0,
    totalPurchaseRate: 0,
    unitSaleRate: 0,
    totalSaleRate: 0
  });

  return (
    <div className="p-6">
      <div className="flex items-center gap-2 mb-6">
        <div className="w-8 h-8 bg-blue-500 rounded flex items-center justify-center">
          <span className="text-white text-lg">📊</span>
        </div>
        <h1 className="text-2xl font-semibold">Stock Value Wrt Items</h1>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-4 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">
          <div>
            <label className="flex items-center gap-2 mb-2">
              <input
                type="checkbox"
                checked={dateRangeEnabled}
                onChange={(e) => setDateRangeEnabled(e.target.checked)}
                className="rounded"
              />
              <span className="text-sm font-medium">Is Date Range is applied for filter</span>
            </label>
            <label className="block text-sm font-medium mb-1">Date Range</label>
            <div className="flex gap-2 items-center">
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                disabled={!dateRangeEnabled}
                className="flex-1 border rounded px-3 py-2 text-sm disabled:bg-gray-100"
              />
              <span>-</span>
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                disabled={!dateRangeEnabled}
                className="flex-1 border rounded px-3 py-2 text-sm disabled:bg-gray-100"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Store</label>
            <select
              value={selectedStore}
              onChange={(e) => setSelectedStore(e.target.value)}
              className="w-full border rounded px-3 py-2 text-sm"
            >
              <option value="">All Stores</option>
              {stores.map(store => (
                <option key={store.storeId} value={store.storeName}>
                  {store.storeName}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Item Type</label>
            <div className="flex gap-4 mt-2">
              <label className="flex items-center gap-2">
                <input
                  type="radio"
                  value="all"
                  checked={selectedItemType === 'all'}
                  onChange={(e) => setSelectedItemType(e.target.value)}
                  className="rounded-full"
                />
                <span className="text-sm">All</span>
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="radio"
                  value="medicine"
                  checked={selectedItemType === 'medicine'}
                  onChange={(e) => setSelectedItemType(e.target.value)}
                  className="rounded-full"
                />
                <span className="text-sm">Medicine</span>
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="radio"
                  value="disposable"
                  checked={selectedItemType === 'disposable'}
                  onChange={(e) => setSelectedItemType(e.target.value)}
                  className="rounded-full"
                />
                <span className="text-sm">Disposable</span>
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="radio"
                  value="item"
                  checked={selectedItemType === 'item'}
                  onChange={(e) => setSelectedItemType(e.target.value)}
                  className="rounded-full"
                />
                <span className="text-sm">Item</span>
              </label>
            </div>
          </div>

          <div className="flex items-end">
            <button
              onClick={handleGenerate}
              className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700"
            >
              Generate
            </button>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-4 border-b flex justify-between items-center">
          <div className="flex items-center gap-2">
            <label className="text-sm">Show</label>
            <select
              value={itemsPerPage}
              onChange={(e) => setItemsPerPage(Number(e.target.value))}
              className="border rounded px-2 py-1 text-sm"
            >
              <option value={10}>10</option>
              <option value={25}>25</option>
              <option value={50}>50</option>
              <option value={100}>100</option>
            </select>
            <label className="text-sm">entries</label>
          </div>
          <div className="flex items-center gap-2">
            <label className="text-sm">Search:</label>
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="border rounded px-3 py-1 text-sm"
            />
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Store Name ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Name ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Batch No. ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Total Items ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Unit Purchase Rate ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Total Purchase Rate ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Unit Sale Rate ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Total Sale Rate ↕</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {currentItems.map((item, index) => (
                <tr key={index} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-sm">{item.storeName || 'N/A'}</td>
                  <td className="px-4 py-3 text-sm">{item.name}</td>
                  <td className="px-4 py-3 text-sm">
                    <button
                      onClick={() => handleBatchClick(item.batchNo, item.name)}
                      className="text-blue-600 hover:underline"
                    >
                      {item.batchNo}
                    </button>
                  </td>
                  <td className="px-4 py-3 text-sm">{item.totalItems}</td>
                  <td className="px-4 py-3 text-sm">{parseFloat(item.unitPurchaseRate).toFixed(2)}</td>
                  <td className="px-4 py-3 text-sm">{parseFloat(item.totalPurchaseRate).toFixed(2)}</td>
                  <td className="px-4 py-3 text-sm">{parseFloat(item.unitSaleRate).toFixed(2)}</td>
                  <td className="px-4 py-3 text-sm">{parseFloat(item.totalSaleRate).toFixed(2)}</td>
                </tr>
              ))}
              {/* Totals Row */}
              {filteredItems.length > 0 && (
                <tr className="bg-gray-100 font-semibold">
                  <td className="px-4 py-3 text-sm" colSpan="3">Store Name</td>
                  <td className="px-4 py-3 text-sm">Total Items:{totals.totalItems.toFixed(2)}</td>
                  <td className="px-4 py-3 text-sm">Unit Purchase Rate: {totals.unitPurchaseRate.toFixed(2)}</td>
                  <td className="px-4 py-3 text-sm">Total Purchase Rate: {totals.totalPurchaseRate.toFixed(2)}</td>
                  <td className="px-4 py-3 text-sm">Unit Sale Rate: {totals.unitSaleRate.toFixed(2)}</td>
                  <td className="px-4 py-3 text-sm">Total Sale Rate: {totals.totalSaleRate.toFixed(2)}</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        <div className="p-4 border-t flex justify-between items-center">
          <div className="text-sm text-gray-600">
            Showing {indexOfFirstItem + 1} to {Math.min(indexOfLastItem, filteredItems.length)} of {filteredItems.length} entries
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
              disabled={currentPage === 1}
              className="px-3 py-1 border rounded text-sm disabled:opacity-50"
            >
              Previous
            </button>
            {[...Array(totalPages)].map((_, i) => (
              <button
                key={i + 1}
                onClick={() => setCurrentPage(i + 1)}
                className={`px-3 py-1 border rounded text-sm ${
                  currentPage === i + 1 ? 'bg-blue-600 text-white' : ''
                }`}
              >
                {i + 1}
              </button>
            ))}
            <button
              onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
              disabled={currentPage === totalPages}
              className="px-3 py-1 border rounded text-sm disabled:opacity-50"
            >
              Next
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default StockValueWRTItemsPage;
