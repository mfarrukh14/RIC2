import React, { useState, useEffect } from 'react';
import { PencilIcon, TrashIcon, PlusIcon, ArrowDownTrayIcon } from '@heroicons/react/24/outline';
import { manufacturerApi } from '../services/manufacturerApi';
import Pagination from './Pagination';

const ManufacturerList = ({ onEdit, onAdd }) => {
  const [manufacturers, setManufacturers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  useEffect(() => {
    loadManufacturers();
  }, []);

  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, itemsPerPage]);

  const loadManufacturers = async () => {
    try {
      setLoading(true);
      const data = await manufacturerApi.getAll();
      setManufacturers(data);
      setError(null);
    } catch (err) {
      setError('Failed to load manufacturers: ' + (err.response?.data || err.message));
      console.error('Error loading manufacturers:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this manufacturer?')) {
      return;
    }

    try {
      await manufacturerApi.delete(id);
      await loadManufacturers(); // Refresh the list
    } catch (err) {
      setError('Failed to delete manufacturer: ' + (err.response?.data?.message || err.response?.data || err.message));
      console.error('Error deleting manufacturer:', err);
    }
  };

  // Filter manufacturers based on search term
  const filteredManufacturers = manufacturers.filter(manufacturer =>
    manufacturer.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (manufacturer.address && manufacturer.address.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (manufacturer.cNo && manufacturer.cNo.includes(searchTerm))
  );

  // Export functionality
  const handleExport = () => {
    const csvContent = [
      ['Name', 'Address', 'Contact No', 'Status', 'Created Date'].join(','),
      ...filteredManufacturers.map(manufacturer => [
        `"${manufacturer.name}"`,
        `"${manufacturer.address || 'N/A'}"`,
        `"${manufacturer.cNo || 'N/A'}"`,
        manufacturer.isActive ? 'Active' : 'Inactive',
        new Date(manufacturer.createdAt).toLocaleDateString()
      ].join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `manufacturers_${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
  };

  // Pagination calculations
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentManufacturers = filteredManufacturers.slice(startIndex, endIndex);

  if (loading) {
    return (
      <div className="flex justify-center items-center py-12">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <div className="bg-white shadow-sm rounded-lg">
      {/* Header */}
      <div className="px-6 py-4 border-b border-gray-200">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
              <span className="text-blue-600">🏭</span>
              Manufacturers
            </h2>
          </div>
          <div className="flex gap-2">
            <button
              onClick={handleExport}
              className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 flex items-center gap-2 transition-colors"
              disabled={filteredManufacturers.length === 0}
            >
              <ArrowDownTrayIcon className="w-5 h-5" />
              Export
            </button>
            <button
              onClick={onAdd}
              className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2 transition-colors"
            >
              <PlusIcon className="w-5 h-5" />
              Add Manufacturer
            </button>
          </div>
        </div>

        {/* Search and Controls */}
        <div className="mt-4 flex justify-end items-center">
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-700">Search:</span>
            <input
              type="text"
              placeholder="Search manufacturers..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>
      </div>

      {error && (
        <div className="mx-6 mt-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          <p>{error}</p>
          <button 
            onClick={loadManufacturers}
            className="mt-2 bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700"
          >
            Retry
          </button>
        </div>
      )}

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Name
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Address
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Contact No
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {currentManufacturers.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-6 py-8 text-center">
                  <div className="text-gray-500">
                    {filteredManufacturers.length === 0 && manufacturers.length > 0 ? (
                      <div>
                        <p className="text-lg mb-2">No manufacturers found matching your search.</p>
                        <button
                          onClick={() => setSearchTerm('')}
                          className="text-blue-600 hover:text-blue-800"
                        >
                          Clear search
                        </button>
                      </div>
                    ) : (
                      <div>
                        <p className="text-lg mb-4">No manufacturers found</p>
                        <button
                          onClick={onAdd}
                          className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 flex items-center gap-2 mx-auto"
                        >
                          <PlusIcon className="w-5 h-5" />
                          Add Your First Manufacturer
                        </button>
                      </div>
                    )}
                  </div>
                </td>
              </tr>
            ) : (
              currentManufacturers.map((manufacturer, index) => (
                <tr key={manufacturer.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div>
                      <div className="text-sm font-medium text-gray-900">{manufacturer.name}</div>
                      {manufacturer.cpName1 && (
                        <div className="text-sm text-gray-500">Contact: {manufacturer.cpName1}</div>
                      )}
                      {manufacturer.email && (
                        <div className="text-sm text-gray-500">{manufacturer.email}</div>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-sm text-gray-900">
                      {manufacturer.address && <div>{manufacturer.address}</div>}
                      {(manufacturer.city || manufacturer.country) && (
                        <div>
                          {manufacturer.city && manufacturer.country ? `${manufacturer.city}, ${manufacturer.country}` : manufacturer.city || manufacturer.country}
                        </div>
                      )}
                      {!manufacturer.address && !manufacturer.city && !manufacturer.country && (
                        <span className="text-gray-400">No address provided</span>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {manufacturer.cNo || 'N/A'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                        manufacturer.isActive
                          ? 'bg-green-100 text-green-800'
                          : 'bg-red-100 text-red-800'
                      }`}
                    >
                      {manufacturer.isActive ? '✓' : '✗'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div className="flex space-x-2">
                      <button
                        onClick={() => onEdit(manufacturer)}
                        className="text-blue-600 hover:text-blue-900 p-1 rounded hover:bg-blue-50"
                        title="Edit manufacturer"
                      >
                        <PencilIcon className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleDelete(manufacturer.id)}
                        className="text-red-600 hover:text-red-900 p-1 rounded hover:bg-red-50"
                        title="Delete manufacturer"
                      >
                        <TrashIcon className="w-4 h-4" />
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
        totalCount={filteredManufacturers.length}
        onPageChange={setCurrentPage}
        onPageSizeChange={setItemsPerPage}
      />
    </div>
  );
};

export default ManufacturerList;