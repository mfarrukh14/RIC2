import React,{ useState, useEffect } from 'react';
import { stockDetailRecordsApi } from '../services/stockDetailRecordsApi';
import { getAllStores } from '../services/storeApi';
import vendorApi from '../services/vendorApi';
import { stockTypesApi } from '../services/stockTypesApi';
import itemApi from '../services/itemApi';
import { itemTypeApi } from '../services/itemTypeApi';
import BranchField from '../components/BranchField';
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
  const [records, setRecords] = useState([]);
  const [loading, setLoading] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');

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
      const data = await itemApi.getAll();
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

  const fetchData = async () => {
    try {
      setLoading(true);
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

      const data = await stockDetailRecordsApi.getAll(params);
      setRecords(data);
    } catch (error) {
      console.error('Error fetching stock detail records:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleExport = () => {
    // Export functionality
    console.log('Export clicked');
  };

  const filteredRecords = records.filter(record =>
    record.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    record.stockType?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = filteredRecords.slice(indexOfFirstItem, indexOfLastItem);
  const totalPages = Math.ceil(filteredRecords.length / itemsPerPage);

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
              onClick={fetchData}
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
              {currentItems.length > 0 ? (
                currentItems.map((record, index) => (
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
                    No data available in table
                  </td>
                </tr>
              )}
            </tbody>
            {currentItems.length > 0 && (
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

        <div className="p-4 border-t flex justify-between items-center">
          <div className="text-sm text-gray-600">
            Showing {indexOfFirstItem + 1} to {Math.min(indexOfLastItem, filteredRecords.length)} of {filteredRecords.length} entries
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
              disabled={currentPage === 1}
              className="px-3 py-1 border rounded text-sm disabled:opacity-50"
            >
              Previous
            </button>
            {[...Array(Math.min(5, totalPages))].map((_, i) => {
              const pageNum = i + 1;
              return (
                <button
                  key={pageNum}
                  onClick={() => setCurrentPage(pageNum)}
                  className={`px-3 py-1 border rounded text-sm ${
                    currentPage === pageNum ? 'bg-blue-600 text-white' : ''
                  }`}
                >
                  {pageNum}
                </button>
              );
            })}
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

export default StockDetailRecordPage;
