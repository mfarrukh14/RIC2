import React, { useState } from 'react';
import ItemUnitList from '../components/ItemUnitList';
import ItemUnitForm from '../components/ItemUnitForm';

const ItemUnitsPage = () => {
  const [showForm, setShowForm] = useState(false);
  const [editingItemUnit, setEditingItemUnit] = useState(null);

  const handleAdd = () => {
    setEditingItemUnit(null);
    setShowForm(true);
  };

  const handleEdit = (itemUnit) => {
    setEditingItemUnit(itemUnit);
    setShowForm(true);
  };

  const handleFormSave = () => {
    setShowForm(false);
    setEditingItemUnit(null);
  };

  const handleFormCancel = () => {
    setShowForm(false);
    setEditingItemUnit(null);
  };

  if (showForm) {
    return (
      <ItemUnitForm
        itemUnitToEdit={editingItemUnit}
        onBack={handleFormCancel}
      />
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <ItemUnitList onAdd={handleAdd} onEdit={handleEdit} />
      </div>
    </div>
  );
};

export default ItemUnitsPage;