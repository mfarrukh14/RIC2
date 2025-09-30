import React, { useState, useEffect } from "react";
import { PlusIcon, PencilIcon, TrashIcon } from "@heroicons/react/24/outline";
import { itemUnitApi } from "../services/itemUnitApi";

const ItemUnitList = ({ onAdd, onEdit }) => {
  const [itemUnits, setItemUnits] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState("");

  useEffect(() => {
    fetchItemUnits();
  }, []);

  const fetchItemUnits = async () => {
    try {
      setLoading(true);
      const data = await itemUnitApi.getAll();
      setItemUnits(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleAddItemUnit = () => {
    onAdd();
  };

  const handleEditItemUnit = (itemUnit) => {
    onEdit(itemUnit);
  };

  const handleDeleteItemUnit = async (id) => {
    if (window.confirm("Are you sure you want to delete this item unit?")) {
      try {
        await itemUnitApi.delete(id);
        await fetchItemUnits();
      } catch (err) {
        setError(err.message);
      }
    }
  };

  const filteredItemUnits = itemUnits.filter((itemUnit) =>
    itemUnit.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (itemUnit.description && itemUnit.description.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 mb-6">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex justify-between items-center">
              <div>
                <h1 className="text-2xl font-semibold text-gray-900">Item Units</h1>
                <p className="mt-1 text-sm text-gray-600">
                  Manage units of measurement for inventory items
                </p>
              </div>
              <button
                onClick={handleAddItemUnit}
                className="inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition-colors duration-200"
              >
                <PlusIcon className="h-5 w-5 mr-2" />
                Add Item Unit
              </button>
            </div>
          </div>

          {/* Search */}
          <div className="px-6 py-4">
            <div className="relative">
              <input
                type="text"
                placeholder="Search item units..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-4 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
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

        {/* Item Units Table */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
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
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredItemUnits.map((itemUnit) => (
                  <tr key={itemUnit.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">
                        {itemUnit.name}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">
                        {itemUnit.description || "-"}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span
                        className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                          itemUnit.isActive
                            ? "bg-green-100 text-green-800"
                            : "bg-red-100 text-red-800"
                        }`}
                      >
                        {itemUnit.isActive ? "Active" : "Inactive"}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <div className="flex space-x-2">
                        <button
                          onClick={() => handleEditItemUnit(itemUnit)}
                          className="text-blue-600 hover:text-blue-900 p-1 rounded-md hover:bg-blue-50"
                          title="Edit"
                        >
                          <PencilIcon className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleDeleteItemUnit(itemUnit.id)}
                          className="text-red-600 hover:text-red-900 p-1 rounded-md hover:bg-red-50"
                          title="Delete"
                        >
                          <TrashIcon className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {filteredItemUnits.length === 0 && (
              <div className="text-center py-12">
                <div className="text-gray-500">
                  {searchTerm ? "No item units found matching your search." : "No item units found."}
                </div>
              </div>
            )}
          </div>

          {/* Pagination */}
          <div className="bg-gray-50 px-6 py-3 border-t border-gray-200">
            <div className="flex items-center justify-between">
              <div className="text-sm text-gray-700">
                Showing {filteredItemUnits.length} of {itemUnits.length} entries
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ItemUnitList;