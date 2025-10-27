import React,{ useState, useEffect } from 'react';
import { QuestionMarkCircleIcon } from '@heroicons/react/24/outline';
import stockApi from '../services/stockApi';
import inventoryApi from '../services/inventoryApi';

const StockPage = () => {
  const [stocks, setStocks] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  
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

  // Lookup data
  const [stores, setStores] = useState([]);
  const [itemTypes, setItemTypes] = useState([]);
  const [items, setItems] = useState([]);
  const [categories, setCategories] = useState([]);
  const [stockTypes, setStockTypes] = useState([]);
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [entriesPerPage, setEntriesPerPage] = useState(5);
  const [searchTerm, setSearchTerm] = useState('');

  // Selected categories for multi-select
  const [selectedCategories, setSelectedCategories] = useState([]);

  useEffect(() => {
    loadLookupData();
  }, []);

  const loadLookupData = async () => {
    try {
      const data = await inventoryApi.getLookupData();
      setStores(data.stores || []);
      setItems(data.items || []);
      setStockTypes(data.stockTypes || []);
      // Note: Item types and categories need to be loaded separately if available
    } catch (err) {
      console.error('Error loading lookup data:', err);
    }
  };

  const handleSearch = async () => {
    setLoading(true);
    setError(null);
    try {
      const searchFilters = {
        ...filters,
        storeId: filters.storeId ? convertStoreIdToGuid(filters.storeId) : null,
        categoryIds: selectedCategories.join(',')
      };
      const data = await stockApi.searchStocks(searchFilters);
      setStocks(data);
    } catch (err) {
      setError('Failed to search stocks');
      console.error('Error searching stocks:', err);
    } finally {
      setLoading(false);
    }
  };

  const convertStoreIdToGuid = (storeId) => {
    if (typeof storeId === 'number' || !storeId.includes('-')) {
      const paddedId = String(storeId).padStart(8, '0');
      return `${paddedId}-0000-0000-0000-000000000000`;
    }
    return storeId;
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

  // Filter stocks based on search term
  const filteredStocks = stocks.filter(stock =>
    stock.itemName.toLowerCase().includes(searchTerm.toLowerCase()) ||
    stock.stockType?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    stock.categoryName?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  // Pagination logic
  const totalPages = Math.ceil(filteredStocks.length / entriesPerPage);
  const startIndex = (currentPage - 1) * entriesPerPage;
  const endIndex = startIndex + entriesPerPage;
  const currentStocks = filteredStocks.slice(startIndex, endIndex);

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center space-x-2">
        <QuestionMarkCircleIcon className="h-6 w-6 text-blue-600" />
        <h1 className="text-2xl font-semibold text-gray-800">Stock (MPL)</h1>
      </div>

      {/* Filters */}
      <div className="bg-white p-6 rounded-lg shadow space-y-4">
        <div className="grid grid-cols-4 gap-4">
          {/* Branch */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Branch
            </label>
            <select
              name="branchId"
              value={filters.branchId || ''}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Please Select</option>
              <option value="00000000-0000-0000-0000-000000000001">Main Branch</option>
            </select>
          </div>

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
              {stores.map(store => (
                <option key={store.id} value={store.id}>
                  {store.name}
                </option>
              ))}
            </select>
          </div>

          {/* Item Type */}
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
              <option value="1">Medicine(4)</option>
              <option value="2">Disposable(4)</option>
              <option value="3">Item(8)</option>
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
              {items.map(item => (
                <option key={item.id} value={item.id}>
                  {item.name}
                </option>
              ))}
            </select>
          </div>

          {/* Category(s) */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Category(s)
            </label>
            <select
              multiple
              size={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              onChange={(e) => {
                const options = Array.from(e.target.selectedOptions);
                setSelectedCategories(options.map(opt => opt.value));
              }}
            >
              <option value="">Please Select</option>
              <option value="1">Category 1</option>
              <option value="2">Category 2</option>
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
              {stockTypes.map(st => (
                <option key={st.id} value={st.id}>
                  {st.name}
                </option>
              ))}
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
          {error}
        </div>
      )}

      {/* Results Table */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-4 flex justify-between items-center border-b">
          <div className="flex items-center space-x-2">
            <label className="text-sm text-gray-600">Show</label>
            <select
              value={entriesPerPage}
              onChange={(e) => {
                setEntriesPerPage(Number(e.target.value));
                setCurrentPage(1);
              }}
              className="border border-gray-300 rounded px-2 py-1 text-sm"
            >
              <option value={5}>5</option>
              <option value={10}>10</option>
              <option value={25}>25</option>
              <option value={50}>50</option>
            </select>
            <label className="text-sm text-gray-600">entries</label>
          </div>

          <div className="flex items-center space-x-2">
            <label className="text-sm text-gray-600">Search:</label>
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              className="border border-gray-300 rounded px-3 py-1 text-sm"
              placeholder="Search..."
            />
          </div>
        </div>

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
              {currentStocks.length === 0 ? (
                <tr>
                  <td colSpan="7" className="px-6 py-4 text-center text-sm text-gray-500">
                    {loading ? 'Loading...' : 'Showing 1 to 1 of 1 entries'}
                  </td>
                </tr>
              ) : (
                currentStocks.map((stock) => (
                  <tr key={stock.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {stock.itemName}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {stock.stockType || '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      -
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
                      <button className="text-green-600 hover:text-green-800">
                        📥
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="p-4 flex items-center justify-between border-t">
          <div className="text-sm text-gray-600">
            Showing {startIndex + 1} to {Math.min(endIndex, filteredStocks.length)} of {filteredStocks.length} entries
          </div>
          <div className="flex space-x-2">
            <button
              onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
              disabled={currentPage === 1}
              className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
            >
              &lt;
            </button>
            {[...Array(Math.min(totalPages, 5))].map((_, i) => (
              <button
                key={i + 1}
                onClick={() => setCurrentPage(i + 1)}
                className={`px-3 py-1 border border-gray-300 rounded ${
                  currentPage === i + 1 ? 'bg-blue-600 text-white' : 'hover:bg-gray-50'
                }`}
              >
                {i + 1}
              </button>
            ))}
            <button
              onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
              disabled={currentPage === totalPages}
              className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
            >
              &gt;
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default StockPage;
