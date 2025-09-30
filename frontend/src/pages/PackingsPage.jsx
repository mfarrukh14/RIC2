import React, { useState } from 'react';
import PackingList from '../components/PackingList';
import PackingForm from '../components/PackingForm';

const PackingsPage = () => {
  const [showForm, setShowForm] = useState(false);
  const [editingPacking, setEditingPacking] = useState(null);

  const handleAdd = () => {
    setEditingPacking(null);
    setShowForm(true);
  };

  const handleEdit = (packing) => {
    setEditingPacking(packing);
    setShowForm(true);
  };

  const handleFormSave = () => {
    setShowForm(false);
    setEditingPacking(null);
  };

  const handleFormCancel = () => {
    setShowForm(false);
    setEditingPacking(null);
  };

  if (showForm) {
    return (
      <PackingForm
        packing={editingPacking}
        onSave={handleFormSave}
        onCancel={handleFormCancel}
        isEditing={!!editingPacking}
      />
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <PackingList onAdd={handleAdd} onEdit={handleEdit} />
      </div>
    </div>
  );
};

export default PackingsPage;