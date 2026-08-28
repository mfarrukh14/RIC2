import axios from 'axios';

const API_URL = 'http://10.10.10.35:5100/api/Store';

// GET /api/Store (dbo.SP_Pharmacy_AllStores, backed by Pharmacy.PharmacyStores) returns
// Id/Name/ParentId/ParentName/ImagePath/IsDisableRetailSale/DayClosingWise/etc - not the
// storeId/storeName/... names most pages' dropdowns, filters, and edit forms use (mirroring
// StoreCreateRequest/StoreUpdateRequest instead). Every one of those pages calls
// getAllStores() directly, so mapping is centralized here rather than duplicated per page -
// without it, store.storeName is undefined and dropdowns render blank/selectable-but-empty
// <option> rows instead of throwing (which is why it went unnoticed across ~20 pages).
const mapStoreFromApi = (store) => ({
  ...store,
  storeId: store.id,
  storeName: store.name,
  storeCode: store.storeCode ?? '',
  storeType: store.storeType ?? '',
  parentStoreId: store.parentId,
  parentStoreName: store.parentName,
  buildingName: store.buildingName,
  floorName: store.floorName,
  roomName: store.roomName,
  disableRetailSale: store.isDisableRetailSale,
  dayClosing: store.dayClosingWise,
  closingCashAccountId: store.dayClosingCashAccountId,
  closingRevenueAccountId: store.dayClosingRevenueAccountId,
  closingInventoryAccountId: store.dayClosingInventoryAccountId,
  closingInventoryExpenseAccountId: store.dayClosingInventoryExpenseAccountId,
  closingTaxExpenseAccountId: store.dayClosingTaxExpenseAccountId,
  storeImage: store.imagePath,
});

export const getAllStores = async () => {
  const response = await axios.get(API_URL);
  return (response.data || []).map(mapStoreFromApi);
};

export const getPharmacyStoreDropdown = async (branchId = 1) => {
  const response = await axios.post(`${API_URL}/pharmacy-store-dropdown`, { branchId });
  return response.data?.data ?? [];
};

export const getStoreLocationLookup = async () => {
  const response = await axios.get(`${API_URL}/location-lookup`);
  return response.data;
};

export const getStoreById = async (id) => {
  const response = await axios.get(`${API_URL}/${id}`);
  return response.data;
};

export const createStore = async (data) => {
  const response = await axios.post(API_URL, data);
  return response.data;
};

export const updateStore = async (id, data) => {
  const response = await axios.put(`${API_URL}/${id}`, data);
  return response.data;
};

export const deleteStore = async (id) => {
  const response = await axios.delete(`${API_URL}/${id}`);
  return response.data;
};
