import React, { useState, useEffect } from 'react';
import { PencilIcon, TrashIcon, PlusIcon, ArrowDownTrayIcon } from '@heroicons/react/24/outline';
import stockTypeAssociationsApi from '../services/stockTypeAssociationsApi';
import Pagination from './Pagination';

const StockTypeAssociationList = ({ onEdit, onAdd }) => {
  const [associations, setAssociations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  const [filteredAssociations, setFilteredAssociations] = useState([]);

  useEffect(() => {
    loadAssociations();
  }, []);

  useEffect(() => {
    // Filter associations based on search term
    const filtered = associations.filter(assoc => 
      (assoc.storeName && assoc.storeName.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (assoc.stockTypeName && assoc.stockTypeName.toLowerCase().includes(searchTerm.toLowerCase()))
    );
    setFilteredAssociations(filtered);
    setCurrentPage(1); // Reset to first page when filtering
  }, [associations, searchTerm]);

  const loadAssociations = async () => {
    try {
      setLoading(true);
      const data = await stockTypeAssociationsApi.getAllStockTypeAssociations();
      setAssociations(data);
      setError(null);
    } catch (err) {
      setError('Failed to load stock type associations: ' + (err.response?.data || err.message));
      console.error('Error loading stock type associations:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this stock type association?')) {
      return;
    }

    try {
      await stockTypeAssociationsApi.deleteStockTypeAssociation(id);
      await loadAssociations(); // Refresh the list
    } catch (err) {
      setError('Failed to delete stock type association: ' + (err.response?.data?.message || err.response?.data || err.message));
      console.error('Error deleting stock type association:', err);
    }
  };

  const getPatientTypeName = (patientType) => {
    switch (patientType) {
      case 1:
        return 'Regular';
      case 2:
        return 'Entitle';
      case 3:
        return 'Panel';
      default:
        return 'Unknown';
    }
  };

  const handleExport = () => {
    // Create CSV content
    const headers = ['Store', 'Stock Types', 'Patient Types', 'Created On'];
    const csvContent = [
      headers.join(','),
      ...filteredAssociations.map(assoc => [
        `"${assoc.storeName || ''}"`,
        `"${assoc.stockTypeName || ''}"`,
        `"${getPatientTypeName(assoc.patientTypes)}"`,
        `"${new Date(assoc.createdOn).toLocaleString()}"`,
      ].join(','))
    ].join('\n');

    // Create and download file
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `stock_type_associations_${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
  };

  // Pagination calculations
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentAssociations = filteredAssociations.slice(startIndex, endIndex);

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
              <span className="text-blue-600">🔗</span>
              Stock Type Association
            </h2>
          </div>
          <div className="flex gap-2">
            <button
              onClick={handleExport}
              className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 flex items-center gap-2 transition-colors"
              disabled={filteredAssociations.length === 0}
            >
              <ArrowDownTrayIcon className="w-5 h-5" />
              Export
            </button>
            <button
              onClick={onAdd}
              className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2 transition-colors"
            >
              <PlusIcon className="w-5 h-5" />
              Add New
            </button>
          </div>
        </div>

        {/* Search and Controls */}
        <div className="mt-4 flex gap-4">
          <div className="flex-1">
            <input
              type="text"
              placeholder="Search..."
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
                Store
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Stock Types
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Patient Types
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Created On
              </th>
              <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                Action
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {currentAssociations.length === 0 ? (
              <tr>
                <td colSpan="6" className="px-6 py-8 text-center text-gray-500">
                  {searchTerm ? 'No stock type associations found matching your search.' : 'No stock type associations found. Click "Add New" to create one.'}
                </td>
              </tr>
            ) : (
              currentAssociations.map((assoc, index) => (
                <tr key={assoc.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {startIndex + index + 1}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{assoc.storeName || '-'}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{assoc.stockTypeName || '-'}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{getPatientTypeName(assoc.patientTypes)}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">
                      {new Date(assoc.createdOn).toLocaleDateString()} {new Date(assoc.createdOn).toLocaleTimeString()}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-center text-sm font-medium">
                    <button
                      onClick={() => onEdit(assoc)}
                      className="text-blue-600 hover:text-blue-900 mr-4"
                      title="Edit"
                    >
                      <PencilIcon className="w-5 h-5 inline" />
                    </button>
                    <button
                      onClick={() => handleDelete(assoc.id)}
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
        totalCount={filteredAssociations.length}
        onPageChange={setCurrentPage}
        onPageSizeChange={setItemsPerPage}
      />
    </div>
  );
};

export default StockTypeAssociationList;
