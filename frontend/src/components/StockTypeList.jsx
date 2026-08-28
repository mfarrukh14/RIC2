import React, { useState, useEffect } from 'react';
import { PencilIcon, TrashIcon, PlusIcon, ArrowDownTrayIcon } from '@heroicons/react/24/outline';
import stockTypesApi from '../services/stockTypesApi';
import Pagination from './Pagination';

const StockTypeList = ({ onEdit, onAdd }) => {
  const [stockTypes, setStockTypes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  const [filteredStockTypes, setFilteredStockTypes] = useState([]);

  useEffect(() => {
    loadStockTypes();
  }, []);

  useEffect(() => {
    // Filter stock types based on search term
    const filtered = stockTypes.filter(stockType => 
      stockType.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (stockType.description && stockType.description.toLowerCase().includes(searchTerm.toLowerCase()))
    );
    setFilteredStockTypes(filtered);
    setCurrentPage(1); // Reset to first page when filtering
  }, [stockTypes, searchTerm]);

  const loadStockTypes = async () => {
    try {
      setLoading(true);
      const data = await stockTypesApi.getAllStockTypes();
      setStockTypes(data);
      setError(null);
    } catch (err) {
      setError('Failed to load stock types: ' + (err.response?.data || err.message));
      console.error('Error loading stock types:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this stock type?')) {
      return;
    }

    try {
      await stockTypesApi.deleteStockType(id);
      await loadStockTypes(); // Refresh the list
    } catch (err) {
      setError('Failed to delete stock type: ' + (err.response?.data?.message || err.response?.data || err.message));
      console.error('Error deleting stock type:', err);
    }
  };

  const handleExport = () => {
    // Create CSV content
    const headers = ['Name', 'Description'];
    const csvContent = [
      headers.join(','),
      ...filteredStockTypes.map(stockType => [
        `"${stockType.name}"`,
        `"${stockType.description || ''}"`,
      ].join(','))
    ].join('\n');

    // Create and download file
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `stock_types_${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
  };

  // Pagination calculations
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentStockTypes = filteredStockTypes.slice(startIndex, endIndex);

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
              <span className="text-blue-600">📦</span>
              Stock Types
            </h2>
          </div>
          <div className="flex gap-2">
            <button
              onClick={handleExport}
              className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 flex items-center gap-2 transition-colors"
              disabled={filteredStockTypes.length === 0}
            >
              <ArrowDownTrayIcon className="w-5 h-5" />
              Export
            </button>
            <button
              onClick={onAdd}
              className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2 transition-colors"
            >
              <PlusIcon className="w-5 h-5" />
              Add Stock Type
            </button>
          </div>
        </div>

        {/* Search and Controls */}
        <div className="mt-4 flex gap-4">
          <div className="flex-1">
            <input
              type="text"
              placeholder="Search stock types..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="px-6 py-4 bg-red-50 border-b border-red-200">
          <p className="text-red-600">{error}</p>
        </div>
      )}

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Sr No
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Name
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Description
              </th>
              <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {currentStockTypes.length === 0 ? (
              <tr>
                <td colSpan="4" className="px-6 py-8 text-center text-gray-500">
                  {searchTerm ? 'No stock types found matching your search.' : 'No stock types found. Click "Add Stock Type" to create one.'}
                </td>
              </tr>
            ) : (
              currentStockTypes.map((stockType, index) => (
                <tr key={stockType.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {startIndex + index + 1}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{stockType.name}</div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-sm text-gray-500">{stockType.description || '-'}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-center text-sm font-medium">
                    <button
                      onClick={() => onEdit(stockType)}
                      className="text-blue-600 hover:text-blue-900 mr-4"
                      title="Edit"
                    >
                      <PencilIcon className="w-5 h-5 inline" />
                    </button>
                    <button
                      onClick={() => handleDelete(stockType.id)}
                      className="text-red-600 hover:text-red-900"
                      title="Delete"
                    >
                      <TrashIcon className="w-5 h-5 inline" />
                    </button>
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
        totalCount={filteredStockTypes.length}
        onPageChange={setCurrentPage}
        onPageSizeChange={setItemsPerPage}
      />
    </div>
  );
};

export default StockTypeList;
