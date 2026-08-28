import React,{ useState, useEffect } from 'react';
import { QuestionMarkCircleIcon, ArrowDownTrayIcon, Squares2X2Icon, PencilSquareIcon, PrinterIcon, ShoppingCartIcon, XMarkIcon } from '@heroicons/react/24/outline';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import stockApi from '../services/stockApi';
import inventoryApi from '../services/inventoryApi';
import purchaseOrderApi from '../services/purchaseOrderApi';
import { itemTypeApi, vendorApi } from '../services/api';
import BranchField from '../components/BranchField';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';
import { useSession } from '../context/SessionContext';

const StockPage = () => {
  const { session } = useSession();

  // Filter states
  const [filters, setFilters] = useState({
    branchId: null,
    storeId: null,
    itemTypeId: null,
    itemId: null,
    categoryIds: '',
    stockTypeId: null,
    generalType: null,
    medicineTypeId: null,
    stockAvailability: 'All',
    isVaccine: null,
    minimumPanicLevelOnly: false
  });

  // The filters actually sent to the server - only updated when "Generate" is
  // clicked, so editing a dropdown mid-form doesn't re-trigger a search.
  const [submittedFilters, setSubmittedFilters] = useState(null);

  // Lookup data
  const [stores, setStores] = useState([]);
  const [itemTypes, setItemTypes] = useState([]);
  const [items, setItems] = useState([]);
  const [categories, setCategories] = useState([]);
  const [stockTypes, setStockTypes] = useState([]);
  const [vendors, setVendors] = useState([]);
  const [itemQuantities, setItemQuantities] = useState({});

  const {
    items: stocks,
    totalCount,
    currentPage,
    pageSize: entriesPerPage,
    setPageSize: setEntriesPerPage,
    goToPage,
    search: runSearch,
    loading,
    error,
    reload: reloadStocks,
  } = usePagedList(stockApi.searchStocks, submittedFilters || {}, { autoLoad: false, initialPageSize: 10 });

  // Selected categories for multi-select
  const [selectedCategories, setSelectedCategories] = useState([]);

  // Row action modals - mirrors the old Stock (MPL) screen's Detail / Update /
  // Print / Add to Purchase Order row actions.
  const [detailStock, setDetailStock] = useState(null);
  const [updateStock, setUpdateStock] = useState(null);
  const [updateMpl, setUpdateMpl] = useState('');
  const [updateSubmitting, setUpdateSubmitting] = useState(false);
  const [updateError, setUpdateError] = useState(null);
  const [poStock, setPoStock] = useState(null);
  const [poForm, setPoForm] = useState({ vendorId: '', quantity: 1, unitPrice: 0 });
  const [poSubmitting, setPoSubmitting] = useState(false);
  const [poError, setPoError] = useState(null);

  useEffect(() => {
    loadLookupData();
  }, []);

  // Stock is always scoped to the logged-in user's own branch.
  useEffect(() => {
    if (session?.branchId) {
      setFilters((prev) => ({ ...prev, branchId: session.branchId }));
    }
  }, [session?.branchId]);

  // Item dropdown narrows to what's actually on hand at the selected store,
  // with the live quantity shown inline (e.g. "Syringe 10ml - 8") - this is a
  // filter picker, not the results themselves, so "Out of Stock" browsing
  // still works via the Stock Availability radio with no item selected.
  useEffect(() => {
    if (!filters.storeId) {
      setItemQuantities({});
      return;
    }

    let cancelled = false;
    stockApi.getQuantitiesByStore(filters.storeId)
      .then((data) => {
        if (!cancelled) setItemQuantities(data || {});
      })
      .catch((err) => {
        console.error('Error loading item quantities for store:', err);
        if (!cancelled) setItemQuantities({});
      });

    return () => { cancelled = true; };
  }, [filters.storeId]);

  const loadLookupData = async () => {
    try {
      const [data, types, vendorList] = await Promise.all([
        inventoryApi.getLookupData(),
        itemTypeApi.getAll(),
        vendorApi.getAll()
      ]);
      setStores(data.stores || []);
      setItems(data.items || []);
      setStockTypes(data.stockTypes || []);
      setCategories(data.categories || []);
      setItemTypes((types || []).filter((t) => t.isActive !== false));
      setVendors(vendorList || []);
    } catch (err) {
      console.error('Error loading lookup data:', err);
    }
  };

  const handleSearch = () => {
    const searchFilters = {
      ...filters,
      branchId: filters.branchId ? Number(filters.branchId) : null,
      storeId: filters.storeId ? Number(filters.storeId) : null,
      itemTypeId: filters.itemTypeId ? Number(filters.itemTypeId) : null,
      itemId: filters.itemId ? Number(filters.itemId) : null,
      stockTypeId: filters.stockTypeId ? Number(filters.stockTypeId) : null,
      categoryIds: selectedCategories.join(',')
    };
    setSubmittedFilters(searchFilters);
    runSearch(searchFilters);
  };

  const handleFilterChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFilters(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value === '' ? null : value
    }));
  };

  const handleCategoryToggle = (categoryId) => {
    setSelectedCategories(prev => {
      if (prev.includes(categoryId)) {
        return prev.filter(id => id !== categoryId);
      } else {
        return [...prev, categoryId];
      }
    });
  };

  const selectedStoreName = () => {
    if (!filters.storeId) return 'All';
    const match = stores.find((s) => String(s.storeId ?? s.id) === String(filters.storeId));
    return match ? (match.storeName ?? match.name) : 'All';
  };

  const selectedItemTypeName = () => {
    if (!filters.itemTypeId) return 'All';
    const match = itemTypes.find((t) => String(t.id) === String(filters.itemTypeId));
    return match ? match.name : 'All';
  };

  // Generates the "Stock Report" PDF - same layout as the old system's Stock
  // (MPL) Export: RIC letterhead, "Stock Report (Store - Item Type)" title,
  // Sr/Name/Stock Type/Total Items/Min Panic Level/Modified On table, and a
  // date + "Page X of Y" footer. Used both by the header Export button (full
  // filtered list) and by each row's Print button (single row).
  const generateStockReportPdf = async (rows, fileSuffix) => {
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

    doc.setFontSize(15);
    doc.setFont('helvetica', 'bold');
    doc.text('Rawalpindi Institute of Cardiology', pageWidth / 2, 16, { align: 'center' });

    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    doc.text('Rawal Road', pageWidth / 2, 22, { align: 'center' });
    doc.text('Email: info@ric.gov.pk, Ph: 051928111-9', pageWidth / 2, 27, { align: 'center' });

    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text(`Stock Report (${selectedStoreName()} - ${selectedItemTypeName()})`, pageWidth / 2, 36, { align: 'center' });

    const body = rows.map((stock, index) => [
      index + 1,
      stock.itemName,
      stock.stockType || '-',
      (stock.totalItems ?? 0).toLocaleString('en-US'),
      stock.minimumPanicLevel ?? 0,
      stock.modifiedOn ? new Date(stock.modifiedOn).toLocaleString('en-US', { month: 'short', day: '2-digit', year: 'numeric', hour: 'numeric', minute: '2-digit' }) : '-'
    ]);

    autoTable(doc, {
      startY: 42,
      head: [['Sr.', 'Name', 'Stock Type', 'Total Items', 'Min Panic Level', 'Modified On']],
      body,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 2, lineColor: [0, 0, 0], lineWidth: 0.1 },
      headStyles: { fillColor: [255, 255, 255], textColor: [0, 0, 0], fontStyle: 'bold', halign: 'center' },
      columnStyles: {
        0: { cellWidth: 10, halign: 'center' },
        3: { halign: 'right', textColor: [153, 51, 0] },
        4: { halign: 'right' }
      },
      didParseCell: (data) => {
        if (data.column.index === 1 && data.section === 'body') {
          data.cell.styles.textColor = [37, 71, 160];
        }
      },
      didDrawPage: () => {
        const now = new Date();
        const dateStr = now.toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' });
        const timeStr = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
        doc.setFontSize(8);
        doc.setFont('helvetica', 'normal');
        doc.text(`${dateStr}   ${timeStr}`, 14, doc.internal.pageSize.height - 10);
      }
    });

    // autoTable doesn't know the final page count while drawing each page, so
    // the "Page X of Y" part is filled in afterwards across every page that was drawn.
    const pageCount = doc.internal.getNumberOfPages();
    for (let i = 1; i <= pageCount; i++) {
      doc.setPage(i);
      doc.setFontSize(8);
      doc.text(`Page ${i} of ${pageCount}`, pageWidth - 14, doc.internal.pageSize.height - 10, { align: 'right' });
    }

    doc.save(`StockReport_${fileSuffix}.pdf`);
  };

  // Exports only the currently-loaded page, not the whole filtered result set -
  // results are now paged server-side, so "export everything" would need a
  // separate non-paginated export endpoint rather than reusing this data.
  const handleExport = () => {
    if (stocks.length === 0) return;
    generateStockReportPdf(stocks, new Date().toISOString().slice(0, 19).replace(/[:T]/g, '_'));
  };

  const handlePrintRow = (stock) => {
    generateStockReportPdf([stock], (stock.itemName || 'item').replace(/[^a-z0-9]+/gi, '_'));
  };

  const openUpdateModal = (stock) => {
    setUpdateStock(stock);
    setUpdateMpl(String(stock.minimumPanicLevel ?? 0));
    setUpdateError(null);
  };

  const closeUpdateModal = () => {
    setUpdateStock(null);
    setUpdateError(null);
  };

  const submitUpdate = async (e) => {
    e.preventDefault();
    if (!updateStock) return;
    setUpdateSubmitting(true);
    setUpdateError(null);
    try {
      await stockApi.updateMinimumPanicLevel(updateStock.id, Number(updateMpl) || 0);
      reloadStocks();
      closeUpdateModal();
    } catch (err) {
      console.error('Error updating minimum panic level:', err);
      setUpdateError('Failed to update Minimum Panic Level. Please try again.');
    } finally {
      setUpdateSubmitting(false);
    }
  };

  const inferItemType = (stock) => {
    const name = (stock.itemTypeName || '').toLowerCase();
    if (name.includes('medicine')) return 'Medicine';
    if (name.includes('disposable')) return 'Disposable';
    return 'Item';
  };

  const openAddToPoModal = (stock) => {
    setPoStock(stock);
    const suggestedQuantity = Math.max((stock.minimumPanicLevel ?? 0) - (stock.totalItems ?? 0), 1);
    setPoForm({ vendorId: '', quantity: suggestedQuantity, unitPrice: 0 });
    setPoError(null);
  };

  const closeAddToPoModal = () => {
    setPoStock(null);
    setPoError(null);
  };

  const submitAddToPo = async (e) => {
    e.preventDefault();
    if (!poStock) return;

    if (!poForm.vendorId) {
      setPoError('Please select a vendor.');
      return;
    }
    if (!poForm.quantity || Number(poForm.quantity) <= 0) {
      setPoError('Quantity must be greater than 0.');
      return;
    }
    if (!poForm.unitPrice || Number(poForm.unitPrice) <= 0) {
      setPoError('Unit price must be greater than 0.');
      return;
    }

    setPoSubmitting(true);
    setPoError(null);
    try {
      await purchaseOrderApi.create({
        storeId: Number(poStock.storeId),
        vendorId: Number(poForm.vendorId),
        items: [
          {
            itemId: poStock.itemId,
            itemType: inferItemType(poStock),
            packetQuantity: null,
            unitQuantity: Number(poForm.quantity),
            packetPrice: null,
            unitPrice: Number(poForm.unitPrice)
          }
        ]
      });
      closeAddToPoModal();
    } catch (err) {
      console.error('Error creating purchase order from stock row:', err);
      setPoError(err.response?.data?.message || 'Failed to add this item to a purchase order.');
    } finally {
      setPoSubmitting(false);
    }
  };

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <QuestionMarkCircleIcon className="h-6 w-6 text-blue-600" />
          <h1 className="text-2xl font-semibold text-gray-800">Stock (MPL)</h1>
        </div>
        <button
          onClick={handleExport}
          disabled={stocks.length === 0}
          className="flex items-center gap-2 px-4 py-2 border border-gray-300 rounded-md text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <ArrowDownTrayIcon className="h-4 w-4" />
          Export
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white p-6 rounded-lg shadow space-y-4">
        <div className="grid grid-cols-4 gap-4">
          {/* Branch - locked to the logged-in user's own branch */}
          <BranchField />

          {/* Store */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Store
            </label>
            <select
              name="storeId"
              value={filters.storeId || ''}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Store</option>
              {stores.map((store, index) => {
                const storeId = store.storeId ?? store.id ?? '';
                const storeName = store.storeName ?? store.name ?? `Store ${index + 1}`;

                return (
                <option key={`store-${storeId || index}`} value={storeId}>
                  {storeName}
                </option>
                );
              })}
            </select>
          </div>

          {/* Item Type - active item types only, from Inv.ItemTypes */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Item Type
            </label>
            <select
              name="itemTypeId"
              value={filters.itemTypeId || ''}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All</option>
              {itemTypes.map((type) => (
                <option key={type.id} value={type.id}>{type.name}</option>
              ))}
            </select>
          </div>

          {/* Item */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Item
            </label>
            <select
              name="itemId"
              value={filters.itemId || ''}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Item</option>
              {items
                .filter((item) => {
                  if (!filters.storeId) return true;
                  const itemId = item.id ?? item.itemId;
                  if (itemId == null) return true;
                  return (itemQuantities[itemId] ?? 0) > 0;
                })
                .map((item, index) => {
                  const itemId = item.id ?? item.itemId ?? '';
                  const itemName = item.name ?? item.itemName ?? `Item ${index + 1}`;
                  const qty = filters.storeId && itemId !== '' ? itemQuantities[itemId] ?? 0 : null;

                  return (
                  <option key={`item-${itemId || index}`} value={itemId}>
                    {qty !== null ? `${itemName} - ${qty}` : itemName}
                  </option>
                  );
                })}
            </select>
          </div>

          {/* Category */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Category
            </label>
            <select
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              value={selectedCategories[0] || ''}
              onChange={(e) => {
                setSelectedCategories(e.target.value ? [e.target.value] : []);
              }}
            >
              <option value="">All Categories</option>
              {categories.map((category, index) => {
                const categoryId = category.id ?? category.categoryId ?? '';
                const categoryName = category.name ?? category.categoryName ?? `Category ${index + 1}`;
                return (
                  <option key={`category-${categoryId || index}`} value={categoryId}>
                    {categoryName}
                  </option>
                );
              })}
            </select>
          </div>

          {/* Stock Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Stock Type
            </label>
            <select
              name="stockTypeId"
              value={filters.stockTypeId || ''}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Stock Type</option>
              {stockTypes.map((stockType, index) => {
                const stockTypeId = stockType.id ?? stockType.stockTypeId ?? '';
                const stockTypeName = stockType.name ?? stockType.stockTypeName ?? `Stock Type ${index + 1}`;

                return (
                <option key={`stock-type-${stockTypeId || index}`} value={stockTypeId}>
                  {stockTypeName}
                </option>
                );
              })}
            </select>
          </div>

          {/* General Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              General Type
            </label>
            <div className="flex items-center space-x-4 pt-2">
              <label className="flex items-center">
                <input
                  type="radio"
                  name="generalType"
                  value=""
                  checked={!filters.generalType}
                  onChange={handleFilterChange}
                  className="mr-2"
                />
                All
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="generalType"
                  value="Expensive"
                  checked={filters.generalType === 'Expensive'}
                  onChange={handleFilterChange}
                  className="mr-2"
                />
                Expensive Item
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="generalType"
                  value="Fridge"
                  checked={filters.generalType === 'Fridge'}
                  onChange={handleFilterChange}
                  className="mr-2"
                />
                Fridge Item
              </label>
            </div>
          </div>

          {/* Medicine Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Medicine Type
            </label>
            <select
              name="medicineTypeId"
              value={filters.medicineTypeId || ''}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select Medicine Type</option>
              <option value="1">Type 1</option>
              <option value="2">Type 2</option>
            </select>
          </div>
        </div>

        <div className="grid grid-cols-4 gap-4 items-end">
          {/* Stock Availability */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Stock Availability
            </label>
            <div className="flex items-center space-x-4 pt-2">
              <label className="flex items-center">
                <input
                  type="radio"
                  name="stockAvailability"
                  value="All"
                  checked={filters.stockAvailability === 'All'}
                  onChange={handleFilterChange}
                  className="mr-2"
                />
                All
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="stockAvailability"
                  value="InStock"
                  checked={filters.stockAvailability === 'InStock'}
                  onChange={handleFilterChange}
                  className="mr-2"
                />
                In Stock
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="stockAvailability"
                  value="OutOfStock"
                  checked={filters.stockAvailability === 'OutOfStock'}
                  onChange={handleFilterChange}
                  className="mr-2"
                />
                Out Of Stock
              </label>
            </div>
          </div>

          {/* Vaccine Checkbox */}
          <div className="flex items-center">
            <input
              type="checkbox"
              id="isVaccine"
              name="isVaccine"
              checked={filters.isVaccine || false}
              onChange={(e) => setFilters(prev => ({...prev, isVaccine: e.target.checked ? true : null}))}
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
            />
            <label htmlFor="isVaccine" className="ml-2 text-sm text-gray-700">
              Vaccine
            </label>
          </div>

          {/* Minimum Panic Level Checkbox */}
          <div className="flex items-center">
            <input
              type="checkbox"
              id="minimumPanicLevelOnly"
              name="minimumPanicLevelOnly"
              checked={filters.minimumPanicLevelOnly}
              onChange={handleFilterChange}
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
            />
            <label htmlFor="minimumPanicLevelOnly" className="ml-2 text-sm text-gray-700">
              Minimum Panic Level Reached Only?
            </label>
          </div>

          {/* Generate Button */}
          <div>
            <button
              onClick={handleSearch}
              disabled={loading}
              className="px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Loading...' : 'Generate'}
            </button>
          </div>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          Failed to search stocks{error.message ? `: ${error.message}` : ''}
        </div>
      )}

      {/* Results Table */}
      <div className="bg-white rounded-lg shadow">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Stock Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Location(Rack.Row.Column.Drawer)
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Total Items(Transition)
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  MPL
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Modified On
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {stocks.length === 0 ? (
                <tr>
                  <td colSpan="7" className="px-6 py-4 text-center text-sm text-gray-500">
                    {loading ? 'Loading...' : 'No entries found'}
                  </td>
                </tr>
              ) : (
                stocks.map((stock) => (
                  <tr key={stock.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {stock.itemName}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {stock.stockType || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {stock.location || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {stock.totalItems || 0}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {stock.minimumPanicLevel || 0}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {stock.modifiedOn ? new Date(stock.modifiedOn).toLocaleString() : '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <div className="flex items-center gap-2">
                        <button onClick={() => setDetailStock(stock)} className="text-blue-600 hover:text-blue-800" title="Detail">
                          <Squares2X2Icon className="h-5 w-5" />
                        </button>
                        <button onClick={() => openUpdateModal(stock)} className="text-indigo-600 hover:text-indigo-800" title="Update">
                          <PencilSquareIcon className="h-5 w-5" />
                        </button>
                        <button onClick={() => handlePrintRow(stock)} className="text-green-600 hover:text-green-800" title="Print">
                          <PrinterIcon className="h-5 w-5" />
                        </button>
                        <button onClick={() => openAddToPoModal(stock)} className="text-orange-600 hover:text-orange-800" title="Add to purchase order">
                          <ShoppingCartIcon className="h-5 w-5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <Pagination
          currentPage={currentPage}
          pageSize={entriesPerPage}
          totalCount={totalCount}
          onPageChange={goToPage}
          onPageSizeChange={setEntriesPerPage}
        />
      </div>

      {/* Detail modal */}
      {detailStock && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40 p-4">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-lg">
            <div className="flex items-center justify-between border-b px-6 py-4">
              <h2 className="text-lg font-semibold text-gray-900">Stock Detail</h2>
              <button onClick={() => setDetailStock(null)} className="text-gray-400 hover:text-gray-600">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>
            <div className="px-6 py-4 grid grid-cols-2 gap-4 text-sm">
              <div><div className="text-gray-500">Item Name</div><div className="font-medium text-gray-900">{detailStock.itemName}</div></div>
              <div><div className="text-gray-500">Stock Type</div><div className="font-medium text-gray-900">{detailStock.stockType || '-'}</div></div>
              <div><div className="text-gray-500">Item Type</div><div className="font-medium text-gray-900">{detailStock.itemTypeName || '-'}</div></div>
              <div><div className="text-gray-500">Category</div><div className="font-medium text-gray-900">{detailStock.categoryName || '-'}</div></div>
              <div><div className="text-gray-500">Location</div><div className="font-medium text-gray-900">{detailStock.location || '-'}</div></div>
              <div><div className="text-gray-500">Total Items</div><div className="font-medium text-gray-900">{detailStock.totalItems ?? 0}</div></div>
              <div><div className="text-gray-500">Minimum Panic Level</div><div className="font-medium text-gray-900">{detailStock.minimumPanicLevel ?? 0}</div></div>
              <div><div className="text-gray-500">Fridge Item</div><div className="font-medium text-gray-900">{detailStock.isFridgeItem ? 'Yes' : 'No'}</div></div>
              <div><div className="text-gray-500">Consumption Item</div><div className="font-medium text-gray-900">{detailStock.isConsumptionItem ? 'Yes' : 'No'}</div></div>
              <div><div className="text-gray-500">Modified On</div><div className="font-medium text-gray-900">{detailStock.modifiedOn ? new Date(detailStock.modifiedOn).toLocaleString() : '-'}</div></div>
            </div>
            <div className="flex justify-end border-t px-6 py-4">
              <button onClick={() => setDetailStock(null)} className="px-4 py-2 border border-gray-300 rounded-md text-sm hover:bg-gray-50">Close</button>
            </div>
          </div>
        </div>
      )}

      {/* Update modal - the only field on this screen that's actually editable
          is the Minimum Panic Level threshold; quantity/location/etc. are all
          derived from other transactions. */}
      {updateStock && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40 p-4">
          <form onSubmit={submitUpdate} className="bg-white rounded-lg shadow-xl w-full max-w-md">
            <div className="flex items-center justify-between border-b px-6 py-4">
              <h2 className="text-lg font-semibold text-gray-900">Update Stock</h2>
              <button type="button" onClick={closeUpdateModal} className="text-gray-400 hover:text-gray-600">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>
            <div className="px-6 py-4 space-y-4">
              {updateError && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-3 py-2 rounded text-sm">{updateError}</div>
              )}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Item</label>
                <input type="text" value={updateStock.itemName} disabled className="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-100 text-sm" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Minimum Panic Level<span className="text-red-500">*</span></label>
                <input
                  type="number"
                  min="0"
                  value={updateMpl}
                  onChange={(e) => setUpdateMpl(e.target.value)}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm"
                />
              </div>
            </div>
            <div className="flex justify-end gap-2 border-t px-6 py-4">
              <button type="button" onClick={closeUpdateModal} className="px-4 py-2 border border-gray-300 rounded-md text-sm hover:bg-gray-50">Cancel</button>
              <button type="submit" disabled={updateSubmitting} className="px-4 py-2 bg-indigo-600 text-white rounded-md text-sm hover:bg-indigo-700 disabled:opacity-50">
                {updateSubmitting ? 'Saving...' : 'Save'}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Add to purchase order modal */}
      {poStock && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40 p-4">
          <form onSubmit={submitAddToPo} className="bg-white rounded-lg shadow-xl w-full max-w-md">
            <div className="flex items-center justify-between border-b px-6 py-4">
              <h2 className="text-lg font-semibold text-gray-900">Add to Purchase Order</h2>
              <button type="button" onClick={closeAddToPoModal} className="text-gray-400 hover:text-gray-600">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>
            <div className="px-6 py-4 space-y-4">
              {poError && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-3 py-2 rounded text-sm">{poError}</div>
              )}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Item</label>
                <input type="text" value={poStock.itemName} disabled className="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-100 text-sm" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Vendor<span className="text-red-500">*</span></label>
                <select
                  value={poForm.vendorId}
                  onChange={(e) => setPoForm((prev) => ({ ...prev, vendorId: e.target.value }))}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm"
                >
                  <option value="">Select Vendor</option>
                  {vendors.map((vendor) => (
                    <option key={vendor.id} value={vendor.id}>{vendor.name}</option>
                  ))}
                </select>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Quantity<span className="text-red-500">*</span></label>
                  <input
                    type="number"
                    min="1"
                    value={poForm.quantity}
                    onChange={(e) => setPoForm((prev) => ({ ...prev, quantity: e.target.value }))}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm"
                  />
                  <p className="text-xs text-gray-500 mt-1">Suggested from Min Panic Level - Total Items on hand.</p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Unit Price<span className="text-red-500">*</span></label>
                  <input
                    type="number"
                    min="0"
                    step="0.01"
                    value={poForm.unitPrice}
                    onChange={(e) => setPoForm((prev) => ({ ...prev, unitPrice: e.target.value }))}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm"
                  />
                </div>
              </div>
            </div>
            <div className="flex justify-end gap-2 border-t px-6 py-4">
              <button type="button" onClick={closeAddToPoModal} className="px-4 py-2 border border-gray-300 rounded-md text-sm hover:bg-gray-50">Cancel</button>
              <button type="submit" disabled={poSubmitting} className="px-4 py-2 bg-orange-600 text-white rounded-md text-sm hover:bg-orange-700 disabled:opacity-50">
                {poSubmitting ? 'Creating...' : 'Create Purchase Order'}
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};

export default StockPage;
