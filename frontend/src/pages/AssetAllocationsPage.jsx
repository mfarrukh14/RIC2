import React, { useState } from 'react';
import AssetAllocationList from '../components/AssetAllocationList';
import AssetAllocationForm from '../components/AssetAllocationForm';

const AssetAllocationsPage = () => {
  const [showForm, setShowForm] = useState(false);
  const [editingAllocation, setEditingAllocation] = useState(null);

  const handleAdd = () => {
    setEditingAllocation(null);
    setShowForm(true);
  };

  const handleEdit = (allocation) => {
    setEditingAllocation(allocation);
    setShowForm(true);
  };

  const handleFormCancel = () => {
    setShowForm(false);
    setEditingAllocation(null);
  };

  if (showForm) {
    return (
      <AssetAllocationForm
        allocationToEdit={editingAllocation}
        onBack={handleFormCancel}
      />
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <AssetAllocationList onAdd={handleAdd} onEdit={handleEdit} />
      </div>
    </div>
  );
};

export default AssetAllocationsPage;