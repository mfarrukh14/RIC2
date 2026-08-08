import React, { useState, useEffect } from 'react';
import { CheckIcon, XMarkIcon } from '@heroicons/react/24/outline';
import { stockAuditApi } from '../services/stockAuditApi';
import inventoryApi from '../services/inventoryApi';
import BranchField from '../components/BranchField';
import Pagination from '../components/Pagination';
import { useSession } from '../context/SessionContext';

const normalizeStores = (stores) =>
  (stores || [])
    .map((store, index) => {
      const id = store?.id ?? store?.storeId;
      if (id === null || id === undefined || id === '') {
        return null;
      }

      return {
        id,
        name: store?.name ?? store?.storeName ?? `Store ${index + 1}`,
      };
    })
    .filter(Boolean);

const StockAuditPage = () => {
  const { session } = useSession();
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [successMessage, setSuccessMessage] = useState('');

  // Past stock audits (history list) - matches the old system's Stock Audit
  // screen, which was purely a browsable log of previously-submitted audits.
  const [pastAudits, setPastAudits] = useState([]);
  const [loadingHistory, setLoadingHistory] = useState(false);
  
  // Search filters
  const [filters, setFilters] = useState({
    branchId: null,
    storeId: null,
    itemType: 'All', // All, Medicine, Disposable, Item
    categoryId: null,
    itemIds: '',
    manufacturerIds: '',
    stockTypeId: null
  });

  // Audit form
  const [auditForm, setAuditForm] = useState({
    storeId: null,
    branchId: null,
    stockAuditDate: new Date().toISOString().split('T')[0],
    remarks: ''
  });

  // Lookup data
  const [stores, setStores] = useState([]);
  const [categories, setCategories] = useState([]);
  const [itemList, setItemList] = useState([]);
  const [manufacturers, setManufacturers] = useState([]);
  const [stockTypes, setStockTypes] = useState([]);
  
  // Selected items and manufacturers for multi-select
  const [selectedItems, setSelectedItems] = useState([]);
  const [selectedManufacturers, setSelectedManufacturers] = useState([]);

  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [entriesPerPage, setEntriesPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  const [historyPage, setHistoryPage] = useState(1);
  const [historyPageSize, setHistoryPageSize] = useState(10);

  useEffect(() => {
    loadLookupData();
  }, []);

  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, entriesPerPage]);

  useEffect(() => {
    setHistoryPage(1);
  }, [historyPageSize]);

  // Stock audits are always scoped to the logged-in user's own branch.
  useEffect(() => {
    if (session?.branchId) {
      setFilters((prev) => ({ ...prev, branchId: session.branchId }));
      setAuditForm((prev) => ({ ...prev, branchId: session.branchId }));
      loadPastAudits(session.branchId);
    }
  }, [session?.branchId]);

  const loadPastAudits = async (branchId) => {
    setLoadingHistory(true);
    try {
      const data = await stockAuditApi.getAll({ branchId });
      setPastAudits(data);
    } catch (err) {
      console.error('Error loading past stock audits:', err);
    } finally {
      setLoadingHistory(false);
    }
  };

  const loadLookupData = async () => {
    try {
      const data = await inventoryApi.getLookupData();
      setStores(normalizeStores(data.stores));
      setItemList(data.items || []);
      setManufacturers((data.manufacturers || []).map((manufacturer) => ({
        id: manufacturer.id ?? manufacturer.manufacturerId,
        name: manufacturer.name ?? manufacturer.manufacturerName,
      })));
      setCategories(data.categories || []);
      setStockTypes(data.stockTypes || []);
    } catch (err) {
      console.error('Error loading lookup data:', err);
    }
  };

  const handleGenerate = async () => {
    setLoading(true);
    setError(null);
    setSuccessMessage('');
    try {
      const searchFilters = {
        branchId: filters.branchId ? Number(filters.branchId) : null,
        storeId: filters.storeId ? Number(filters.storeId) : null,
        stockTypeId: filters.stockTypeId ? Number(filters.stockTypeId) : null,
        itemIds: selectedItems.join(','),
        manufacturerIds: selectedManufacturers.join(',')
      };
      const data = await stockAuditApi.searchItems(searchFilters);
      setItems(data);
    } catch (err) {
      setError('Failed to generate stock audit items');
      console.error('Error generating stock audit:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setFilters(prev => ({
      ...prev,
      [name]: value === '' ? null : value
    }));
  };

  const handleAuditFormChange = (e) => {
    const { name, value } = e.target;
    setAuditForm(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleItemToggle = (itemId) => {
    setSelectedItems(prev => {
      if (prev.includes(itemId)) {
        return prev.filter(id => id !== itemId);
      } else {
        return [...prev, itemId];
      }
    });
  };

  const handleManufacturerToggle = (manufacturerId) => {
    setSelectedManufacturers(prev => {
      if (prev.includes(manufacturerId)) {
        return prev.filter(id => id !== manufacturerId);
      } else {
        return [...prev, manufacturerId];
      }
    });
  };

  const handleQtyChange = (itemId, qty) => {
    setItems(prev => prev.map(item => {
      if (item.itemId === itemId) {
        const qtyOnShelf = parseFloat(qty) || 0;
        const difference = qtyOnShelf - item.totalItems;
        return { ...item, qtyOnShelf, difference };
      }
      return item;
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!filters.storeId) {
      setError('Please select a store from the filters above');
      return;
    }
    
    setLoading(true);
    setError(null);
    setSuccessMessage('');

    try {
      const auditData = {
        storeId: Number(filters.storeId),
        branchId: Number(filters.branchId || session?.branchId),
        stockAuditDate: new Date(auditForm.stockAuditDate).toISOString(),
        remarks: auditForm.remarks
      };

      await stockAuditApi.createAudit(auditData);
      setSuccessMessage('Stock audit created successfully');
      loadPastAudits(auditData.branchId);

      // Reset form
      setAuditForm({
        storeId: null,
        branchId: null,
        stockAuditDate: new Date().toISOString().split('T')[0],
        remarks: ''
      });
      setItems([]);
      setSelectedItems([]);
      setSelectedManufacturers([]);
    } catch (err) {
      setError(err.message || 'Failed to create stock audit');
    } finally {
      setLoading(false);
    }
  };

  // Filter items by search term
  const filteredItems = items.filter(item =>
    item.itemName?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  // Pagination
  const indexOfLastEntry = currentPage * entriesPerPage;
  const indexOfFirstEntry = indexOfLastEntry - entriesPerPage;
  const currentItems = filteredItems.slice(indexOfFirstEntry, indexOfLastEntry);

  const pastAuditsPage = pastAudits.slice((historyPage - 1) * historyPageSize, historyPage * historyPageSize);

  return (
    <div className="p-6">
      <h1 className="text-2xl font-semibold text-gray-900 mb-6">Stock Audit</h1>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {successMessage && (
        <div className="mb-4 bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded">
          {successMessage}
        </div>
      )}

      {/* Filters Section */}
      <div className="bg-white shadow rounded-lg p-6 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
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
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">Select Store</option>
              {stores.map((store) => (
                <option key={store.id} value={store.id}>
                  {store.name}
                </option>
              ))}
            </select>
          </div>

          {/* Item Type with Radio Buttons */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Item Type
            </label>
            <div className="flex items-center gap-4 mt-2">
              <label className="flex items-center">
                <input
                  type="radio"
                  name="itemType"
                  value="All"
                  checked={filters.itemType === 'All'}
                  onChange={handleFilterChange}
                  className="mr-1"
                />
                <span className="text-sm">All</span>
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="itemType"
                  value="Medicine"
                  checked={filters.itemType === 'Medicine'}
                  onChange={handleFilterChange}
                  className="mr-1"
                />
                <span className="text-sm">Medicine()</span>
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="itemType"
                  value="Disposable"
                  checked={filters.itemType === 'Disposable'}
                  onChange={handleFilterChange}
                  className="mr-1"
                />
                <span className="text-sm">Disposable()</span>
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="itemType"
                  value="Item"
                  checked={filters.itemType === 'Item'}
                  onChange={handleFilterChange}
                  className="mr-1"
                />
                <span className="text-sm">Item(s)</span>
              </label>
            </div>
          </div>

          {/* Category */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Category(s):
            </label>
            <select
              name="categoryId"
              value={filters.categoryId || ''}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">Please Select</option>
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
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-4">
          {/* Item(s) Multi-select */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Item(s)
            </label>
            <select
              multiple
              size="1"
              onChange={(e) => {
                const selected = Array.from(e.target.selectedOptions, option => option.value);
                setSelectedItems(selected);
              }}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            >
              {itemList.map((item, index) => {
                const itemId = item.id ?? item.itemId ?? '';
                const itemName = item.name ?? item.itemName ?? `Item ${index + 1}`;

                return (
                <option key={`audit-item-${itemId || index}`} value={itemId}>
                  {itemName}
                </option>
                );
              })}
            </select>
          </div>

          {/* Stock Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Type
            </label>
            <select
              name="stockTypeId"
              value={filters.stockTypeId || ''}
              onChange={handleFilterChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">All</option>
              {stockTypes.map((stockType) => (
                <option key={stockType.id} value={stockType.id}>
                  {stockType.name}
                </option>
              ))}
            </select>
          </div>

          {/* Manufacturer(s) */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Manufacturer(s)
            </label>
            <select
              multiple
              size="1"
              onChange={(e) => {
                const selected = Array.from(e.target.selectedOptions, option => option.value);
                setSelectedManufacturers(selected);
              }}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            >
              {manufacturers.map((manufacturer, index) => {
                const manufacturerId = manufacturer.id ?? manufacturer.brandId ?? '';
                const manufacturerName = manufacturer.name ?? manufacturer.brandName ?? `Manufacturer ${index + 1}`;

                return (
                <option key={`manufacturer-${manufacturerId || index}`} value={manufacturerId}>
                  {manufacturerName}
                </option>
                );
              })}
            </select>
          </div>
        </div>

        <div className="flex justify-end">
          <button
            onClick={handleGenerate}
            disabled={loading}
            className="px-6 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 disabled:bg-gray-400"
          >
            {loading ? 'Generating...' : 'Generate'}
          </button>
        </div>
      </div>

      {/* Results Table */}
      {items.length > 0 && (
        <div className="bg-white shadow rounded-lg p-6 mb-6">
          <div className="flex justify-end items-center mb-4">
            <div>
              <input
                type="text"
                placeholder="Search..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="px-3 py-1 border border-gray-300 rounded-md text-sm"
              />
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-12">
                    <input type="checkbox" className="rounded" />
                  </th>
                  <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Name
                  </th>
                  <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Stock Type
                  </th>
                  <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Total Items (Transition)
                  </th>
                  <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Qty on Shelf
                  </th>
                  <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Difference
                  </th>
                  <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    MPL
                  </th>
                  <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Sale Price
                  </th>
                  <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Quantity Per Packet
                  </th>
                  <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Modified On
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {currentItems.map((item, index) => (
                  <React.Fragment key={`audit-row-${item.itemId ?? 'item'}-${item.stockType ?? 'stock'}-${item.batchNo ?? index}-${index}`}>
                    <tr className="hover:bg-gray-50">
                      <td className="px-3 py-4 whitespace-nowrap">
                        <input type="checkbox" className="rounded" />
                      </td>
                      <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                        {item.itemName}
                      </td>
                      <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                        {item.stockType}
                      </td>
                      <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                        {item.totalItems}
                      </td>
                      <td className="px-3 py-4 whitespace-nowrap">
                        <input
                          type="text"
                          placeholder="Qty On Shelf"
                          value={item.qtyOnShelf || ''}
                          onChange={(e) => handleQtyChange(item.itemId, e.target.value)}
                          className="w-28 px-2 py-1 border border-gray-300 rounded text-sm"
                        />
                      </td>
                      <td className="px-3 py-4 whitespace-nowrap">
                        <input
                          type="text"
                          placeholder="Difference"
                          value={item.difference || ''}
                          readOnly
                          className="w-24 px-2 py-1 border border-gray-300 rounded text-sm bg-gray-50"
                        />
                      </td>
                      <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                        {item.mpl}
                      </td>
                      <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                        {item.salePrice}
                      </td>
                      <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                        {item.quantityPerPacket}
                      </td>
                      <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                        {item.modifiedOn ? new Date(item.modifiedOn).toLocaleDateString() : '-'}
                      </td>
                    </tr>
                    {/* Additional row for totals - show after each item */}
                    <tr className="bg-gray-50">
                      <td colSpan="3" className="px-3 py-2"></td>
                      <td className="px-3 py-2 text-sm font-medium text-green-600">
                        Total Sale:
                      </td>
                      <td className="px-3 py-2 text-sm font-medium text-green-600">
                        Total Buy:
                      </td>
                      <td colSpan="2" className="px-3 py-2">
                        <input
                          type="text"
                          placeholder="70"
                          className="w-20 px-2 py-1 border border-gray-300 rounded text-sm"
                        />
                      </td>
                      <td className="px-3 py-2 text-sm">MPL</td>
                      <td colSpan="2" className="px-3 py-2 text-sm">Quantity Per Packet</td>
                    </tr>
                  </React.Fragment>
                ))}
              </tbody>
            </table>
          </div>

          <Pagination
            currentPage={currentPage}
            pageSize={entriesPerPage}
            totalCount={filteredItems.length}
            onPageChange={setCurrentPage}
            onPageSizeChange={setEntriesPerPage}
          />
        </div>
      )}

      {/* Audit Form Section */}
      <div className="bg-white shadow rounded-lg p-6">
        <form onSubmit={handleSubmit}>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Stock Audit
              </label>
              <input
                type="text"
                name="stockAuditName"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                placeholder=""
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Stock Audit Date <span className="text-red-500">*</span>
              </label>
              <input
                type="date"
                name="stockAuditDate"
                value={auditForm.stockAuditDate}
                onChange={handleAuditFormChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          </div>

          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Remarks
            </label>
            <textarea
              name="remarks"
              value={auditForm.remarks}
              onChange={handleAuditFormChange}
              rows="3"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              placeholder="Please Enter Remarks"
            />
          </div>

          <div className="flex justify-end">
            <button
              type="submit"
              disabled={loading}
              className="px-8 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 disabled:bg-gray-400 font-medium"
            >
              {loading ? 'Submitting...' : 'Submit'}
            </button>
          </div>
        </form>
      </div>

      {/* Past Stock Audits (history) */}
      <div className="bg-white shadow rounded-lg p-6 mt-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Past Stock Audits</h2>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date
                </th>
                <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Store
                </th>
                <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Remarks
                </th>
                <th className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Created On
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {loadingHistory ? (
                <tr>
                  <td colSpan="4" className="px-3 py-4 text-center text-sm text-gray-500">
                    Loading...
                  </td>
                </tr>
              ) : pastAudits.length === 0 ? (
                <tr>
                  <td colSpan="4" className="px-3 py-4 text-center text-sm text-gray-500">
                    No stock audits found
                  </td>
                </tr>
              ) : (
                pastAuditsPage.map((audit) => (
                  <tr key={audit.id} className="hover:bg-gray-50">
                    <td className="px-3 py-3 whitespace-nowrap text-sm text-gray-900">
                      {new Date(audit.auditDate).toLocaleDateString()}
                    </td>
                    <td className="px-3 py-3 whitespace-nowrap text-sm text-gray-900">
                      {audit.storeName || '-'}
                    </td>
                    <td className="px-3 py-3 text-sm text-gray-500">
                      {audit.remarks || '-'}
                    </td>
                    <td className="px-3 py-3 whitespace-nowrap text-sm text-gray-500">
                      {new Date(audit.createdOn).toLocaleString()}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
        <Pagination
          currentPage={historyPage}
          pageSize={historyPageSize}
          totalCount={pastAudits.length}
          onPageChange={setHistoryPage}
          onPageSizeChange={setHistoryPageSize}
        />
      </div>
    </div>
  );
};

export default StockAuditPage;
