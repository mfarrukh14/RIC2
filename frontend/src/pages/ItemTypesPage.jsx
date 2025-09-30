import React, { useState } from 'react';
import ItemTypeList from '../components/ItemTypeList';
import ItemTypeForm from '../components/ItemTypeForm';

const ItemTypesPage = () => {
  const [showForm, setShowForm] = useState(false);
  const [editingItemType, setEditingItemType] = useState(null);

  const handleAdd = () => {
    setEditingItemType(null);
    setShowForm(true);
  };

  const handleEdit = (itemType) => {
    setEditingItemType(itemType);
    setShowForm(true);
  };

  const handleFormSave = () => {
    setShowForm(false);
    setEditingItemType(null);
  };

  const handleFormCancel = () => {
    setShowForm(false);
    setEditingItemType(null);
  };

  if (showForm) {
    return (
      <ItemTypeForm
        itemType={editingItemType}
        onSave={handleFormSave}
        onCancel={handleFormCancel}
        isEditing={!!editingItemType}
      />
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <ItemTypeList onAdd={handleAdd} onEdit={handleEdit} />
      </div>
    </div>
  );
};

export default ItemTypesPage;