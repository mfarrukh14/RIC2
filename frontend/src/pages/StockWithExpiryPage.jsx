import React,{ useState, useEffect } from 'react';
import { stockWithExpiryApi } from '../services/stockWithExpiryApi';
import { getAllStores } from '../services/storeApi';
import { branchApi } from '../services/branchApi';
import itemApi from '../services/itemApi';
import itemCategoryApi from '../services/itemCategoryApi';

function StockWithExpiryPage() {
    const [stocks, setStocks] = useState([]);
    const [stores, setStores] = useState([]);
    const [branches, setBranches] = useState([]);
    const [items, setItems] = useState([]);
    const [categories, setCategories] = useState([]);
    const [loading, setLoading] = useState(false);
    
    const [currentPage, setCurrentPage] = useState(1);
    const [itemsPerPage, setItemsPerPage] = useState(10);
    const [searchTerm, setSearchTerm] = useState('');
    
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
        fetchStocks();
    }, []);

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
            const data = await itemApi.getAll();
            setItems(data);
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

    const filteredStocks = stocks.filter(stock =>
        stock.itemName?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const indexOfLastItem = currentPage * itemsPerPage;
    const indexOfFirstItem = indexOfLastItem - itemsPerPage;
    const currentStocks = filteredStocks.slice(indexOfFirstItem, indexOfLastItem);
    const totalPages = Math.ceil(filteredStocks.length / itemsPerPage);

    const paginate = (pageNumber) => setCurrentPage(pageNumber);

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
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">Branch</label>
                        <select
                            value={filters.branchId || ''}
                            onChange={(e) => handleFilterChange('branchId', e.target.value ? parseInt(e.target.value) : null)}
                            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        >
                            <option value="">Select Branch</option>
                            {branches.map(branch => (
                                <option key={branch.id} value={branch.id}>
                                    {branch.name}
                                </option>
                            ))}
                        </select>
                    </div>

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
                        <input
                            type="text"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            placeholder="Search by item name..."
                            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
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

            {/* Results Summary */}
            <div className="mb-4 flex justify-between items-center">
                <div className="text-sm text-gray-600">
                    Show 
                    <select
                        value={itemsPerPage}
                        onChange={(e) => {
                            setItemsPerPage(parseInt(e.target.value));
                            setCurrentPage(1);
                        }}
                        className="mx-2 px-2 py-1 border border-gray-300 rounded"
                    >
                        <option value="10">10</option>
                        <option value="25">25</option>
                        <option value="50">50</option>
                        <option value="100">100</option>
                    </select>
                    entries
                </div>
                <div className="text-sm text-gray-600">
                    Showing {indexOfFirstItem + 1} to {Math.min(indexOfLastItem, filteredStocks.length)} of {filteredStocks.length} entries
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
                                        <button className="text-blue-600 hover:text-blue-900 mr-3" title="View Details">
                                            👁️
                                        </button>
                                        <button className="text-green-600 hover:text-green-900 mr-3" title="Download">
                                            📥
                                        </button>
                                        <button className="text-red-600 hover:text-red-900" title="Delete">
                                            🗑️
                                        </button>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
                <div className="flex justify-center items-center gap-2 mt-6">
                    <button 
                        onClick={() => paginate(currentPage - 1)} 
                        disabled={currentPage === 1}
                        className="px-4 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 disabled:bg-gray-300 disabled:cursor-not-allowed"
                    >
                        Previous
                    </button>
                    
                    {[...Array(Math.min(6, totalPages))].map((_, idx) => {
                        const pageNum = idx + 1;
                        return (
                            <button
                                key={pageNum}
                                onClick={() => paginate(pageNum)}
                                className={`px-4 py-2 rounded-lg ${
                                    currentPage === pageNum
                                        ? 'bg-blue-600 text-white'
                                        : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                                }`}
                            >
                                {pageNum}
                            </button>
                        );
                    })}
                    
                    <button 
                        onClick={() => paginate(currentPage + 1)} 
                        disabled={currentPage === totalPages}
                        className="px-4 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 disabled:bg-gray-300 disabled:cursor-not-allowed"
                    >
                        Next
                    </button>
                </div>
            )}
        </div>
    );
}

export default StockWithExpiryPage;
