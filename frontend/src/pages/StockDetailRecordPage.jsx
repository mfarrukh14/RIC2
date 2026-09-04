import React,{ useState, useEffect } from 'react';
import { stockDetailRecordsApi } from '../services/stockDetailRecordsApi';
import { getAllStores } from '../services/storeApi';
import vendorApi from '../services/vendorApi';
import { stockTypesApi } from '../services/stockTypesApi';
import itemApi from '../services/itemApi';
import { itemTypeApi } from '../services/itemTypeApi';
import BranchField from '../components/BranchField';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';
import { useSession } from '../context/SessionContext';

const getToday = () => new Date().toISOString().split('T')[0];

const StockDetailRecordPage = () => {
  const { session } = useSession();
  const [branch, setBranch] = useState('Rawalpindi Institute of Cardiology');
  const [startDate, setStartDate] = useState(getToday());
  const [endDate, setEndDate] = useState(getToday());
  const [selectedStore, setSelectedStore] = useState('');
  const [selectedVendor, setSelectedVendor] = useState('');
  const [selectedStockType, setSelectedStockType] = useState('');
  const [selectedItem, setSelectedItem] = useState('');
  const [selectedItemType, setSelectedItemType] = useState('');
  const [selectedSaleType, setSelectedSaleType] = useState('all');
  const [stores, setStores] = useState([]);
  const [vendors, setVendors] = useState([]);
  const [stockTypes, setStockTypes] = useState([]);
  const [items, setItems] = useState([]);
  const [itemTypes, setItemTypes] = useState([]);

  // The filters actually sent to the server - only updated when "Search" is
  // clicked, mirroring StockPage - so editing a dropdown mid-form doesn't
  // re-trigger a search.
  const [submittedFilters, setSubmittedFilters] = useState(null);

  const {
    items: records,
    totalCount,
    currentPage,
    pageSize: itemsPerPage,
    setPageSize: setItemsPerPage,
    goToPage,
    search: runSearch,
    loading,
    error,
  } = usePagedList(stockDetailRecordsApi.getAll, submittedFilters || {}, { autoLoad: false, initialPageSize: 10 });

  useEffect(() => {
    fetchStores();
    fetchVendors();
    fetchStockTypes();
    fetchItems();
    fetchItemTypes();
  }, []);

  // Records are always scoped to the logged-in user's own branch.
  useEffect(() => {
    if (session?.branchName) {
      setBranch(session.branchName);
    }
  }, [session?.branchName]);

  const fetchStores = async () => {
    try {
      const data = await getAllStores();
      const activeStores = data.filter(store => store.isActive);
      setStores(activeStores);
      if (activeStores.length > 0) {
        setSelectedStore(activeStores[0].storeName);
      }
    } catch (error) {
      console.error('Error fetching stores:', error);
    }
  };

  const fetchVendors = async () => {
    try {
      const data = await vendorApi.getAll();
      setVendors(data);
    } catch (error) {
      console.error('Error fetching vendors:', error);
    }
  };

  const fetchStockTypes = async () => {
    try {
      const data = await stockTypesApi.getAllStockTypes();
      setStockTypes(data);
    } catch (error) {
      console.error('Error fetching stock types:', error);
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

  const fetchItemTypes = async () => {
    try {
      const data = await itemTypeApi.getAll();
      setItemTypes(data.filter(itemType => itemType.isActive));
    } catch (error) {
      console.error('Error fetching item types:', error);
    }
  };

  const handleSearch = () => {
    const params = {
      branch: branch || undefined,
      startDate: startDate ? new Date(startDate).toISOString() : undefined,
      endDate: endDate ? new Date(endDate).toISOString() : undefined,
      store: selectedStore || undefined,
      vendor: selectedVendor || undefined,
      stockType: selectedStockType || undefined,
      item: selectedItem || undefined,
      itemType: selectedItemType || undefined,
      saleType: selectedSaleType === 'all' ? undefined : selectedSaleType
    };
    setSubmittedFilters(params);
    runSearch(params);
  };

  const handleExport = () => {
    // Export functionality
    console.log('Export clicked');
  };

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-blue-500 rounded flex items-center justify-center">
            <span className="text-white text-lg">📋</span>
          </div>
          <h1 className="text-2xl font-semibold">Pharmacy Stock Detail Record</h1>
        </div>
        <button
          onClick={handleExport}
          className="flex items-center gap-2 bg-white border px-4 py-2 rounded hover:bg-gray-50"
        >
          <span>⬇</span>
          <span>Export</span>
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-4 mb-6">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 mb-4">
          {/* Branch - locked to the logged-in user's own branch */}
          <BranchField />

          {/* Holds two date inputs, so it gets double width on lg+ (laptop) screens -
              a single narrow grid cell was crushing both inputs into overlapping,
              unreadable date pickers. */}
          <div className="lg:col-span-2">
            <label className="block text-sm font-medium mb-1">Date Range Filter</label>
            <div className="flex flex-col sm:flex-row gap-2">
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="min-w-[140px] flex-1 border rounded px-3 py-2 text-sm"
              />
              <span className="hidden sm:inline self-center">-</span>
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className="min-w-[140px] flex-1 border rounded px-3 py-2 text-sm"
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
              <option value="">Select Store</option>
              {stores.map(store => (
                <option key={store.storeId} value={store.storeName}>
                  {store.storeName}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Vendor</label>
            <select
              value={selectedVendor}
              onChange={(e) => setSelectedVendor(e.target.value)}
              className="w-full border rounded px-3 py-2 text-sm"
            >
              <option value="">Select Vendor</option>
              {vendors.map(vendor => (
                <option key={vendor.id} value={vendor.name}>
                  {vendor.name}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium mb-1">Stock Type</label>
            <select
              value={selectedStockType}
              onChange={(e) => setSelectedStockType(e.target.value)}
              className="w-full border rounded px-3 py-2 text-sm"
            >
              <option value="">All</option>
              {stockTypes.map(stockType => (
                <option key={stockType.stockTypeId} value={stockType.stockTypeName}>
                  {stockType.stockTypeName}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Item</label>
            <select
              value={selectedItem}
              onChange={(e) => setSelectedItem(e.target.value)}
              className="w-full border rounded px-3 py-2 text-sm"
            >
              <option value="">Select Item</option>
              {items.map(item => (
                <option key={item.id} value={item.name}>
                  {item.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Type</label>
            <select
              value={selectedItemType}
              onChange={(e) => setSelectedItemType(e.target.value)}
              className="w-full border rounded px-3 py-2 text-sm"
            >
              <option value="">All</option>
              {itemTypes.map(itemType => (
                <option key={itemType.id} value={itemType.name}>
                  {itemType.name}
                </option>
              ))}
            </select>
          </div>

          <div className="flex items-end">
            <button
              onClick={handleSearch}
              disabled={loading}
              className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700 disabled:bg-gray-400"
            >
              {loading ? 'Loading...' : 'Search'}
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">Sale Type</label>
            <div className="flex flex-wrap gap-x-6 gap-y-2 mt-2">
              <label className="flex items-center gap-2">
                <input
                  type="radio"
                  value="all"
                  checked={selectedSaleType === 'all'}
                  onChange={(e) => setSelectedSaleType(e.target.value)}
                  className="rounded-full"
                />
                <span className="text-sm">Over All</span>
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="radio"
                  value="opd"
                  checked={selectedSaleType === 'opd'}
                  onChange={(e) => setSelectedSaleType(e.target.value)}
                  className="rounded-full"
                />
                <span className="text-sm">OPD</span>
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="radio"
                  value="emergency"
                  checked={selectedSaleType === 'emergency'}
                  onChange={(e) => setSelectedSaleType(e.target.value)}
                  className="rounded-full"
                />
                <span className="text-sm">Emergency</span>
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="radio"
                  value="ipd"
                  checked={selectedSaleType === 'ipd'}
                  onChange={(e) => setSelectedSaleType(e.target.value)}
                  className="rounded-full"
                />
                <span className="text-sm">IPD</span>
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="radio"
                  value="outdoor"
                  checked={selectedSaleType === 'outdoor'}
                  onChange={(e) => setSelectedSaleType(e.target.value)}
                  className="rounded-full"
                />
                <span className="text-sm">Out Door Pharmacy</span>
              </label>
            </div>
          </div>
        </div>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          Failed to load stock detail records{error.response?.data?.message ? `: ${error.response.data.message}` : error.message ? `: ${error.message}` : ''}
        </div>
      )}

      {/* Table */}
      <div className="bg-white rounded-lg shadow">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Sr. ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Name ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Stock Type ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Buying Price ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Selling Price ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Opening ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Received ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Issued ↕</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Balance ↕</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {records.length > 0 ? (
                records.map((record, index) => (
                  <tr key={index} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-sm">{record.sr}</td>
                    <td className="px-4 py-3 text-sm">{record.name}</td>
                    <td className="px-4 py-3 text-sm">{record.stockType}</td>
                    <td className="px-4 py-3 text-sm">{record.buyingPrice.toFixed(2)}</td>
                    <td className="px-4 py-3 text-sm">{record.sellingPrice.toFixed(2)}</td>
                    <td className="px-4 py-3 text-sm">{record.opening}</td>
                    <td className="px-4 py-3 text-sm">{record.received}</td>
                    <td className="px-4 py-3 text-sm">{record.issued}</td>
                    <td className="px-4 py-3 text-sm">{record.balance}</td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="9" className="px-4 py-8 text-center text-sm text-gray-500">
                    {loading ? 'Loading...' : 'No data available in table'}
                  </td>
                </tr>
              )}
            </tbody>
            {records.length > 0 && (
              <tfoot className="bg-gray-50 border-t">
                <tr>
                  <td className="px-4 py-3 text-sm font-semibold" colSpan="3">Sr.</td>
                  <td className="px-4 py-3 text-sm font-semibold">Name</td>
                  <td className="px-4 py-3 text-sm font-semibold">Stock Type</td>
                  <td className="px-4 py-3 text-sm font-semibold">Buying Price</td>
                  <td className="px-4 py-3 text-sm font-semibold">Selling Price</td>
                  <td className="px-4 py-3 text-sm font-semibold">Opening</td>
                  <td className="px-4 py-3 text-sm font-semibold">Received</td>
                </tr>
              </tfoot>
            )}
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

export default StockDetailRecordPage;
