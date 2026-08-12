import React,{ useCallback, useState, useEffect } from 'react';
import { stockValueItemsApi } from '../services/stockValueItemsApi';
import { getAllStores } from '../services/storeApi';
import { itemTypeApi } from '../services/itemTypeApi';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';
import { useSession } from '../context/SessionContext';

const StockValueWRTItemsPage = () => {
  const { session } = useSession();
  const [dateRangeEnabled, setDateRangeEnabled] = useState(false);
  const [startDate, setStartDate] = useState('2025-10-29');
  const [endDate, setEndDate] = useState('2025-10-29');
  const [selectedStore, setSelectedStore] = useState('');
  const [selectedItemType, setSelectedItemType] = useState('');
  const [stores, setStores] = useState([]);
  const [itemTypes, setItemTypes] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');

  const buildParams = (overrideSearchTerm) => {
    const params = {
      store: selectedStore || undefined,
      itemType: selectedItemType || undefined,
      searchTerm: (overrideSearchTerm !== undefined ? overrideSearchTerm : searchTerm) || undefined
    };

    if (dateRangeEnabled && startDate && endDate) {
      params.startDate = new Date(startDate).toISOString();
      params.endDate = new Date(endDate).toISOString();
    }

    return params;
  };

  const fetchPage = useCallback(async (params) => {
    const data = await stockValueItemsApi.getAll(params);
    return { items: data.items || [], totalCount: data.totalCount || 0 };
  }, []);

  const {
    items: stockValueItems,
    totalCount,
    currentPage,
    pageSize: itemsPerPage,
    setPageSize: setItemsPerPage,
    goToPage,
    search: runSearch,
    loading,
  } = usePagedList(fetchPage, buildParams(), { autoLoad: false, initialPageSize: 10 });

  useEffect(() => {
    fetchStores();
    fetchItemTypes();
    runSearch(buildParams());
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const fetchStores = async () => {
    try {
      const data = await getAllStores();
      setStores(data.filter(store => store.isActive));
    } catch (error) {
      console.error('Error fetching stores:', error);
    }
  };

  const fetchItemTypes = async () => {
    try {
      const data = await itemTypeApi.getAll();
      setItemTypes(data.filter(itemType => itemType.isActive));
    } catch (error) {
      console.error('Error fetching item types:', error);
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

    autoTable(doc, {
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

    autoTable(doc, {
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
    runSearch(buildParams());
  };

  const handleSearchTermChange = (value) => {
    setSearchTerm(value);
    runSearch(buildParams(value));
  };

  // "Item Wise Stock Report" export - RIC letterhead, User line, Filters line, then
  // the same Store/Name/Batch/Qty/Rate columns as the on-screen table, matching the
  // old system's export against the currently applied filters. Exports only the
  // currently-loaded page, not the whole filtered result set - results are now
  // paged server-side, same tradeoff as StockPage's export.
  const handleExport = async () => {
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
    } catch (err) {
      console.error('Logo load error:', err);
    }

    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('Rawalpindi Institute of Cardiology', pageWidth / 2, 16, { align: 'center' });
    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    doc.text('Rawal Road Rawalpindi, Punjab, Pakistan', pageWidth / 2, 22, { align: 'center' });
    doc.text('Email: info@ric.gov.pk, Phone: 0519281111-9', pageWidth / 2, 27, { align: 'center' });

    autoTable(doc, {
      startY: 33,
      body: [['Item Wise Stock Report']],
      theme: 'plain',
      styles: { fontSize: 11, fontStyle: 'bold', halign: 'center', lineColor: [0, 0, 0], lineWidth: 0.2, cellPadding: 2 }
    });

    const userLabel = session?.user?.UserName || session?.branchName || 'User';
    autoTable(doc, {
      startY: doc.lastAutoTable.finalY,
      body: [[`User: ${userLabel}`]],
      theme: 'plain',
      styles: { fontSize: 9, lineColor: [0, 0, 0], lineWidth: 0.2, cellPadding: 2 }
    });

    const storeLabel = selectedStore || 'All';
    const typeLabel = selectedItemType || 'All';
    const dateFilterLabel = dateRangeEnabled ? 'Yes' : 'No';
    autoTable(doc, {
      startY: doc.lastAutoTable.finalY,
      body: [[`Filters:  Store: ${storeLabel}   Type: ${typeLabel}   Is Date Range Filter Applied: ${dateFilterLabel}`]],
      theme: 'plain',
      styles: { fontSize: 9, lineColor: [0, 0, 0], lineWidth: 0.2, cellPadding: 2 }
    });

    const body = stockValueItems.map((item) => [
      item.storeName || 'N/A',
      item.name,
      item.batchNo || '-',
      Number(item.totalItems).toFixed(4),
      parseFloat(item.unitPurchaseRate).toFixed(2),
      parseFloat(item.totalPurchaseRate).toFixed(2),
      parseFloat(item.unitSaleRate).toFixed(2),
      parseFloat(item.totalSaleRate).toFixed(2)
    ]);

    autoTable(doc, {
      startY: doc.lastAutoTable.finalY,
      head: [['Store Name', 'Name', 'Batch No.', 'Total Items', 'Unit Purchase Rate', 'Total Purchase Rate', 'Unit Sale Rate', 'Total Sale Rate']],
      body,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 2, lineColor: [0, 0, 0], lineWidth: 0.1 },
      headStyles: { fillColor: [255, 255, 255], textColor: [0, 0, 0], fontStyle: 'bold', halign: 'center' },
      columnStyles: {
        3: { halign: 'right' },
        4: { halign: 'right' },
        5: { halign: 'right' },
        6: { halign: 'right' },
        7: { halign: 'right' }
      },
      didDrawPage: () => {
        const now = new Date();
        const dateStr = now.toLocaleDateString('en-US', { month: '2-digit', day: '2-digit', year: 'numeric' });
        const timeStr = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
        doc.setFontSize(8);
        doc.setFont('helvetica', 'normal');
        doc.text(`${dateStr} ${timeStr}`, 14, doc.internal.pageSize.height - 10);
      }
    });

    const pageCount = doc.internal.getNumberOfPages();
    for (let i = 1; i <= pageCount; i++) {
      doc.setPage(i);
      doc.setFontSize(8);
      doc.text(`Page ${i} of ${pageCount}`, pageWidth - 14, doc.internal.pageSize.height - 10, { align: 'right' });
    }

    doc.save(`ItemWiseStockReport_${new Date().toISOString().slice(0, 19).replace(/[:T]/g, '_')}.pdf`);
  };

  // Totals reflect only the current page now that results are paged server-side
  // (search/filtering also happens server-side - see buildParams/runSearch).
  const totals = stockValueItems.reduce((acc, item) => ({
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
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-blue-500 rounded flex items-center justify-center">
            <span className="text-white text-lg">📊</span>
          </div>
          <h1 className="text-2xl font-semibold">Stock Value Wrt Items</h1>
        </div>
        <button
          onClick={handleExport}
          disabled={stockValueItems.length === 0}
          className="flex items-center gap-2 px-4 py-2 border border-gray-300 rounded-md text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <span>⬇</span>
          Export
        </button>
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
            <select
              value={selectedItemType}
              onChange={(e) => setSelectedItemType(e.target.value)}
              className="w-full border rounded px-3 py-2 text-sm"
            >
              <option value="">All Types</option>
              {itemTypes.map(itemType => (
                <option key={itemType.id} value={itemType.name}>
                  {itemType.name}
                </option>
              ))}
            </select>
          </div>

          <div className="flex items-end">
            <button
              onClick={handleGenerate}
              disabled={loading}
              className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700 disabled:bg-blue-300"
            >
              {loading ? 'Generating...' : 'Generate'}
            </button>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-4 border-b flex justify-end items-center">
          <div className="flex items-center gap-2">
            <label className="text-sm">Search:</label>
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => handleSearchTermChange(e.target.value)}
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
              {stockValueItems.map((item, index) => (
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
              {/* Totals Row - current page only, now that results are paged server-side */}
              {stockValueItems.length > 0 && (
                <tr className="bg-gray-100 font-semibold">
                  <td className="px-4 py-3 text-sm" colSpan="3">Page Totals</td>
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

        <Pagination
          currentPage={currentPage}
          pageSize={itemsPerPage}
          totalCount={totalCount}
          onPageChange={goToPage}
          onPageSizeChange={setItemsPerPage}
        />
      </div>
    </div>
  );
};

export default StockValueWRTItemsPage;
