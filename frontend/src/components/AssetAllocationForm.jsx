import React, { useState, useEffect } from "react";
import { ArrowLeftIcon } from "@heroicons/react/24/outline";
import { assetAllocationApi } from "../services/assetAllocationApi";

const AssetAllocationForm = ({ onBack, allocationToEdit }) => {
  const [formData, setFormData] = useState({
    remarks: "",
    allocatedDate: new Date().toISOString().split('T')[0],
    userId: "",
    roomId: "",
    quantity: 1,
    inventoryItemId: "",
    isReturn: false,
    returnDate: "",
    returnRemarks: "",
    isActive: true,
  });

  const [building, setBuilding] = useState("");
  const [floor, setFloor] = useState("");

  const [lookupData, setLookupData] = useState({
    users: [],
    rooms: [],
    buildings: [],
    floors: [],
    inventoryItems: []
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [allocationType, setAllocationType] = useState("Room"); // Room or User

  useEffect(() => {
    fetchLookupData();
    if (allocationToEdit) {
      setFormData({
        remarks: allocationToEdit.remarks || "",
        allocatedDate: allocationToEdit.allocatedDate ? allocationToEdit.allocatedDate.split('T')[0] : new Date().toISOString().split('T')[0],
        userId: allocationToEdit.userId || "",
        roomId: allocationToEdit.roomId || "",
        quantity: allocationToEdit.quantity || 1,
        inventoryItemId: allocationToEdit.inventoryItemId || "",
        isReturn: allocationToEdit.isReturn || false,
        returnDate: allocationToEdit.returnDate ? allocationToEdit.returnDate.split('T')[0] : "",
        returnRemarks: allocationToEdit.returnRemarks || "",
        isActive: allocationToEdit.isActive !== undefined ? allocationToEdit.isActive : true,
      });

      // Determine allocation type based on existing data
      if (allocationToEdit.userId) {
        setAllocationType("User");
      } else {
        setAllocationType("Room");
      }
    }
  }, [allocationToEdit]);

  // Once rooms are loaded, pre-select the Building/Floor filters to match the
  // allocation's existing room (edit mode) so the room stays visible in the list.
  useEffect(() => {
    if (allocationToEdit?.roomId && lookupData.rooms.length > 0) {
      const room = lookupData.rooms.find(r => r.id === allocationToEdit.roomId);
      if (room) {
        setBuilding(room.building || "");
        setFloor(room.floor || "");
      }
    }
  }, [allocationToEdit, lookupData.rooms]);

  useEffect(() => {
    if (building) {
      assetAllocationApi.getFloors(building)
        .then(floors => setLookupData(prev => ({ ...prev, floors })))
        .catch(() => setLookupData(prev => ({ ...prev, floors: [] })));
    } else {
      setLookupData(prev => ({ ...prev, floors: [] }));
    }
  }, [building]);

  const fetchLookupData = async () => {
    try {
      const [users, rooms, buildings, inventoryItems] = await Promise.all([
        assetAllocationApi.getUsers(),
        assetAllocationApi.getRooms(),
        assetAllocationApi.getBuildings(),
        assetAllocationApi.getAvailableInventoryItems()
      ]);

      setLookupData(prev => ({
        ...prev,
        users,
        rooms,
        buildings,
        inventoryItems
      }));
    } catch (err) {
      setError(err.message);
    }
  };

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  const handleBuildingChange = (e) => {
    setBuilding(e.target.value);
    setFloor("");
    setFormData(prev => ({ ...prev, roomId: "" }));
  };

  const handleFloorChange = (e) => {
    setFloor(e.target.value);
    setFormData(prev => ({ ...prev, roomId: "" }));
  };

  const getFilteredRooms = () => {
    let filtered = lookupData.rooms;
    if (building) filtered = filtered.filter(r => r.building === building);
    if (floor) filtered = filtered.filter(r => r.floor === floor);
    return filtered;
  };

  const handleAllocationTypeChange = (type) => {
    setAllocationType(type);
    // Clear opposite allocation fields
    if (type === "Room") {
      setFormData(prev => ({ ...prev, userId: "" }));
    } else {
      setFormData(prev => ({ ...prev, roomId: "" }));
      setBuilding("");
      setFloor("");
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      // Prepare data based on allocation type
      const submitData = {
        ...formData,
        // Clear unused fields based on allocation type
        userId: allocationType === "User" ? formData.userId || null : null,
        roomId: allocationType === "Room" ? formData.roomId || null : null,
        // Convert dates to proper format
        allocatedDate: new Date(formData.allocatedDate).toISOString(),
        returnDate: formData.returnDate ? new Date(formData.returnDate).toISOString() : null,
      };

      if (allocationToEdit) {
        await assetAllocationApi.update(allocationToEdit.id, submitData);
      } else {
        await assetAllocationApi.create(submitData);
      }
      onBack(); // Navigate back after successful save
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 mb-6">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex items-center">
              <button
                onClick={onBack}
                className="mr-4 p-2 text-gray-400 hover:text-gray-600 rounded-md hover:bg-gray-100"
              >
                <ArrowLeftIcon className="h-5 w-5" />
              </button>
              <div>
                <h1 className="text-2xl font-semibold text-gray-900">
                  {allocationToEdit ? "Edit Asset/Items Allocation" : "Add Asset/Items Allocation"}
                </h1>
                <p className="mt-1 text-sm text-gray-600">
                  {allocationToEdit
                    ? "Update the details of this allocation"
                    : "Create a new asset or item allocation"}
                </p>
              </div>
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

        {/* Form */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <form onSubmit={handleSubmit} className="p-6 space-y-6">
            
            {/* Allocation Type Selection */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-3">
                Allocation Type <span className="text-red-500">*</span>
              </label>
              <div className="flex space-x-4">
                <label className="flex items-center">
                  <input
                    type="radio"
                    name="allocationType"
                    value="Room"
                    checked={allocationType === "Room"}
                    onChange={(e) => handleAllocationTypeChange(e.target.value)}
                    className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
                  />
                  <span className="ml-2 text-sm text-gray-700">Room</span>
                </label>
                <label className="flex items-center">
                  <input
                    type="radio"
                    name="allocationType"
                    value="User"
                    checked={allocationType === "User"}
                    onChange={(e) => handleAllocationTypeChange(e.target.value)}
                    className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
                  />
                  <span className="ml-2 text-sm text-gray-700">User</span>
                </label>
              </div>
            </div>

            {/* Asset Selection */}
            <div>
              <label htmlFor="inventoryItemId" className="block text-sm font-medium text-gray-700 mb-2">
                Asset <span className="text-red-500">*</span>
              </label>
              <select
                id="inventoryItemId"
                name="inventoryItemId"
                value={formData.inventoryItemId}
                onChange={handleChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="">Select Asset</option>
                {lookupData.inventoryItems.map((item) => (
                  <option key={item.id} value={item.id}>
                    {item.name} {item.serialNumber ? `(${item.serialNumber})` : ''}
                  </option>
                ))}
              </select>
            </div>

            {/* Allocation Date */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label htmlFor="allocatedDate" className="block text-sm font-medium text-gray-700 mb-2">
                  Asset Allocated Date <span className="text-red-500">*</span>
                </label>
                <input
                  type="date"
                  id="allocatedDate"
                  name="allocatedDate"
                  value={formData.allocatedDate}
                  onChange={handleChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              <div>
                <label htmlFor="quantity" className="block text-sm font-medium text-gray-700 mb-2">
                  Quantity
                </label>
                <input
                  type="number"
                  id="quantity"
                  name="quantity"
                  value={formData.quantity}
                  onChange={handleChange}
                  min="1"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>

            {/* Conditional Fields Based on Allocation Type */}
            {allocationType === "Room" ? (
              <>
                {/* Building/Floor/Room Selection */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <div>
                    <label htmlFor="building" className="block text-sm font-medium text-gray-700 mb-2">
                      Building
                    </label>
                    <select
                      id="building"
                      name="building"
                      value={building}
                      onChange={handleBuildingChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    >
                      <option value="">Please Select</option>
                      {lookupData.buildings.map((b) => (
                        <option key={b} value={b}>{b}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label htmlFor="floor" className="block text-sm font-medium text-gray-700 mb-2">
                      Floor
                    </label>
                    <select
                      id="floor"
                      name="floor"
                      value={floor}
                      onChange={handleFloorChange}
                      disabled={!building}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    >
                      <option value="">Please Select</option>
                      {lookupData.floors.map((f) => (
                        <option key={f} value={f}>{f}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label htmlFor="roomId" className="block text-sm font-medium text-gray-700 mb-2">
                      Room <span className="text-red-500">*</span>
                    </label>
                    <select
                      id="roomId"
                      name="roomId"
                      value={formData.roomId}
                      onChange={handleChange}
                      required
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    >
                      <option value="">Please Select</option>
                      {getFilteredRooms().map((room) => (
                        <option key={room.id} value={room.id}>
                          {room.name} {room.building && room.floor ? `(${room.building}, ${room.floor})` : ''}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              </>
            ) : (
              <>
                {/* User Selection */}
                <div>
                  <label htmlFor="userId" className="block text-sm font-medium text-gray-700 mb-2">
                    User <span className="text-red-500">*</span>
                  </label>
                  <select
                    id="userId"
                    name="userId"
                    value={formData.userId}
                    onChange={handleChange}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="">Select User</option>
                    {lookupData.users.map((user) => (
                      <option key={user.id} value={user.id}>
                        {user.name} {user.department ? `(${user.department})` : ''}
                      </option>
                    ))}
                  </select>
                </div>
              </>
            )}

            {/* Description */}
            <div>
              <label htmlFor="remarks" className="block text-sm font-medium text-gray-700 mb-2">
                Description
              </label>
              <textarea
                id="remarks"
                name="remarks"
                value={formData.remarks}
                onChange={handleChange}
                rows={3}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Enter allocation description"
              />
            </div>

            {/* Return Information (for existing allocations) */}
            {allocationToEdit && (
              <>
                <div className="border-t pt-6">
                  <h3 className="text-lg font-medium text-gray-900 mb-4">Return Information</h3>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="flex items-center">
                        <input
                          type="checkbox"
                          name="isReturn"
                          checked={formData.isReturn}
                          onChange={handleChange}
                          className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        />
                        <span className="ml-2 text-sm font-medium text-gray-700">Mark as Returned</span>
                      </label>
                    </div>

                    {formData.isReturn && (
                      <div>
                        <label htmlFor="returnDate" className="block text-sm font-medium text-gray-700 mb-2">
                          Return Date
                        </label>
                        <input
                          type="date"
                          id="returnDate"
                          name="returnDate"
                          value={formData.returnDate}
                          onChange={handleChange}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                    )}
                  </div>

                  {formData.isReturn && (
                    <div className="mt-4">
                      <label htmlFor="returnRemarks" className="block text-sm font-medium text-gray-700 mb-2">
                        Return Remarks
                      </label>
                      <textarea
                        id="returnRemarks"
                        name="returnRemarks"
                        value={formData.returnRemarks}
                        onChange={handleChange}
                        rows={3}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        placeholder="Enter return remarks"
                      />
                    </div>
                  )}
                </div>
              </>
            )}

            {/* Actions */}
            <div className="flex justify-end space-x-3 pt-6 border-t border-gray-200">
              <button
                type="button"
                onClick={onBack}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-lg hover:bg-blue-700 focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? (
                  <div className="flex items-center">
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    {allocationToEdit ? "Updating..." : "Creating..."}
                  </div>
                ) : (
                  allocationToEdit ? "Update Allocation" : "Submit"
                )}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default AssetAllocationForm;