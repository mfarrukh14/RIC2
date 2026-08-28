// Encodes/decodes the itemId/medicineId/subServiceId triple used by unified
// Item+Medicine+Disposable pickers (see itemApi.getAllWithMedicines) into a
// single <select> option value, since exactly one of the three is set per row.
export const productOptionValue = (row) => {
  if (row.itemId != null) return `item-${row.itemId}`;
  if (row.medicineId != null) return `medicine-${row.medicineId}`;
  if (row.subServiceId != null) return `disposable-${row.subServiceId}`;
  return '';
};

export const parseProductOptionValue = (value) => {
  const [kind, idStr] = String(value || '').split('-');
  const id = idStr ? parseInt(idStr, 10) : null;
  return {
    itemId: kind === 'item' ? id : null,
    medicineId: kind === 'medicine' ? id : null,
    subServiceId: kind === 'disposable' ? id : null,
  };
};

export const findProductRow = (rows, { itemId, medicineId, subServiceId }) =>
  (rows || []).find((row) =>
    (itemId != null && row.itemId === itemId) ||
    (medicineId != null && row.medicineId === medicineId) ||
    (subServiceId != null && row.subServiceId === subServiceId)
  );

// Looks up a row's on-hand quantity in a StoreItemQuantities response
// ({ items, medicines, subServices }, see StocksController.GetQuantitiesByStore) -
// an ItemId, BranchMedicineId and BranchSubServiceId can all collide on the same
// integer, so the right bucket must be picked by the row's kind, not just its id.
export const quantityForProduct = (quantities, row) => {
  if (!quantities || !row) return 0;
  if (row.itemId != null) return quantities.items?.[row.itemId] ?? 0;
  if (row.medicineId != null) return quantities.medicines?.[row.medicineId] ?? 0;
  if (row.subServiceId != null) return quantities.subServices?.[row.subServiceId] ?? 0;
  return 0;
};
