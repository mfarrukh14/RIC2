import api from './api';

const returnInventoryApi = {
  // Get all return inventory records with filters
  getAll: async (filters = {}) => {
    const params = new URLSearchParams();

    if (filters.branchId) params.append('branchId', filters.branchId);
    if (filters.storeId) params.append('storeId', filters.storeId);
    if (filters.itemTypeId) params.append('itemTypeId', filters.itemTypeId);
    if (filters.startDate) params.append('startDate', filters.startDate);
    if (filters.endDate) params.append('endDate', filters.endDate);
    if (filters.purchaseOrderNo) params.append('purchaseOrderNo', filters.purchaseOrderNo);
    if (filters.itemId) params.append('itemId', filters.itemId);
    if (filters.inventoryNo) params.append('inventoryNo', filters.inventoryNo);

    const queryString = params.toString();
    const response = await api.get(`/returninventory${queryString ? `?${queryString}` : ''}`);
    return response.data;
  },

  // Get single return inventory by ID
  getById: async (id) => {
    const response = await api.get(`/returninventory/${id}`);
    return response.data;
  },

  // Create new return inventory - performs the actual stock deduction (and, if
  // a PO/Inventory number is supplied, the matching PO/GRN line deduction) server-side.
  create: async (data) => {
    const response = await api.post('/returninventory', data);
    return response.data;
  },

  // Update existing return inventory (header fields only)
  update: async (id, data) => {
    const response = await api.put(`/returninventory/${id}`, data);
    return response.data;
  },

  // Delete return inventory
  delete: async (id) => {
    const response = await api.delete(`/returninventory/${id}`);
    return response.data;
  },

  // Get lookup data for dropdowns (branches, active stores, active item types, vendors)
  getLookupData: async () => {
    const response = await api.get('/returninventory/lookup');
    return response.data;
  }
};

export default returnInventoryApi;
