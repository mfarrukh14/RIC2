import React, { useState, useEffect } from 'react';
import { FiSearch } from 'react-icons/fi';
import grnApi from '../services/grnApi';
import inventoryApi from '../services/inventoryApi';

const GRNPage = () => {
  const [grns, setGRNs] = useState([]);
  const [lookupData, setLookupData] = useState({
    vendors: [],
    stockTypes: [],
    manufacturers: []
  });
  
  // Form state
  const [showForm, setShowForm] = useState(false);
  const [selectedPO, setSelectedPO] = useState('');
  const [poSearchOptions, setPOSearchOptions] = useState([]);
  const [vendorInvoiceNo, setVendorInvoiceNo] = useState('');
  const [vendorInvoiceDate, setVendorInvoiceDate] = useState('');
  
  // Items from PO
  const [items, setItems] = useState([]);
  const [selectedItems, setSelectedItems] = useState([]);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const [grnsData, lookup, invLookup] = await Promise.all([
        grnApi.getAll(),
        grnApi.getLookupData(),
        inventoryApi.getLookupData()
      ]);
      
      setGRNs(grnsData);
      setLookupData({
        ...lookup,
        items: invLookup.items
      });
      
      // Generate PO search options (mock data for now)
      generatePOOptions();
    } catch (err) {
      console.error('Error fetching data:', err);
    }
  };

  const generatePOOptions = () => {
    // Mock PO options - in real scenario, fetch from backend
    const options = [
      'PO-0401AAA0370 [May 7 2024 8:52AM]',
      'PO-0401AAA0368 [7016/1-5/24] [May 7 2024 8:46AM]',
      'PO-0401AAA0367 [7004/1-3/24] [May 7 2024 8:44AM]',
      'PO-0401AAA0366 [7017/1-3/24] [May 7 2024 8:42AM]',
      'PO-0401AAA0365 [2922/1-3/24] [May 7 2024 8:39AM]',
      'PO-0401AAA0364 [2298/1-1/24] [Jan 9 2024 2:38PM]'
    ];
    setPOSearchOptions(options);
  };

  const handlePOSelect = (e) => {
    const poNumber = e.target.value;
    setSelectedPO(poNumber);
    
    if (poNumber) {
      // Mock: Load items for selected PO
      loadPOItems(poNumber);
    } else {
      setItems([]);
    }
  };

  const loadPOItems = (poNumber) => {
    // Mock items from PO
    const mockItems = [
      {
        id: 1,
        itemName: 'Exhaust Fan 12" SK fan the',
        manufacturer: '',
        mfgDate: '',
        expiryDate: '',
        registrationNumber: '',
        lotNo: '',
        batchNo: '',
        noOfBoxes: 1,
        noOfPackets: 1,
        itemPerPacket: 2,
        poQuantity: 2,
        packQuantity: 0,
        receivedQuantity: 0,
        remainingQuantity: 2,
        totalBuyingPrice: 18340.00,
        unitBuyingPrice: 7870.00,
        advanceTaxPercent: 0,
        advanceTaxAmount: 0
      }
    ];
    setItems(mockItems);
    setSelectedItems([1]); // Pre-select first item
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
    try {
      const selectedItemsData = items.filter(item => selectedItems.includes(item.id));
      
      const grnData = {
        poNumber: selectedPO.split(' ')[0],
        vendorId: 1, // Get from PO or form
        vendorInvoiceNo,
        vendorInvoiceDate: vendorInvoiceDate || null,
        stockTypeId: 1, // From form
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
      setItems([]);
      fetchData();
    } catch (err) {
      console.error('Error saving GRN:', err);
      alert('Failed to save GRN');
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
                {poSearchOptions.map((po, index) => (
                  <option key={index} value={po}>
                    {po}
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
            <select className="px-3 py-1 border border-gray-300 rounded-md">
              <option>10</option>
              <option>25</option>
              <option>50</option>
            </select>
            <span className="text-sm text-gray-700">entries</span>
          </div>
          <div>
            <input
              type="text"
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
                    Showing 0 to 0 of 0 entries
                  </td>
                </tr>
              ) : (
                grns.map((grn) => (
                  <tr key={grn.id}>
                    <td className="px-6 py-4 text-sm">{grn.invoiceNo || '-'}</td>
                    <td className="px-6 py-4 text-sm">{grn.poNumber}</td>
                    <td className="px-6 py-4 text-sm">{grn.stockTypeName || '-'}</td>
                    <td className="px-6 py-4 text-sm">
                      {grn.dateAndTime ? new Date(grn.dateAndTime).toLocaleString() : '-'}
                    </td>
                    <td className="px-6 py-4 text-sm">
                      <button className="text-blue-600 hover:text-blue-900 mr-3">Edit</button>
                      <button className="text-red-600 hover:text-red-900">Delete</button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default GRNPage;
