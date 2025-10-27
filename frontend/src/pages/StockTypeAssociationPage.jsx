import React, { useState } from 'react';
import StockTypeAssociationList from '../components/StockTypeAssociationList';
import StockTypeAssociationForm from '../components/StockTypeAssociationForm';

const StockTypeAssociationPage = () => {
  const [showForm, setShowForm] = useState(false);
  const [editingAssociation, setEditingAssociation] = useState(null);

  const handleAdd = () => {
    setEditingAssociation(null);
    setShowForm(true);
  };

  const handleEdit = (association) => {
    setEditingAssociation(association);
    setShowForm(true);
  };

  const handleCloseForm = () => {
    setShowForm(false);
    setEditingAssociation(null);
  };

  const handleSave = () => {
    setShowForm(false);
    setEditingAssociation(null);
    // The list component will refresh automatically
  };

  return (
    <div className="p-6">
      {showForm ? (
        <StockTypeAssociationForm
          association={editingAssociation}
          onSave={handleSave}
          onCancel={handleCloseForm}
          isEditing={!!editingAssociation}
        />
      ) : (
        <StockTypeAssociationList
          onEdit={handleEdit}
          onAdd={handleAdd}
        />
      )}
    </div>
  );
};

export default StockTypeAssociationPage;
