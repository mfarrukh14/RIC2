import React, { useState, useEffect } from 'react';
import { PencilIcon, TrashIcon, PlusIcon, ArrowDownTrayIcon } from '@heroicons/react/24/outline';
import { packingApi } from '../services/packingApi';

const PackingList = ({ onEdit, onAdd }) => {
  const [packings, setPackings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  useEffect(() => {
    loadPackings();
  }, []);

  const loadPackings = async () => {
    try {
      setLoading(true);
      const data = await packingApi.getAll();
      setPackings(data);
      setError(null);
    } catch (err) {
      setError('Failed to load packings: ' + (err.response?.data || err.message));
      console.error('Error loading packings:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this packing type?')) {
      return;
    }

    try {
      await packingApi.delete(id);
      await loadPackings(); // Refresh the list
    } catch (err) {
      setError('Failed to delete packing: ' + (err.response?.data || err.message));
      console.error('Error deleting packing:', err);
    }
  };

  // Filter packings based on search term
  const filteredPackings = packings.filter(packing =>
    packing.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (packing.description && packing.description.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  // Export functionality
  const handleExport = () => {
    const csvContent = [
      ['Name', 'Description', 'Pack', 'Leaf', 'Items Per Leaf', 'Status'].join(','),
      ...filteredPackings.map(packing => [
        `"${packing.name}"`,
        `"${packing.description || 'N/A'}"`,
        `"${packing.pack || 'N/A'}"`,
        `"${packing.leaf || 'N/A'}"`,
        `"${packing.numberOfItems || 'N/A'}"`,
        packing.isActive ? 'Active' : 'Inactive'
      ].join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `packings_${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
  };

  const handleItemsPerPageChange = (e) => {
    setItemsPerPage(parseInt(e.target.value));
    setCurrentPage(1);
  };

  // Pagination calculations
  const totalPages = Math.ceil(filteredPackings.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentPackings = filteredPackings.slice(startIndex, endIndex);

  const handlePageChange = (page) => {
    setCurrentPage(page);
  };

  const renderPagination = () => {
    const buttons = [];
    const maxButtons = 5;
    const halfMaxButtons = Math.floor(maxButtons / 2);

    let startPage = Math.max(1, currentPage - halfMaxButtons);
    let endPage = Math.min(totalPages, startPage + maxButtons - 1);

    if (endPage - startPage < maxButtons - 1) {
      startPage = Math.max(1, endPage - maxButtons + 1);
    }

    // Previous button
    if (currentPage > 1) {
      buttons.push(
        <button
          key="prev"
          onClick={() => handlePageChange(currentPage - 1)}
          className="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-l-md hover:bg-gray-50"
        >
          Previous
        </button>
      );
    }

    // Page number buttons
    for (let i = startPage; i <= endPage; i++) {
      buttons.push(
        <button
          key={i}
          onClick={() => handlePageChange(i)}
          className={`px-3 py-2 text-sm font-medium border ${
            i === currentPage
              ? 'bg-blue-50 border-blue-500 text-blue-600'
              : 'bg-white border-gray-300 text-gray-500 hover:bg-gray-50'
          }`}
        >
          {i}
        </button>
      );
    }

    // Next button
    if (currentPage < totalPages) {
      buttons.push(
        <button
          key="next"
          onClick={() => handlePageChange(currentPage + 1)}
          className="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-r-md hover:bg-gray-50"
        >
          Next
        </button>
      );
    }

    return buttons;
  };

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
              Packing Type
            </h2>
          </div>
          <div className="flex gap-2">
            <button
              onClick={handleExport}
              className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 flex items-center gap-2 transition-colors"
              disabled={filteredPackings.length === 0}
            >
              <ArrowDownTrayIcon className="w-5 h-5" />
              Export
            </button>
            <button
              onClick={onAdd}
              className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2 transition-colors"
            >
              <PlusIcon className="w-5 h-5" />
              Add Packing
            </button>
          </div>
        </div>

        {/* Search and Controls */}
        <div className="mt-4 flex justify-between items-center">
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <span className="text-sm text-gray-700">Show</span>
              <select
                value={itemsPerPage}
                onChange={handleItemsPerPageChange}
                className="border border-gray-300 rounded px-3 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value={5}>5</option>
                <option value={10}>10</option>
                <option value={25}>25</option>
                <option value={50}>50</option>
              </select>
              <span className="text-sm text-gray-700">entries</span>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-700">Search:</span>
            <input
              type="text"
              placeholder="Search packings..."
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
            onClick={loadPackings}
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
                Description
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Pack
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Leaf
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Items Per Leaf
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
            {currentPackings.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-6 py-8 text-center">
                  <div className="text-gray-500">
                    {filteredPackings.length === 0 && packings.length > 0 ? (
                      <div>
                        <p className="text-lg mb-2">No packings found matching your search.</p>
                        <button
                          onClick={() => setSearchTerm('')}
                          className="text-blue-600 hover:text-blue-800"
                        >
                          Clear search
                        </button>
                      </div>
                    ) : (
                      <div>
                        <p className="text-lg mb-4">No packing types found</p>
                        <button
                          onClick={onAdd}
                          className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 flex items-center gap-2 mx-auto"
                        >
                          <PlusIcon className="w-5 h-5" />
                          Add Your First Packing Type
                        </button>
                      </div>
                    )}
                  </div>
                </td>
              </tr>
            ) : (
              currentPackings.map((packing, index) => (
                <tr key={packing.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{packing.name}</div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-sm text-gray-900">
                      {packing.description || <span className="text-gray-400">No description</span>}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {packing.pack || 'N/A'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {packing.leaf || 'N/A'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {packing.numberOfItems || 'N/A'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                        packing.isActive
                          ? 'bg-green-100 text-green-800'
                          : 'bg-red-100 text-red-800'
                      }`}
                    >
                      {packing.isActive ? '✓' : '✗'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div className="flex space-x-2">
                      <button
                        onClick={() => onEdit(packing)}
                        className="text-blue-600 hover:text-blue-900 p-1 rounded hover:bg-blue-50"
                        title="Edit packing"
                      >
                        <PencilIcon className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleDelete(packing.id)}
                        className="text-red-600 hover:text-red-900 p-1 rounded hover:bg-red-50"
                        title="Delete packing"
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

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="px-6 py-4 border-t border-gray-200">
          <div className="flex justify-between items-center">
            <div className="text-sm text-gray-700">
              Showing {startIndex + 1} to {Math.min(endIndex, filteredPackings.length)} of {filteredPackings.length} entries
            </div>
            <div className="flex space-x-1">
              {renderPagination()}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default PackingList;