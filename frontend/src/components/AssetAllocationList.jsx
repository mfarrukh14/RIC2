import React, { useState, useEffect } from "react";
import { PlusIcon, PencilIcon, TrashIcon, ArrowPathIcon } from "@heroicons/react/24/outline";
import { assetAllocationApi } from "../services/assetAllocationApi";

const AssetAllocationList = ({ onAdd, onEdit }) => {
  const [allocations, setAllocations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState("");

  useEffect(() => {
    fetchAllocations();
  }, []);

  const fetchAllocations = async () => {
    try {
      setLoading(true);
      const data = await assetAllocationApi.getAll();
      setAllocations(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleAddAllocation = () => {
    onAdd();
  };

  const handleEditAllocation = (allocation) => {
    onEdit(allocation);
  };

  const handleDeleteAllocation = async (id) => {
    if (window.confirm("Are you sure you want to delete this asset allocation?")) {
      try {
        await assetAllocationApi.delete(id);
        await fetchAllocations();
      } catch (err) {
        setError(err.response?.data?.message || err.response?.data || err.message);
      }
    }
  };

  const handleReturnAsset = async (allocation) => {
    if (window.confirm("Are you sure you want to mark this asset as returned?")) {
      try {
        const updateData = {
          ...allocation,
          isReturn: true,
          returnDate: new Date().toISOString(),
          returnRemarks: "Asset returned"
        };
        await assetAllocationApi.update(allocation.id, updateData);
        await fetchAllocations();
      } catch (err) {
        setError(err.message);
      }
    }
  };

  const filteredAllocations = allocations.filter((allocation) =>
    (allocation.inventoryItemName && allocation.inventoryItemName.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (allocation.userName && allocation.userName.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (allocation.roomName && allocation.roomName.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (allocation.departmentName && allocation.departmentName.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  const formatDate = (dateString) => {
    if (!dateString) return "-";
    return new Date(dateString).toLocaleDateString();
  };

  const getStatusBadge = (allocation) => {
    if (allocation.isReturn) {
      return (
        <span className="inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">
          Returned
        </span>
      );
    }
    return (
      <span className="inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-800">
        Allocated
      </span>
    );
  };

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
                <h1 className="text-2xl font-semibold text-gray-900">Asset/Items Allocation</h1>
                <p className="mt-1 text-sm text-gray-600">
                  Manage asset and item allocations to users and rooms
                </p>
              </div>
              <button
                onClick={handleAddAllocation}
                className="inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition-colors duration-200"
              >
                <PlusIcon className="h-5 w-5 mr-2" />
                Add Asset/Items Allocation
              </button>
            </div>
          </div>

          {/* Search */}
          <div className="px-6 py-4">
            <div className="relative">
              <input
                type="text"
                placeholder="Search allocations..."
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

        {/* Allocations Table */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Asset Name
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    User Name
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Location
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Allocation Date
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Quantity
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Unit Price
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Total Price
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Remarks
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
                {filteredAllocations.map((allocation) => (
                  <tr key={allocation.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">
                        {allocation.inventoryItemName || "-"}
                      </div>
                      {allocation.serialNumber && (
                        <div className="text-sm text-gray-500">
                          SN: {allocation.serialNumber}
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">
                        {allocation.userName || "-"}
                      </div>
                      {allocation.userDepartment && (
                        <div className="text-sm text-gray-500">
                          {allocation.userDepartment}
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">
                        {allocation.roomName || allocation.departmentName || "-"}
                      </div>
                      {allocation.building && allocation.floor && (
                        <div className="text-sm text-gray-500">
                          {allocation.building}, {allocation.floor}
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {formatDate(allocation.allocatedDate)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {allocation.quantity}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {allocation.currentValue ? `Rs ${allocation.currentValue.toLocaleString()}` : "-"}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {allocation.currentValue ? `Rs ${(allocation.currentValue * allocation.quantity).toLocaleString()}` : "-"}
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900 max-w-xs truncate">
                        {allocation.remarks || "-"}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {getStatusBadge(allocation)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <div className="flex space-x-2">
                        <button
                          onClick={() => handleEditAllocation(allocation)}
                          className="text-blue-600 hover:text-blue-900 p-1 rounded-md hover:bg-blue-50"
                          title="Edit"
                        >
                          <PencilIcon className="h-4 w-4" />
                        </button>
                        {!allocation.isReturn && (
                          <button
                            onClick={() => handleReturnAsset(allocation)}
                            className="text-green-600 hover:text-green-900 p-1 rounded-md hover:bg-green-50"
                            title="Mark as Returned"
                          >
                            <ArrowPathIcon className="h-4 w-4" />
                          </button>
                        )}
                        <button
                          onClick={() => handleDeleteAllocation(allocation.id)}
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

            {filteredAllocations.length === 0 && (
              <div className="text-center py-12">
                <div className="text-gray-500">
                  {searchTerm ? "No allocations found matching your search." : "No allocations found."}
                </div>
              </div>
            )}
          </div>

          {/* Pagination */}
          <div className="bg-gray-50 px-6 py-3 border-t border-gray-200">
            <div className="flex items-center justify-between">
              <div className="text-sm text-gray-700">
                Showing {filteredAllocations.length} of {allocations.length} entries
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AssetAllocationList;