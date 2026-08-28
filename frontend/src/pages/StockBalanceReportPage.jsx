import React,{ useState, useEffect } from 'react';
import { stockBalanceReportApi } from '../services/stockBalanceReportApi';
import { getAllStores } from '../services/storeApi';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import BranchField from '../components/BranchField';
import { useSession } from '../context/SessionContext';

const getToday = () => new Date().toISOString().split('T')[0];

const StockBalanceReportPage = () => {
  const { session } = useSession();
  const [startDate, setStartDate] = useState(getToday());
  const [endDate, setEndDate] = useState(getToday());
  const [selectedStore, setSelectedStore] = useState('');
  const [selectedBranch, setSelectedBranch] = useState('Rawalpindi Institute of Cardiology');
  const [stores, setStores] = useState([]);
  const [report, setReport] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchStores();
  }, []);

  // The report is always scoped to the logged-in user's own branch.
  useEffect(() => {
    if (session?.branchName) {
      setSelectedBranch(session.branchName);
    }
  }, [session?.branchName]);

  const fetchStores = async () => {
    try {
      const data = await getAllStores();
      setStores(data.filter(store => store.isActive));
    } catch (error) {
      console.error('Error fetching stores:', error);
    }
  };

  const fetchReport = async () => {
    try {
      setLoading(true);
      const params = {
        startDate: startDate ? new Date(startDate + 'T00:00:00').toISOString() : undefined,
        endDate: endDate ? new Date(endDate + 'T23:59:59').toISOString() : undefined,
        store: selectedStore || undefined,
        branch: selectedBranch || undefined
      };

      const data = await stockBalanceReportApi.getReport(params);
      
      // Ensure report is set even if no data, with default values
      if (!data || !data.summary) {
        setReport({
          user: "Mr. Branch Administrator",
          fromDate: startDate ? new Date(startDate + 'T00:00:00').toISOString() : new Date().toISOString(),
          toDate: endDate ? new Date(endDate + 'T23:59:59').toISOString() : new Date().toISOString(),
          storeName: selectedStore || "All Stores",
          summary: {
            openingStockPurchase: 0,
            openingStockSale: 0,
            purchaseStockPurchase: 0,
            purchaseStockSale: 0,
            patientBillReturnPurchase: 0,
            patientBillReturnSale: 0,
            buyDemandReceivedStockPurchase: 0,
            buyDemandReceivedStockSale: 0,
            procedureMedicinesReceivedStockPurchase: 0,
            procedureMedicinesReceivedStockSale: 0,
            procedureFeeReceivedPurchase: 0,
            procedureFeeReceivedSale: 0,
            ordersReceivedPurchase: 0,
            ordersReceivedSale: 0,
            assetAllocationReceivedStockPurchase: 0,
            assetAllocationReceivedStockSale: 0,
            customerChallanFormsReceivedPurchase: 0,
            customerChallanFormsReceivedSale: 0,
            stockAuditPurchase: 0,
            stockAuditSale: 0,
            sampleCollectionConsumptionItemsReceivedPurchase: 0,
            sampleCollectionConsumptionItemsReceivedSale: 0,
            stockWastageReceivedPurchase: 0,
            stockWastageReceivedSale: 0,
            stockReturnReceivedPurchase: 0,
            stockReturnReceivedSale: 0,
            saleStockPurchase: 0,
            saleStockSale: 0,
            purchaseReturnPurchase: 0,
            purchaseReturnSale: 0,
            stockExpiredAndDamagedPurchase: 0,
            stockExpiredAndDamagedSale: 0,
            saleDemandIssuedStockPurchase: 0,
            saleDemandIssuedStockSale: 0,
            procedureMedicinesPurchase: 0,
            procedureMedicinesSale: 0,
            procedureFeePurchase: 0,
            procedureFeeSale: 0,
            ordersIssuedPurchase: 0,
            ordersIssuedSale: 0,
            assetAllocationPurchase: 0,
            assetAllocationSale: 0,
            customerChallanFormsIssuedPurchase: 0,
            customerChallanFormsIssuedSale: 0,
            stockAuditOutPurchase: 0,
            stockAuditOutSale: 0,
            sampleCollectionConsumptionItemsIssuedPurchase: 0,
            sampleCollectionConsumptionItemsIssuedSale: 0,
            stockWastagePurchase: 0,
            stockWastageSale: 0,
            stockReturnPurchase: 0,
            stockReturnSale: 0,
            closingStockPurchase: 0,
            closingStockSale: 0
          }
        });
      } else {
        setReport(data);
      }
    } catch (error) {
      console.error('Error fetching stock balance report:', error);
      // Set default report even on error
      setReport({
        user: "Mr. Branch Administrator",
        fromDate: startDate ? new Date(startDate + 'T00:00:00').toISOString() : new Date().toISOString(),
        toDate: endDate ? new Date(endDate + 'T23:59:59').toISOString() : new Date().toISOString(),
        storeName: selectedStore || "All Stores",
        summary: {
          openingStockPurchase: 0,
          openingStockSale: 0,
          purchaseStockPurchase: 0,
          purchaseStockSale: 0,
          patientBillReturnPurchase: 0,
          patientBillReturnSale: 0,
          buyDemandReceivedStockPurchase: 0,
          buyDemandReceivedStockSale: 0,
          procedureMedicinesReceivedStockPurchase: 0,
          procedureMedicinesReceivedStockSale: 0,
          procedureFeeReceivedPurchase: 0,
          procedureFeeReceivedSale: 0,
          ordersReceivedPurchase: 0,
          ordersReceivedSale: 0,
          assetAllocationReceivedStockPurchase: 0,
          assetAllocationReceivedStockSale: 0,
          customerChallanFormsReceivedPurchase: 0,
          customerChallanFormsReceivedSale: 0,
          stockAuditPurchase: 0,
          stockAuditSale: 0,
          sampleCollectionConsumptionItemsReceivedPurchase: 0,
          sampleCollectionConsumptionItemsReceivedSale: 0,
          stockWastageReceivedPurchase: 0,
          stockWastageReceivedSale: 0,
          stockReturnReceivedPurchase: 0,
          stockReturnReceivedSale: 0,
          saleStockPurchase: 0,
          saleStockSale: 0,
          purchaseReturnPurchase: 0,
          purchaseReturnSale: 0,
          stockExpiredAndDamagedPurchase: 0,
          stockExpiredAndDamagedSale: 0,
          saleDemandIssuedStockPurchase: 0,
          saleDemandIssuedStockSale: 0,
          procedureMedicinesPurchase: 0,
          procedureMedicinesSale: 0,
          procedureFeePurchase: 0,
          procedureFeeSale: 0,
          ordersIssuedPurchase: 0,
          ordersIssuedSale: 0,
          assetAllocationPurchase: 0,
          assetAllocationSale: 0,
          customerChallanFormsIssuedPurchase: 0,
          customerChallanFormsIssuedSale: 0,
          stockAuditOutPurchase: 0,
          stockAuditOutSale: 0,
          sampleCollectionConsumptionItemsIssuedPurchase: 0,
          sampleCollectionConsumptionItemsIssuedSale: 0,
          stockWastagePurchase: 0,
          stockWastageSale: 0,
          stockReturnPurchase: 0,
          stockReturnSale: 0,
          closingStockPurchase: 0,
          closingStockSale: 0
        }
      });
    } finally {
      setLoading(false);
    }
  };

  const generatePDF = async () => {
    if (!report) return;

    const doc = new jsPDF();
    const pageWidth = doc.internal.pageSize.width;
    
    // Add logo on left
    try {
      const logoImg = new Image();
      logoImg.src = '/logo.jpg';
      await new Promise((resolve) => {
        logoImg.onload = () => {
          doc.addImage(logoImg, 'JPEG', 15, 10, 20, 20);
          resolve();
        };
        logoImg.onerror = () => resolve(); // Continue even if logo fails
      });
    } catch (err) {
      console.error('Logo load error:', err);
    }

    // Add Punjab govt logo on right (placeholder circle)
    doc.setDrawColor(0);
    doc.circle(pageWidth - 25, 20, 10);
    
    // Header
    doc.setFontSize(16);
    doc.setFont('helvetica', 'bold');
    doc.text('Rawalpindi Institute of Cardiology', pageWidth / 2, 18, { align: 'center' });
    
    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    doc.text('Rawal Road Rawalpindi, Punjab, Pakistan', pageWidth / 2, 23, { align: 'center' });
    doc.text('Email: info@ric.gov.pk, Phone: 051928111-9', pageWidth / 2, 27, { align: 'center' });
    
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('Stock Balance Report', pageWidth / 2, 35, { align: 'center' });

    // User and date info
    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    const formatDateTime = (dateStr) => {
      const date = new Date(dateStr);
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      const year = date.getFullYear();
      const hours = String(date.getHours()).padStart(2, '0');
      const minutes = String(date.getMinutes()).padStart(2, '0');
      return `Oct ${day}, ${year} ${hours}:${minutes}`;
    };

    doc.text(`User: ${report.user}`, 14, 42);
    doc.text(`From ${formatDateTime(report.fromDate)} To ${formatDateTime(report.toDate)}`, pageWidth - 14, 42, { align: 'right' });

    // Filters
    doc.setFontSize(9);
    doc.setFont('helvetica', 'bold');
    doc.text(`Filters:  Store Name: ${report.storeName}`, 14, 48);

    // Stock Summary Table
    doc.setFontSize(10);
    doc.setFont('helvetica', 'bold');
    doc.text('Stock Summary', 14, 55);

    const summaryData = [
      // Stock In Items
      ['Opening Stock', report.summary.openingStockPurchase.toFixed(2), report.summary.openingStockSale.toFixed(2)],
      ['Purchase Stock', report.summary.purchaseStockPurchase.toFixed(2), report.summary.purchaseStockSale.toFixed(2)],
      ['Patient Bill Return', report.summary.patientBillReturnPurchase.toFixed(2), report.summary.patientBillReturnSale.toFixed(2)],
      ['Buy Demand Received Stock', report.summary.buyDemandReceivedStockPurchase.toFixed(2), report.summary.buyDemandReceivedStockSale.toFixed(2)],
      ['Procedure Medicines Received Stock', report.summary.procedureMedicinesReceivedStockPurchase.toFixed(2), report.summary.procedureMedicinesReceivedStockSale.toFixed(2)],
      ['Procedure Fee Received', report.summary.procedureFeeReceivedPurchase.toFixed(2), report.summary.procedureFeeReceivedSale.toFixed(2)],
      ['Orders Received', report.summary.ordersReceivedPurchase.toFixed(2), report.summary.ordersReceivedSale.toFixed(2)],
      ['Asset Allocation Received Stock', report.summary.assetAllocationReceivedStockPurchase.toFixed(2), report.summary.assetAllocationReceivedStockSale.toFixed(2)],
      ['Customer Challan Forms Received', report.summary.customerChallanFormsReceivedPurchase.toFixed(2), report.summary.customerChallanFormsReceivedSale.toFixed(2)],
      ['Stock Audit', report.summary.stockAuditPurchase.toFixed(2), report.summary.stockAuditSale.toFixed(2)],
      ['Sample Collection Consumption Items Received', report.summary.sampleCollectionConsumptionItemsReceivedPurchase.toFixed(2), report.summary.sampleCollectionConsumptionItemsReceivedSale.toFixed(2)],
      ['Stock Wastage Received', report.summary.stockWastageReceivedPurchase.toFixed(2), report.summary.stockWastageReceivedSale.toFixed(2)],
      ['Stock Return Received', report.summary.stockReturnReceivedPurchase.toFixed(2), report.summary.stockReturnReceivedSale.toFixed(2)],
      ['', { content: 'Stock In Total', colSpan: 1, styles: { fontStyle: 'bold' } }, 
       (report.summary.openingStockPurchase + report.summary.purchaseStockPurchase).toFixed(2),
       (report.summary.openingStockSale + report.summary.purchaseStockSale).toFixed(2)],
      
      // Empty row
      ['', '', ''],
      
      // Stock Out Items
      ['Sale Stock', report.summary.saleStockPurchase.toFixed(2), report.summary.saleStockSale.toFixed(2)],
      ['Purchase Return', report.summary.purchaseReturnPurchase.toFixed(2), report.summary.purchaseReturnSale.toFixed(2)],
      ['Stock Expired And Damaged', report.summary.stockExpiredAndDamagedPurchase.toFixed(2), report.summary.stockExpiredAndDamagedSale.toFixed(2)],
      ['Sale Demand Issued Stock', report.summary.saleDemandIssuedStockPurchase.toFixed(2), report.summary.saleDemandIssuedStockSale.toFixed(2)],
      ['Procedure Medicines', report.summary.procedureMedicinesPurchase.toFixed(2), report.summary.procedureMedicinesSale.toFixed(2)],
      ['Procedure Fee', report.summary.procedureFeePurchase.toFixed(2), report.summary.procedureFeeSale.toFixed(2)],
      ['Orders Issued', report.summary.ordersIssuedPurchase.toFixed(2), report.summary.ordersIssuedSale.toFixed(2)],
      ['Asset Allocation', report.summary.assetAllocationPurchase.toFixed(2), report.summary.assetAllocationSale.toFixed(2)],
      ['Customer Challan Forms Issued', report.summary.customerChallanFormsIssuedPurchase.toFixed(2), report.summary.customerChallanFormsIssuedSale.toFixed(2)],
      ['Stock Audit', report.summary.stockAuditOutPurchase.toFixed(2), report.summary.stockAuditOutSale.toFixed(2)],
      ['Sample Collection Consumption Items Issued', report.summary.sampleCollectionConsumptionItemsIssuedPurchase.toFixed(2), report.summary.sampleCollectionConsumptionItemsIssuedSale.toFixed(2)],
      ['Stock Wastage', report.summary.stockWastagePurchase.toFixed(2), report.summary.stockWastageSale.toFixed(2)],
      ['Stock Return', report.summary.stockReturnPurchase.toFixed(2), report.summary.stockReturnSale.toFixed(2)],
      ['Closing Stock', report.summary.closingStockPurchase.toFixed(2), report.summary.closingStockSale.toFixed(2)],
      ['', { content: 'Stock Out Total', colSpan: 1, styles: { fontStyle: 'bold' } },
       (report.summary.saleStockPurchase + report.summary.closingStockPurchase).toFixed(2),
       (report.summary.saleStockSale + report.summary.closingStockSale).toFixed(2)]
    ];

    autoTable(doc, {
      startY: 60,
      head: [['', 'Purchase', 'Sale']],
      body: summaryData,
      theme: 'grid',
      styles: { 
        fontSize: 8, 
        cellPadding: 2,
        lineColor: [0, 0, 0],
        lineWidth: 0.5
      },
      headStyles: {
        fillColor: [255, 255, 255],
        textColor: [0, 0, 0],
        fontStyle: 'bold',
        halign: 'center',
        lineColor: [0, 0, 0],
        lineWidth: 0.5
      },
      columnStyles: {
        0: { cellWidth: 110, halign: 'left' },
        1: { cellWidth: 35, halign: 'right' },
        2: { cellWidth: 35, halign: 'right' }
      },
      didParseCell: function(data) {
        // Bold the total rows
        if (data.row.index === 13 || data.row.index === 28) {
          data.cell.styles.fontStyle = 'bold';
        }
      }
    });

    // Footer
    doc.setFontSize(8);
    doc.setFont('helvetica', 'normal');
    const now = new Date();
    const timestamp = `${String(now.getDate()).padStart(2, '0')}-${String(now.getMonth() + 1).padStart(2, '0')}-${now.getFullYear()} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
    doc.text(timestamp, 14, doc.internal.pageSize.height - 10);
    doc.text('Page 1 of 1', pageWidth - 14, doc.internal.pageSize.height - 10, { align: 'right' });

    // Save PDF
    doc.save(`StockBalanceReport_${timestamp.replace(/[\s:-]/g, '_')}.pdf`);
  };

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-2">
          <h1 className="text-2xl font-semibold">Stock Balance Report</h1>
        </div>
        <button
          onClick={generatePDF}
          disabled={!report}
          className="flex items-center gap-2 bg-white border px-4 py-2 rounded hover:bg-gray-50 disabled:opacity-50"
        >
          <span>⬇</span>
          <span>Export</span>
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-4 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium mb-1">Date Range</label>
            <div className="flex gap-2 items-center">
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="flex-1 border rounded px-3 py-2 text-sm"
              />
              <span>-</span>
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className="flex-1 border rounded px-3 py-2 text-sm"
              />
            </div>
          </div>

          {/* Branch - locked to the logged-in user's own branch */}
          <BranchField />

          <div>
            <label className="block text-sm font-medium mb-1">Store</label>
            <select
              value={selectedStore}
              onChange={(e) => setSelectedStore(e.target.value)}
              className="w-full border rounded px-3 py-2 text-sm"
            >
              <option value="">Select Store</option>
              {stores.map(store => (
                <option key={store.storeId} value={store.storeName}>
                  {store.storeName}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="flex justify-start">
          <button
            onClick={fetchReport}
            disabled={loading}
            className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700 disabled:bg-gray-400"
          >
            {loading ? 'Loading...' : 'Generate Report'}
          </button>
        </div>
      </div>

      {/* Report Display */}
      {report && (
        <div className="bg-white rounded-lg shadow p-6">
          <div className="mb-4">
            <h2 className="text-lg font-semibold mb-2">Stock Summary</h2>
            <div className="overflow-x-auto">
              <table className="w-full border-collapse border border-gray-300">
                <thead>
                  <tr className="bg-gray-100">
                    <th className="border border-gray-300 px-4 py-2 text-left"></th>
                    <th className="border border-gray-300 px-4 py-2 text-center">Purchase</th>
                    <th className="border border-gray-300 px-4 py-2 text-center">Sale</th>
                  </tr>
                </thead>
                <tbody className="text-sm">
                  {/* Stock In */}
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Opening Stock</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.openingStockPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.openingStockSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Purchase Stock</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.purchaseStockPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.purchaseStockSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Patient Bill Return</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.patientBillReturnPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.patientBillReturnSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Buy Demand Received Stock</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.buyDemandReceivedStockPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.buyDemandReceivedStockSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Procedure Medicines Received Stock</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.procedureMedicinesReceivedStockPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.procedureMedicinesReceivedStockSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Procedure Fee Received</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.procedureFeeReceivedPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.procedureFeeReceivedSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Orders Received</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.ordersReceivedPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.ordersReceivedSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Asset Allocation Received Stock</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.assetAllocationReceivedStockPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.assetAllocationReceivedStockSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Customer Challan Forms Received</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.customerChallanFormsReceivedPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.customerChallanFormsReceivedSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Stock Audit</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.stockAuditPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.stockAuditSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Sample Collection Consumption Items Received</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.sampleCollectionConsumptionItemsReceivedPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.sampleCollectionConsumptionItemsReceivedSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Stock Wastage Received</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.stockWastageReceivedPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.stockWastageReceivedSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Stock Return Received</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.stockReturnReceivedPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.stockReturnReceivedSale.toFixed(2)}</td>
                  </tr>
                  <tr className="bg-gray-100 font-semibold">
                    <td className="border border-gray-300 px-4 py-2">Stock In Total</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">
                      {(report.summary.openingStockPurchase + report.summary.purchaseStockPurchase).toFixed(2)}
                    </td>
                    <td className="border border-gray-300 px-4 py-2 text-right">
                      {(report.summary.openingStockSale + report.summary.purchaseStockSale).toFixed(2)}
                    </td>
                  </tr>
                  
                  {/* Stock Out */}
                  <tr>
                    <td className="border border-gray-300 px-4 py-2 h-4"></td>
                    <td className="border border-gray-300 px-4 py-2"></td>
                    <td className="border border-gray-300 px-4 py-2"></td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Sale Stock</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.saleStockPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.saleStockSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Purchase Return</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.purchaseReturnPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.purchaseReturnSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Stock Expired And Damaged</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.stockExpiredAndDamagedPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.stockExpiredAndDamagedSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Sale Demand Issued Stock</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.saleDemandIssuedStockPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.saleDemandIssuedStockSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Procedure Medicines</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.procedureMedicinesPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.procedureMedicinesSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Procedure Fee</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.procedureFeePurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.procedureFeeSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Orders Issued</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.ordersIssuedPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.ordersIssuedSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Asset Allocation</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.assetAllocationPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.assetAllocationSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Customer Challan Forms Issued</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.customerChallanFormsIssuedPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.customerChallanFormsIssuedSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Stock Audit</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.stockAuditOutPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.stockAuditOutSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Sample Collection Consumption Items Issued</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.sampleCollectionConsumptionItemsIssuedPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.sampleCollectionConsumptionItemsIssuedSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Stock Wastage</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.stockWastagePurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.stockWastageSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Stock Return</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.stockReturnPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.stockReturnSale.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td className="border border-gray-300 px-4 py-2">Closing Stock</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.closingStockPurchase.toFixed(2)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{report.summary.closingStockSale.toFixed(2)}</td>
                  </tr>
                  <tr className="bg-gray-100 font-semibold">
                    <td className="border border-gray-300 px-4 py-2">Stock Out Total</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">
                      {(report.summary.saleStockPurchase + report.summary.closingStockPurchase).toFixed(2)}
                    </td>
                    <td className="border border-gray-300 px-4 py-2 text-right">
                      {(report.summary.saleStockSale + report.summary.closingStockSale).toFixed(2)}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default StockBalanceReportPage;
