import React, { useState } from 'react';
import StockTypeList from '../components/StockTypeList';
import StockTypeForm from '../components/StockTypeForm';

const StockTypePage = () => {
  const [showStockTypeForm, setShowStockTypeForm] = useState(false);
  const [editingStockType, setEditingStockType] = useState(null);

  const handleAddStockType = () => {
    setEditingStockType(null);
    setShowStockTypeForm(true);
  };

  const handleEditStockType = (stockType) => {
    setEditingStockType(stockType);
    setShowStockTypeForm(true);
  };

  const handleCloseStockTypeForm = () => {
    setShowStockTypeForm(false);
    setEditingStockType(null);
  };

  const handleSaveStockType = () => {
    setShowStockTypeForm(false);
    setEditingStockType(null);
    // The StockTypeList component will refresh automatically
  };

  return (
    <div className="p-6">
      {showStockTypeForm ? (
        <StockTypeForm
          stockType={editingStockType}
          onSave={handleSaveStockType}
          onCancel={handleCloseStockTypeForm}
          isEditing={!!editingStockType}
        />
      ) : (
        <StockTypeList
          onEdit={handleEditStockType}
          onAdd={handleAddStockType}
        />
      )}
    </div>
  );
};

export default StockTypePage;
