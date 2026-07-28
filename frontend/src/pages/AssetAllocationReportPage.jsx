import React, { useState, useEffect } from 'react';
import { assetAllocationReportApi } from '../services/assetAllocationReportApi';
import { DocumentArrowDownIcon, MagnifyingGlassIcon } from '@heroicons/react/24/outline';
import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';

const AssetAllocationReportPage = () => {
  const [allocationType, setAllocationType] = useState('Room');
  const [filters, setFilters] = useState({
    startDate: '',
    endDate: '',
    allocationType: 'Room',
    roomId: null,
    userId: null,
    assetId: null,
    building: null,
    floor: null
  });

  const [lookupData, setLookupData] = useState({
    buildings: [],
    floors: [],
    rooms: [],
    users: [],
    assets: []
  });

  const [reportData, setReportData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchLookupData();
  }, []);

  useEffect(() => {
    if (filters.building) {
      fetchFloors(filters.building);
    } else {
      setLookupData(prev => ({ ...prev, floors: [] }));
    }
  }, [filters.building]);

  const fetchLookupData = async () => {
    try {
      const [buildings, rooms, users, assets] = await Promise.all([
        assetAllocationReportApi.getBuildings(),
        assetAllocationReportApi.getRooms(),
        assetAllocationReportApi.getUsers(),
        assetAllocationReportApi.getInventoryItems()
      ]);

      setLookupData({
        buildings,
        rooms,
        users,
        assets,
        floors: []
      });
    } catch (err) {
      setError('Failed to load filter options');
      console.error(err);
    }
  };

  const fetchFloors = async (building) => {
    try {
      const floors = await assetAllocationReportApi.getFloors(building);
      setLookupData(prev => ({ ...prev, floors }));
    } catch (err) {
      console.error('Failed to load floors:', err);
    }
  };

  const handleAllocationTypeChange = (type) => {
    setAllocationType(type);
    setFilters(prev => ({
      ...prev,
      allocationType: type,
      roomId: null,
      userId: null,
      building: null,
      floor: null
    }));
    setReportData([]);
  };

  const handleFilterChange = (field, value) => {
    setFilters(prev => ({ ...prev, [field]: value || null }));
  };

  const handleGenerateReport = async () => {
    setLoading(true);
    setError(null);

    try {
      const payload = {
        ...filters,
        startDate: filters.startDate || null,
        endDate: filters.endDate || null,
      };
      console.log('Generating report with filters:', payload);
      const data = await assetAllocationReportApi.getReport(payload);
      console.log('Report data received:', data);
      setReportData(data);
      if (data.length === 0) {
        setError('No data found for the selected filters');
      }
    } catch (err) {
      setError('Failed to generate report: ' + (err.response?.data?.message || err.message));
      console.error('Report generation error:', err);
    } finally {
      setLoading(false);
    }
  };

  const generatePDF = () => {
    try {
      console.log('Starting PDF generation with data:', reportData);
      
      if (!reportData || reportData.length === 0) {
        alert('No data available to generate PDF');
        return;
      }

      const doc = new jsPDF('l', 'mm', 'a4');
    
    // Header
    doc.setFontSize(16);
    doc.text('Rawalpindi Institute of Cardiology', 148.5, 15, { align: 'center' });
    doc.setFontSize(10);
    doc.text('Rawal Road Rawalpindi, Punjab, Pakistan', 148.5, 21, { align: 'center' });
    doc.text('Email: info@ric.gop.pk, Phone: 0519281111-9', 148.5, 26, { align: 'center' });
    
    doc.setFontSize(14);
    doc.text('Assets Allocation Report', 148.5, 35, { align: 'center' });
    
    // Date range and filters
    doc.setFontSize(9);
    const startDate = filters.startDate ? new Date(filters.startDate).toLocaleDateString() : '';
    const endDate = filters.endDate ? new Date(filters.endDate).toLocaleDateString() : '';
    const dateRange = startDate && endDate ? `From ${startDate} To ${endDate}` : 'All Dates';
    doc.text(`User: Mr. Branch Administrator`, 20, 42);
    doc.text(dateRange, 257, 42, { align: 'right' });
    
    // Filters info
    let filtersText = `Filters: Type: ${allocationType}`;
    if (allocationType === 'Room') {
      const selectedRoom = lookupData.rooms.find(r => r.id === parseInt(filters.roomId));
      filtersText += selectedRoom ? `, Room: ${selectedRoom.name}` : '';
      if (filters.building) filtersText += `, Building: ${filters.building}`;
      if (filters.floor) filtersText += `, Floor: ${filters.floor}`;
    } else {
      const selectedUser = lookupData.users.find(u => u.id === parseInt(filters.userId));
      if (selectedUser) {
        filtersText += `, User Name: ${selectedUser.name}`;
        if (selectedUser.department) filtersText += ` | ${selectedUser.designation || 'Staff'}`;
      }
    }
    
    doc.setFontSize(8);
    doc.text(filtersText, 20, 48);
    
    // Table
    const tableColumns = [
      { header: 'Sr.', dataKey: 'sr' },
      { header: 'Asset', dataKey: 'asset' },
      allocationType === 'User' ? { header: 'User Name', dataKey: 'userName' } : { header: 'Location', dataKey: 'location' },
      { header: 'Qty', dataKey: 'qty' },
      { header: 'Unit Price', dataKey: 'unitPrice' },
      { header: 'Total Price', dataKey: 'totalPrice' },
      { header: 'Alloc. Date', dataKey: 'allocDate' },
      { header: 'Alloc. No', dataKey: 'allocNo' }
    ];
    
    const tableData = reportData.map((item, index) => ({
      sr: index + 1,
      asset: item.assetName || 'N/A',
      userName: item.userName || 'N/A',
      location: item.roomName ? `${item.roomName}${item.building ? `, ${item.building}` : ''}${item.floor ? `, ${item.floor}` : ''}` : 'N/A',
      qty: item.quantity || 0,
      unitPrice: item.unitPrice ? `Rs. ${item.unitPrice.toLocaleString()}` : 'N/A',
      totalPrice: item.totalPrice ? `Rs. ${item.totalPrice.toLocaleString()}` : 'N/A',
      allocDate: item.allocatedDate ? new Date(item.allocatedDate).toLocaleDateString() : 'N/A',
      allocNo: item.allocationNo || 'N/A'
    }));
    
    autoTable(doc, {
      columns: tableColumns,
      body: tableData,
      startY: 52,
      styles: { fontSize: 8, cellPadding: 2 },
      headStyles: { fillColor: [41, 128, 185], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [245, 245, 245] },
      margin: { left: 10, right: 10 }
    });
    
    // Footer
    const pageCount = doc.internal.getNumberOfPages();
    for (let i = 1; i <= pageCount; i++) {
      doc.setPage(i);
      doc.setFontSize(8);
      doc.text(
        `${new Date().toLocaleDateString()} ${new Date().toLocaleTimeString()}`,
        20,
        doc.internal.pageSize.height - 10
      );
      doc.text(
        `Page ${i} of ${pageCount}`,
        doc.internal.pageSize.width - 30,
        doc.internal.pageSize.height - 10
      );
    }
    
    // Save
    doc.save(`asset-allocation-report-${Date.now()}.pdf`);
    console.log('PDF generated successfully');
    } catch (err) {
      console.error('Error generating PDF:', err);
      alert('Failed to generate PDF: ' + err.message);
    }
  };

  const getFilteredRooms = () => {
    let filtered = lookupData.rooms;
    if (filters.building) {
      filtered = filtered.filter(r => r.building === filters.building);
    }
    if (filters.floor) {
      filtered = filtered.filter(r => r.floor === filters.floor);
    }
    return filtered;
  };

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 mb-6">
          <div className="px-6 py-4 border-b border-gray-200">
            <h1 className="text-2xl font-semibold text-gray-900">Asset/Item Allocation Report</h1>
            <p className="mt-1 text-sm text-gray-600">
              Generate detailed reports for asset and item allocations
            </p>
          </div>
        </div>

        {/* Filters */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 mb-6">
          <div className="px-6 py-4">
            {/* Date Range */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">Date Range</label>
              <div className="flex gap-4">
                <input
                  type="date"
                  value={filters.startDate}
                  onChange={(e) => handleFilterChange('startDate', e.target.value)}
                  className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Start Date"
                />
                <span className="self-center text-gray-500">to</span>
                <input
                  type="date"
                  value={filters.endDate}
                  onChange={(e) => handleFilterChange('endDate', e.target.value)}
                  className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="End Date"
                />
              </div>
            </div>

            {/* Allocation Type */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">Allocation Type</label>
              <div className="flex gap-4">
                <label className="flex items-center">
                  <input
                    type="radio"
                    value="Room"
                    checked={allocationType === 'Room'}
                    onChange={(e) => handleAllocationTypeChange(e.target.value)}
                    className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
                  />
                  <span className="ml-2 text-sm text-gray-700">Room</span>
                </label>
                <label className="flex items-center">
                  <input
                    type="radio"
                    value="User"
                    checked={allocationType === 'User'}
                    onChange={(e) => handleAllocationTypeChange(e.target.value)}
                    className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
                  />
                  <span className="ml-2 text-sm text-gray-700">User</span>
                </label>
              </div>
            </div>

            {/* Room Filters */}
            {allocationType === 'Room' && (
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Building</label>
                  <select
                    value={filters.building || ''}
                    onChange={(e) => handleFilterChange('building', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="">Please Select</option>
                    {lookupData.buildings.map((building) => (
                      <option key={building} value={building}>{building}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Floor</label>
                  <select
                    value={filters.floor || ''}
                    onChange={(e) => handleFilterChange('floor', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    disabled={!filters.building}
                  >
                    <option value="">Please Select</option>
                    {lookupData.floors.map((floor) => (
                      <option key={floor} value={floor}>{floor}</option>
                    ))}
                  </select>
                  {!filters.building && (
                    <p className="mt-1 text-xs text-red-500">Please Select Building First</p>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Room</label>
                  <select
                    value={filters.roomId || ''}
                    onChange={(e) => handleFilterChange('roomId', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="">Please Select</option>
                    {getFilteredRooms().map((room) => (
                      <option key={room.id} value={room.id}>
                        {room.name} {room.building && `(${room.building})`}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            )}

            {/* User Filters */}
            {allocationType === 'User' && (
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">User</label>
                <select
                  value={filters.userId || ''}
                  onChange={(e) => handleFilterChange('userId', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="">All Users, Mr. Sajid Mahmoodd | Security Guard</option>
                  {lookupData.users.map((user) => (
                    <option key={user.id} value={user.id}>
                      {user.name} {user.designation && `| ${user.designation}`}
                    </option>
                  ))}
                </select>
              </div>
            )}

            {/* Asset Filter */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">Asset</label>
              <select
                value={filters.assetId || ''}
                onChange={(e) => handleFilterChange('assetId', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="">All Asset(s)</option>
                {lookupData.assets.map((asset) => (
                  <option key={asset.id} value={asset.id}>
                    {asset.name} {asset.serialNumber && `(${asset.serialNumber})`}
                  </option>
                ))}
              </select>
            </div>

            {/* Action Buttons */}
            <div className="flex gap-3">
              <button
                onClick={handleGenerateReport}
                disabled={loading}
                className="inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition-colors duration-200 disabled:opacity-50"
              >
                <MagnifyingGlassIcon className="h-5 w-5 mr-2" />
                {loading ? 'Generating...' : 'Generate Report'}
              </button>

              {reportData.length > 0 && (
                <button
                  onClick={generatePDF}
                  className="inline-flex items-center px-4 py-2 bg-green-600 text-white text-sm font-medium rounded-lg hover:bg-green-700 transition-colors duration-200"
                >
                  <DocumentArrowDownIcon className="h-5 w-5 mr-2" />
                  Export PDF
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Error Alert */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
            <div className="flex">
              <div className="ml-3">
                <h3 className="text-sm font-medium text-red-800">Error</h3>
                <div className="mt-2 text-sm text-red-700">{error}</div>
              </div>
            </div>
          </div>
        )}

        {/* Report Table */}
        {reportData.length > 0 && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Sr.
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Asset
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {allocationType === 'User' ? 'User Name' : 'Location'}
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Qty
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Unit Price
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Total Price
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Alloc. Date
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Alloc. No
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {reportData.map((item, index) => (
                    <tr key={item.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {index + 1}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-900">
                        {item.assetName || 'N/A'}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-900">
                        {allocationType === 'User' 
                          ? item.userName || 'N/A'
                          : item.roomName 
                            ? `${item.roomName}${item.building ? `, ${item.building}` : ''}${item.floor ? `, ${item.floor}` : ''}`
                            : 'N/A'
                        }
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {item.quantity || 0}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {item.unitPrice ? `Rs. ${item.unitPrice.toLocaleString()}` : 'N/A'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {item.totalPrice ? `Rs. ${item.totalPrice.toLocaleString()}` : 'N/A'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {item.allocatedDate ? new Date(item.allocatedDate).toLocaleDateString() : 'N/A'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {item.allocationNo || 'N/A'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {reportData.length === 0 && (
                <div className="text-center py-12">
                  <div className="text-gray-500">There are no items to display.</div>
                </div>
              )}
            </div>

            {/* Summary */}
            <div className="bg-gray-50 px-6 py-3 border-t border-gray-200">
              <div className="text-sm text-gray-700">
                Showing {reportData.length} of {reportData.length} entries
              </div>
            </div>
          </div>
        )}

        {/* Empty State */}
        {!loading && reportData.length === 0 && !error && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-12 text-center">
            <div className="text-gray-500">
              Select filters and click "Generate Report" to view allocation data
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default AssetAllocationReportPage;