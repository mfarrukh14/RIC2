import React, { useState, useEffect } from 'react';
import { FiSearch } from 'react-icons/fi';
import grnApi from '../services/grnApi';
import inventoryApi from '../services/inventoryApi';

const GRNPage = () => {
  const [grns, setGRNs] = useState([]);
  const [totalCount, setTotalCount] = useState(0);
  const [entriesPerPage, setEntriesPerPage] = useState(5);
  const [currentPage, setCurrentPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState('');
  const [lookupData, setLookupData] = useState({
    vendors: [],
    stockTypes: [],
    manufacturers: [],
    purchaseOrders: []
  });

  // Form state
  const [showForm, setShowForm] = useState(false);
  const [selectedPO, setSelectedPO] = useState('');
  const [selectedPODetails, setSelectedPODetails] = useState(null);
  const [vendorInvoiceNo, setVendorInvoiceNo] = useState('');
  const [vendorInvoiceDate, setVendorInvoiceDate] = useState('');

  // Items from PO
  const [items, setItems] = useState([]);
  const [selectedItems, setSelectedItems] = useState([]);

  useEffect(() => {
    loadLookups();
  }, []);

  useEffect(() => {
    loadGRNs();
  }, [currentPage, entriesPerPage, searchTerm]);

  useEffect(() => {
    setCurrentPage(1);
  }, [entriesPerPage, searchTerm]);

  const loadLookups = async () => {
    try {
      const [lookup, invLookup] = await Promise.all([
        grnApi.getLookupData(),
        inventoryApi.getLookupData()
      ]);

      setLookupData({
        ...lookup,
        items: invLookup.items
      });
    } catch (err) {
      console.error('Error fetching lookup data:', err);
    }
  };

  const loadGRNs = async () => {
    try {
      const response = await grnApi.getAll({
        pageNumber: currentPage,
        pageSize: entriesPerPage,
        search: searchTerm.trim() || undefined
      });
      setGRNs(response.items);
      setTotalCount(response.totalCount);
    } catch (err) {
      console.error('Error fetching GRNs:', err);
    }
  };

  const handlePOSelect = async (e) => {
    const poId = e.target.value;
    setSelectedPO(poId);

    if (poId) {
      await loadPOItems(poId);
    } else {
      setSelectedPODetails(null);
      setItems([]);
    }
  };

  // The store credited when this GRN is saved is resolved server-side from this
  // PO's own StoreId - only items with quantity still remaining to receive are
  // offered (an item already fully received against this PO won't show up again).
  const loadPOItems = async (poId) => {
    try {
      const po = await grnApi.getPODetails(poId);
      setSelectedPODetails(po);

      const mappedItems = po.items
        .filter((item) => item.remainingQuantity > 0)
        .map((item) => ({
          id: item.itemId,
          itemName: item.itemName,
          manufacturer: '',
          mfgDate: '',
          expiryDate: '',
          registrationNumber: '',
          lotNo: '',
          batchNo: '',
          noOfBoxes: null,
          noOfPackets: null,
          itemPerPacket: null,
          poQuantity: item.orderedQuantity,
          packQuantity: null,
          receivedQuantity: item.remainingQuantity,
          remainingQuantity: 0,
          totalBuyingPrice: (item.rate || 0) * item.remainingQuantity,
          unitBuyingPrice: item.rate || 0,
          advanceTaxPercent: 0,
          advanceTaxAmount: 0
        }));

      setItems(mappedItems);
      setSelectedItems(mappedItems.map((i) => i.id));
    } catch (err) {
      console.error('Error loading PO items:', err);
      alert('Failed to load items for this Purchase Order.');
      setSelectedPODetails(null);
      setItems([]);
    }
  };

  const handleItemSelect = (itemId) => {
    setSelectedItems(prev => {
      if (prev.includes(itemId)) {
        return prev.filter(id => id !== itemId);
      } else {
        return [...prev, itemId];
      }
    });
  };

  const handleItemChange = (itemId, field, value) => {
    setItems(prev => prev.map(item => 
      item.id === itemId ? { ...item, [field]: value } : item
    ));
  };

  const handleSearch = () => {
    if (!selectedPO) {
      alert('Please select a Purchase Order');
      return;
    }
    setShowForm(true);
  };

  const handleSave = async () => {
    if (!selectedPODetails) {
      alert('Please select a Purchase Order');
      return;
    }

    try {
      const selectedItemsData = items.filter(item => selectedItems.includes(item.id));

      const grnData = {
        purchaseOrderId: selectedPODetails.id,
        poNumber: selectedPODetails.poNumber,
        vendorId: selectedPODetails.vendorId,
        vendorInvoiceNo,
        vendorInvoiceDate: vendorInvoiceDate || null,
        stockTypeId: lookupData.stockTypes?.[0]?.id || null,
        dateAndTime: new Date().toISOString(),
        items: selectedItemsData.map(item => ({
          itemId: item.id,
          manufacturerId: item.manufacturer || null,
          mfgDate: item.mfgDate || null,
          expiryDate: item.expiryDate || null,
          registrationNumber: item.registrationNumber,
          lotNo: item.lotNo,
          batchNo: item.batchNo,
          noOfBoxes: item.noOfBoxes,
          noOfPackets: item.noOfPackets,
          itemPerPacket: item.itemPerPacket,
          totalItem: item.poQuantity,
          packQuantity: item.packQuantity,
          receivedQuantity: item.receivedQuantity,
          remainingQuantity: item.remainingQuantity,
          totalBuyingPrice: item.totalBuyingPrice,
          unitBuyingPrice: item.unitBuyingPrice,
          advanceTaxPercentage: item.advanceTaxPercent,
          advanceTaxAmount: item.advanceTaxAmount
        }))
      };

      await grnApi.create(grnData);
      alert('GRN created successfully!');
      setShowForm(false);
      setSelectedPO('');
      setSelectedPODetails(null);
      setItems([]);
      loadGRNs();
    } catch (err) {
      console.error('Error saving GRN:', err);
      alert(err.response?.data?.message || 'Failed to save GRN');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this GRN? This will reverse the stock it received.')) {
      return;
    }
    try {
      await grnApi.delete(id);
      loadGRNs();
    } catch (err) {
      console.error('Error deleting GRN:', err);
      alert(err.response?.data?.message || 'Failed to delete GRN');
    }
  };

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold text-gray-800 mb-6 flex items-center">
        <span className="mr-2">📦</span>
        Inventory Receiving (GRN)
        <span className="ml-2 text-blue-600 cursor-pointer">ⓘ</span>
      </h1>

      {/* Search Section */}
      <div className="bg-white rounded-lg shadow p-4 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Purchase Order No<span className="text-red-500">*</span>
            </label>
            <div className="relative">
              <select
                value={selectedPO}
                onChange={handlePOSelect}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 appearance-none"
              >
                <option value="">Select Purchase Order</option>
                {lookupData.purchaseOrders.map((po) => (
                  <option key={po.id} value={po.id}>
                    {po.poNumber}{po.vendorName ? ` - ${po.vendorName}` : ''}
                  </option>
                ))}
              </select>
              <div className="absolute right-3 top-1/2 transform -translate-y-1/2 pointer-events-none">
                ▼
              </div>
            </div>
          </div>

          <div className="flex items-end">
            <button
              onClick={handleSearch}
              className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 flex items-center gap-2"
            >
              <FiSearch />
              Search
            </button>
          </div>
        </div>

        {showForm && (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Vendor Invoice No
                </label>
                <input
                  type="text"
                  value={vendorInvoiceNo}
                  onChange={(e) => setVendorInvoiceNo(e.target.value)}
                  placeholder="Vendor Invoice Number"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Vendor Invoice Date
                </label>
                <input
                  type="date"
                  value={vendorInvoiceDate}
                  onChange={(e) => setVendorInvoiceDate(e.target.value)}
                  placeholder="DD/MM/YYYY"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>
          </>
        )}
      </div>

      {/* Items Table */}
      {showForm && items.length > 0 && (
        <div className="bg-white rounded-lg shadow overflow-hidden mb-6">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-2 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    <input type="checkbox" checked={selectedItems.length === items.length} 
                      onChange={() => {
                        if (selectedItems.length === items.length) {
                          setSelectedItems([]);
                        } else {
                          setSelectedItems(items.map(i => i.id));
                        }
                      }}
                    />
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Item Name</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Manufacturer*</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Mfg Date*</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Expiry Date*</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Registration Number</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Lot No</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Batch No</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">No Of Boxes</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">No Of Packets*</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Item Per Packet*</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">PO Quantity</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Pack Quantity</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Received Quantity</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Remaining Quantity</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Total Buying Price (₨)*</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Unit Buying Price (₨)*</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Advance Tax %</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Advance Tax Amount</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {items.map((item) => (
                  <tr key={item.id} className={selectedItems.includes(item.id) ? 'bg-blue-50' : ''}>
                    <td className="px-2 py-3">
                      <input
                        type="checkbox"
                        checked={selectedItems.includes(item.id)}
                        onChange={() => handleItemSelect(item.id)}
                      />
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-900">{item.itemName}</td>
                    <td className="px-4 py-3">
                      <select
                        value={item.manufacturer}
                        onChange={(e) => handleItemChange(item.id, 'manufacturer', e.target.value)}
                        className="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                      >
                        <option value="">Select M...</option>
                        {lookupData.manufacturers.map((m) => (
                          <option key={m.id} value={m.id}>{m.name}</option>
                        ))}
                      </select>
                    </td>
                    <td className="px-4 py-3">
                      <input
                        type="date"
                        value={item.mfgDate}
                        onChange={(e) => handleItemChange(item.id, 'mfgDate', e.target.value)}
                        className="w-32 px-2 py-1 border border-gray-300 rounded text-sm"
                      />
                    </td>
                    <td className="px-4 py-3">
                      <input
                        type="date"
                        value={item.expiryDate}
                        onChange={(e) => handleItemChange(item.id, 'expiryDate', e.target.value)}
                        className="w-32 px-2 py-1 border border-gray-300 rounded text-sm"
                      />
                    </td>
                    <td className="px-4 py-3">
                      <input
                        type="text"
                        value={item.registrationNumber}
                        onChange={(e) => handleItemChange(item.id, 'registrationNumber', e.target.value)}
                        className="w-32 px-2 py-1 border border-gray-300 rounded text-sm"
                      />
                    </td>
                    <td className="px-4 py-3">
                      <input
                        type="text"
                        value={item.lotNo}
                        onChange={(e) => handleItemChange(item.id, 'lotNo', e.target.value)}
                        className="w-24 px-2 py-1 border border-gray-300 rounded text-sm"
                      />
                    </td>
                    <td className="px-4 py-3">
                      <input
                        type="text"
                        value={item.batchNo}
                        onChange={(e) => handleItemChange(item.id, 'batchNo', e.target.value)}
                        className="w-24 px-2 py-1 border border-gray-300 rounded text-sm"
                      />
                    </td>
                    <td className="px-4 py-3">
                      <input
                        type="number"
                        value={item.noOfBoxes}
                        onChange={(e) => handleItemChange(item.id, 'noOfBoxes', parseInt(e.target.value))}
                        className="w-20 px-2 py-1 border border-gray-300 rounded text-sm"
                      />
                    </td>
                    <td className="px-4 py-3">
                      <input
                        type="number"
                        value={item.noOfPackets}
                        onChange={(e) => handleItemChange(item.id, 'noOfPackets', parseInt(e.target.value))}
                        className="w-20 px-2 py-1 border border-gray-300 rounded text-sm"
                      />
                    </td>
                    <td className="px-4 py-3">
                      <input
                        type="number"
                        value={item.itemPerPacket}
                        onChange={(e) => handleItemChange(item.id, 'itemPerPacket', parseInt(e.target.value))}
                        className="w-20 px-2 py-1 border border-gray-300 rounded text-sm"
                      />
                    </td>
                    <td className="px-4 py-3 text-sm">{item.poQuantity}</td>
                    <td className="px-4 py-3">
                      <input
                        type="number"
                        value={item.packQuantity}
                        onChange={(e) => handleItemChange(item.id, 'packQuantity', parseInt(e.target.value))}
                        className="w-20 px-2 py-1 border border-gray-300 rounded text-sm"
                      />
                    </td>
                    <td className="px-4 py-3">
                      <input
                        type="number"
                        value={item.receivedQuantity}
                        onChange={(e) => handleItemChange(item.id, 'receivedQuantity', parseInt(e.target.value))}
                        className="w-20 px-2 py-1 border border-gray-300 rounded text-sm"
                      />
                    </td>
                    <td className="px-4 py-3 text-sm">{item.remainingQuantity}</td>
                    <td className="px-4 py-3 text-sm">{item.totalBuyingPrice.toFixed(2)}</td>
                    <td className="px-4 py-3 text-sm">{item.unitBuyingPrice.toFixed(2)}</td>
                    <td className="px-4 py-3">
                      <input
                        type="number"
                        step="0.01"
                        value={item.advanceTaxPercent}
                        onChange={(e) => handleItemChange(item.id, 'advanceTaxPercent', parseFloat(e.target.value))}
                        className="w-20 px-2 py-1 border border-gray-300 rounded text-sm"
                      />
                    </td>
                    <td className="px-4 py-3 text-sm">{item.advanceTaxAmount}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Action Buttons */}
      {showForm && items.length > 0 && (
        <div className="flex justify-start gap-3">
          <button
            onClick={handleSave}
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
          >
            Save
          </button>
          <button
            onClick={() => {
              setShowForm(false);
              setSelectedPO('');
              setSelectedPODetails(null);
              setItems([]);
            }}
            className="px-6 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
          >
            Cancel
          </button>
        </div>
      )}

      {/* GRN List Table */}
      <div className="mt-8">
        <div className="flex justify-between items-center mb-4">
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-700">Show</span>
            <select
              value={entriesPerPage}
              onChange={(e) => setEntriesPerPage(Number(e.target.value))}
              className="px-3 py-1 border border-gray-300 rounded-md"
            >
              <option value={5}>5</option>
              <option value={10}>10</option>
              <option value={25}>25</option>
              <option value={50}>50</option>
            </select>
            <span className="text-sm text-gray-700">entries</span>
          </div>
          <div>
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search:"
              className="px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Invoice No</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">PO Number</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Stock Type</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date &Time</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Action</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {grns.length === 0 ? (
                <tr>
                  <td colSpan="5" className="px-6 py-4 text-center text-sm text-gray-500">
                    No data available in table
                  </td>
                </tr>
              ) : (
                grns.map((grn) => (
                  <tr key={grn.id}>
                    <td className="px-6 py-4 text-sm">{grn.invoiceNo || '-'}</td>
                    <td className="px-6 py-4 text-sm">{grn.poNumber || '-'}</td>
                    <td className="px-6 py-4 text-sm">{grn.stockTypeName || '-'}</td>
                    <td className="px-6 py-4 text-sm">
                      {grn.dateAndTime ? new Date(grn.dateAndTime).toLocaleString() : '-'}
                    </td>
                    <td className="px-6 py-4 text-sm">
                      <button onClick={() => handleDelete(grn.id)} className="text-red-600 hover:text-red-900">Delete</button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="flex flex-col gap-3 mt-4 md:flex-row md:items-center md:justify-between">
          <div className="text-sm text-gray-700">
            {totalCount === 0
              ? 'Showing 0 to 0 of 0 entries'
              : `Showing ${(currentPage - 1) * entriesPerPage + 1} to ${Math.min(currentPage * entriesPerPage, totalCount)} of ${totalCount} entries`}
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => setCurrentPage((p) => Math.max(p - 1, 1))}
              disabled={currentPage === 1}
              className="px-3 py-1 border border-gray-300 rounded-md text-sm disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Prev
            </button>
            <span className="text-sm text-gray-700">
              {currentPage} / {Math.max(1, Math.ceil(totalCount / entriesPerPage))}
            </span>
            <button
              type="button"
              onClick={() => setCurrentPage((p) => Math.min(p + 1, Math.max(1, Math.ceil(totalCount / entriesPerPage))))}
              disabled={currentPage >= Math.ceil(totalCount / entriesPerPage)}
              className="px-3 py-1 border border-gray-300 rounded-md text-sm disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Next
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default GRNPage;
