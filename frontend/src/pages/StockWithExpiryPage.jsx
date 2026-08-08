import React,{ useState, useEffect } from 'react';
import { Squares2X2Icon, PrinterIcon, ShareIcon, XMarkIcon } from '@heroicons/react/24/outline';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { stockWithExpiryApi } from '../services/stockWithExpiryApi';
import { getAllStores } from '../services/storeApi';
import { branchApi } from '../services/branchApi';
import itemApi from '../services/itemApi';
import itemCategoryApi from '../services/itemCategoryApi';
import purchaseOrderApi from '../services/purchaseOrderApi';
import { vendorApi } from '../services/api';
import BranchField from '../components/BranchField';
import Pagination from '../components/Pagination';
import { useSession } from '../context/SessionContext';

function StockWithExpiryPage() {
    const { session } = useSession();
    const [stocks, setStocks] = useState([]);
    const [stores, setStores] = useState([]);
    const [branches, setBranches] = useState([]);
    const [items, setItems] = useState([]);
    const [categories, setCategories] = useState([]);
    const [loading, setLoading] = useState(false);
    
    const [currentPage, setCurrentPage] = useState(1);
    const [itemsPerPage, setItemsPerPage] = useState(10);

    // Row action modals - mirrors the Stock (MPL) page's Detail / Print /
    // Add to Purchase Order row actions.
    const [detailStock, setDetailStock] = useState(null);
    const [vendors, setVendors] = useState([]);
    const [poStock, setPoStock] = useState(null);
    const [poForm, setPoForm] = useState({ vendorId: '', quantity: 1, unitPrice: 0 });
    const [poSubmitting, setPoSubmitting] = useState(false);
    const [poError, setPoError] = useState(null);

    const [filters, setFilters] = useState({
        branchId: null,
        storeId: null,
        itemType: null,
        itemId: null,
        categoryId: null,
        isExpensiveItem: null,
        isFridgeItem: null,
        minimumPanicLevelOnly: false
    });

    useEffect(() => {
        fetchStores();
        fetchBranches();
        fetchItems();
        fetchCategories();
        fetchVendors();
        fetchStocks();
    }, []);

    // Stock with expiry is always scoped to the logged-in user's own branch.
    useEffect(() => {
        if (session?.branchId) {
            setFilters((prev) => ({ ...prev, branchId: session.branchId }));
        }
    }, [session?.branchId]);

    useEffect(() => {
        setCurrentPage(1);
    }, [itemsPerPage]);

    const fetchStores = async () => {
        try {
            const data = await getAllStores();
            setStores(data);
        } catch (error) {
            console.error('Error fetching stores:', error);
        }
    };

    const fetchBranches = async () => {
        try {
            const data = await branchApi.getAll();
            setBranches(data);
        } catch (error) {
            console.error('Error fetching branches:', error);
        }
    };

    const fetchItems = async () => {
        try {
            const data = await itemApi.getAllUnpaginated();
            setItems(data.filter(item => item.isActive));
        } catch (error) {
            console.error('Error fetching items:', error);
        }
    };

    const fetchCategories = async () => {
        try {
            const data = await itemCategoryApi.getAll();
            setCategories(data);
        } catch (error) {
            console.error('Error fetching categories:', error);
        }
    };

    const fetchVendors = async () => {
        try {
            const data = await vendorApi.getAll();
            setVendors(data || []);
        } catch (error) {
            console.error('Error fetching vendors:', error);
        }
    };

    const fetchStocks = async () => {
        setLoading(true);
        try {
            const data = await stockWithExpiryApi.getAll(filters);
            setStocks(data);
        } catch (error) {
            console.error('Error fetching stocks:', error);
            alert('Failed to fetch stock data');
        } finally {
            setLoading(false);
        }
    };

    const handleFilterChange = (key, value) => {
        setFilters(prev => ({ ...prev, [key]: value }));
    };

    const handleItemTypeChange = (type) => {
        setFilters(prev => ({ ...prev, itemType: type === 'All' ? null : type }));
    };

    const handleGeneralTypeChange = (type, checked) => {
        setFilters(prev => ({ ...prev, [type]: checked ? true : null }));
    };

    const handleGenerate = () => {
        setCurrentPage(1);
        fetchStocks();
    };

    const handleDeselectAll = () => {
        setFilters({
            branchId: null,
            storeId: null,
            itemType: null,
            itemId: null,
            categoryId: null,
            isExpensiveItem: null,
            isFridgeItem: null,
            minimumPanicLevelOnly: false
        });
    };

    // Generates the "Stock With Expiry" PDF for a single row - same letterhead
    // layout used for the Stock (MPL) page's row Print action.
    const handlePrintRow = async (stock) => {
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
        doc.text('Stock With Expiry (MPL)', pageWidth / 2, 36, { align: 'center' });

        autoTable(doc, {
            startY: 42,
            head: [['Name', 'Stock Type', 'Location', 'Total Items', 'MPL', 'Least Expiry Date', 'Modified On']],
            body: [[
                stock.itemName,
                stock.stockType || '-',
                stock.location || '-',
                stock.totalItemsInTransition ?? 0,
                stock.mpl ?? 0,
                stock.expiryDate ? new Date(stock.expiryDate).toLocaleDateString() : 'N/A',
                stock.modifiedOn ? new Date(stock.modifiedOn).toLocaleDateString() : 'N/A'
            ]],
            theme: 'grid',
            styles: { fontSize: 8, cellPadding: 2, lineColor: [0, 0, 0], lineWidth: 0.1 },
            headStyles: { fillColor: [255, 255, 255], textColor: [0, 0, 0], fontStyle: 'bold', halign: 'center' },
            didDrawPage: () => {
                const now = new Date();
                const dateStr = now.toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' });
                const timeStr = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
                doc.setFontSize(8);
                doc.setFont('helvetica', 'normal');
                doc.text(`${dateStr}   ${timeStr}`, 14, doc.internal.pageSize.height - 10);
                doc.text('Page 1 of 1', pageWidth - 14, doc.internal.pageSize.height - 10, { align: 'right' });
            }
        });

        doc.save(`StockWithExpiry_${(stock.itemName || 'item').replace(/[^a-z0-9]+/gi, '_')}.pdf`);
    };

    const openAddToPoModal = (stock) => {
        setPoStock(stock);
        const suggestedQuantity = Math.max((stock.mpl ?? 0) - (stock.totalItemsInTransition ?? 0), 1);
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
                        itemType: poStock.itemType || 'Item',
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

    const indexOfLastItem = currentPage * itemsPerPage;
    const indexOfFirstItem = indexOfLastItem - itemsPerPage;
    const currentStocks = stocks.slice(indexOfFirstItem, indexOfLastItem);

    return (
        <div className="container mx-auto px-4 py-8">
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-3xl font-bold text-gray-800 flex items-center gap-2">
                    <span className="text-blue-600">📦</span> Stock With Expiry(MPL)
                </h1>
                <button
                    onClick={() => window.print()}
                    className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 flex items-center gap-2"
                >
                    📄 Export
                </button>
            </div>

            {/* Filters */}
            <div className="bg-white rounded-lg shadow-md p-6 mb-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                    {/* Branch - locked to the logged-in user's own branch */}
                    <BranchField />

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">Store</label>
                        <select
                            value={filters.storeId || ''}
                            onChange={(e) => handleFilterChange('storeId', e.target.value ? parseInt(e.target.value) : null)}
                            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        >
                            <option value="">Select Store</option>
                            {stores.map(store => (
                                <option key={store.storeId} value={store.storeId}>
                                    {store.storeName}
                                </option>
                            ))}
                        </select>
                    </div>
                </div>

                <div className="mb-4">
                    <label className="block text-sm font-medium text-gray-700 mb-2">Item Type</label>
                    <div className="flex gap-4">
                        <label className="flex items-center gap-2">
                            <input
                                type="radio"
                                name="itemType"
                                checked={!filters.itemType}
                                onChange={() => handleItemTypeChange('All')}
                                className="w-4 h-4"
                            />
                            <span>All</span>
                        </label>
                        <label className="flex items-center gap-2">
                            <input
                                type="radio"
                                name="itemType"
                                checked={filters.itemType === 'Medicine'}
                                onChange={() => handleItemTypeChange('Medicine')}
                                className="w-4 h-4"
                            />
                            <span>Medicine</span>
                        </label>
                        <label className="flex items-center gap-2">
                            <input
                                type="radio"
                                name="itemType"
                                checked={filters.itemType === 'Disposable'}
                                onChange={() => handleItemTypeChange('Disposable')}
                                className="w-4 h-4"
                            />
                            <span>Disposable</span>
                        </label>
                        <label className="flex items-center gap-2">
                            <input
                                type="radio"
                                name="itemType"
                                checked={filters.itemType === 'Item'}
                                onChange={() => handleItemTypeChange('Item')}
                                className="w-4 h-4"
                            />
                            <span>Item</span>
                        </label>
                    </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">Item</label>
                        <select
                            value={filters.itemId || ''}
                            onChange={(e) => handleFilterChange('itemId', e.target.value ? parseInt(e.target.value) : null)}
                            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        >
                            <option value="">Select Item</option>
                            {items.map(item => (
                                <option key={item.id} value={item.id}>
                                    {item.name}
                                </option>
                            ))}
                        </select>
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">Category</label>
                        <select
                            value={filters.categoryId || ''}
                            onChange={(e) => handleFilterChange('categoryId', e.target.value ? parseInt(e.target.value) : null)}
                            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        >
                            <option value="">Please Select</option>
                            {categories.map(cat => (
                                <option key={cat.id} value={cat.id}>
                                    {cat.name}
                                </option>
                            ))}
                        </select>
                    </div>
                </div>

                <div className="mb-4">
                    <label className="block text-sm font-medium text-gray-700 mb-2">General Type</label>
                    <div className="flex gap-4">
                        <label className="flex items-center gap-2">
                            <input
                                type="checkbox"
                                checked={filters.isExpensiveItem === true}
                                onChange={(e) => handleGeneralTypeChange('isExpensiveItem', e.target.checked)}
                                className="w-4 h-4"
                            />
                            <span>Expensive Item</span>
                        </label>
                        <label className="flex items-center gap-2">
                            <input
                                type="checkbox"
                                checked={filters.isFridgeItem === true}
                                onChange={(e) => handleGeneralTypeChange('isFridgeItem', e.target.checked)}
                                className="w-4 h-4"
                            />
                            <span>Fridge Item</span>
                        </label>
                    </div>
                </div>

                <div className="mb-4">
                    <label className="flex items-center gap-2">
                        <input
                            type="checkbox"
                            checked={filters.minimumPanicLevelOnly}
                            onChange={(e) => handleFilterChange('minimumPanicLevelOnly', e.target.checked)}
                            className="w-4 h-4"
                        />
                        <span className="text-sm font-medium text-gray-700">Minimum Panic Level Reached Only?</span>
                    </label>
                </div>

                <div className="flex gap-2">
                    <button
                        onClick={handleGenerate}
                        className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                        disabled={loading}
                    >
                        {loading ? 'Loading...' : 'Generate'}
                    </button>
                    <button
                        onClick={handleDeselectAll}
                        className="px-6 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600"
                    >
                        Deselect All
                    </button>
                </div>
            </div>

            {/* Table */}
            <div className="bg-white rounded-lg shadow-md overflow-hidden">
                <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                        <tr>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Stock Type</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Location(Rack,Row,Column,Drawer)</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Total Items(Transition)</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">MPL</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Least Expiry Date</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Modified On</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
                        </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                        {loading ? (
                            <tr>
                                <td colSpan="8" className="px-6 py-4 text-center text-gray-500">Loading...</td>
                            </tr>
                        ) : currentStocks.length === 0 ? (
                            <tr>
                                <td colSpan="8" className="px-6 py-4 text-center text-gray-500">No stock data found</td>
                            </tr>
                        ) : (
                            currentStocks.map((stock) => (
                                <tr 
                                    key={stock.id} 
                                    className={`hover:bg-gray-50 ${stock.isBelowMPL ? 'bg-red-100' : ''}`}
                                >
                                    <td className="px-6 py-4 whitespace-nowrap font-medium">{stock.itemName}</td>
                                    <td className="px-6 py-4 whitespace-nowrap">{stock.stockType}</td>
                                    <td className="px-6 py-4 whitespace-nowrap">{stock.location}</td>
                                    <td className="px-6 py-4 whitespace-nowrap text-blue-600">
                                        {stock.totalItemsInTransition}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">{stock.mpl}</td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        {stock.expiryDate ? new Date(stock.expiryDate).toLocaleDateString() : 'N/A'}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        {stock.modifiedOn ? new Date(stock.modifiedOn).toLocaleDateString() : 'N/A'}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                        <div className="flex items-center gap-3">
                                            <button onClick={() => setDetailStock(stock)} className="text-blue-600 hover:text-blue-800" title="Details">
                                                <Squares2X2Icon className="h-5 w-5" />
                                            </button>
                                            <button onClick={() => handlePrintRow(stock)} className="text-green-600 hover:text-green-800" title="Print PDF">
                                                <PrinterIcon className="h-5 w-5" />
                                            </button>
                                            <button onClick={() => openAddToPoModal(stock)} className="text-blue-600 hover:text-blue-800" title="Add to Purchase Order">
                                                <ShareIcon className="h-5 w-5" />
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
                pageSize={itemsPerPage}
                totalCount={stocks.length}
                onPageChange={setCurrentPage}
                onPageSizeChange={setItemsPerPage}
            />

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
                            <div><div className="text-gray-500">Item Type</div><div className="font-medium text-gray-900">{detailStock.itemType || '-'}</div></div>
                            <div><div className="text-gray-500">Batch Number</div><div className="font-medium text-gray-900">{detailStock.batchNumber || '-'}</div></div>
                            <div><div className="text-gray-500">Location</div><div className="font-medium text-gray-900">{detailStock.location || '-'}</div></div>
                            <div><div className="text-gray-500">Total Items (Transition)</div><div className="font-medium text-gray-900">{detailStock.totalItemsInTransition ?? 0}</div></div>
                            <div><div className="text-gray-500">Minimum Panic Level</div><div className="font-medium text-gray-900">{detailStock.mpl ?? 0}</div></div>
                            <div><div className="text-gray-500">Least Expiry Date</div><div className="font-medium text-gray-900">{detailStock.expiryDate ? new Date(detailStock.expiryDate).toLocaleDateString() : 'N/A'}</div></div>
                            <div><div className="text-gray-500">Fridge Item</div><div className="font-medium text-gray-900">{detailStock.isFridgeItem ? 'Yes' : 'No'}</div></div>
                            <div><div className="text-gray-500">Expensive Item</div><div className="font-medium text-gray-900">{detailStock.isExpensiveItem ? 'Yes' : 'No'}</div></div>
                            <div><div className="text-gray-500">Modified On</div><div className="font-medium text-gray-900">{detailStock.modifiedOn ? new Date(detailStock.modifiedOn).toLocaleString() : '-'}</div></div>
                        </div>
                        <div className="flex justify-end border-t px-6 py-4">
                            <button onClick={() => setDetailStock(null)} className="px-4 py-2 border border-gray-300 rounded-md text-sm hover:bg-gray-50">Close</button>
                        </div>
                    </div>
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
                                    <p className="text-xs text-gray-500 mt-1">Suggested from MPL - Total Items on hand.</p>
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
}

export default StockWithExpiryPage;
