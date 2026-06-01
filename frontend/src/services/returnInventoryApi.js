import axios from 'axios';

const API_BASE_URL = 'http://10.10.10.67:5100/api';

const returnInventoryApi = {
  // Get all return inventory records with filters
  getAll: async (filters = {}) => {
    const params = new URLSearchParams();
    
    if (filters.branchId) params.append('branchId', filters.branchId);
    if (filters.storeId) params.append('storeId', filters.storeId);
    if (filters.itemTypeId) params.append('itemTypeId', filters.itemTypeId);
    if (filters.itemType) params.append('itemType', filters.itemType);
    if (filters.startDate) params.append('startDate', filters.startDate);
    if (filters.endDate) params.append('endDate', filters.endDate);
    if (filters.purchaseOrderNo) params.append('purchaseOrderNo', filters.purchaseOrderNo);
    if (filters.itemId) params.append('itemId', filters.itemId);
    if (filters.inventoryNo) params.append('inventoryNo', filters.inventoryNo);
    
    const queryString = params.toString();
    const url = `${API_BASE_URL}/returninventory${queryString ? `?${queryString}` : ''}`;
    
    const response = await axios.get(url);
    return response.data;
  },

  // Get single return inventory by ID
  getById: async (id) => {
    const response = await axios.get(`${API_BASE_URL}/returninventory/${id}`);
    return response.data;
  },

  // Create new return inventory
  create: async (data) => {
    const response = await axios.post(`${API_BASE_URL}/returninventory`, data);
    return response.data;
  },

  // Update existing return inventory
  update: async (id, data) => {
    const response = await axios.put(`${API_BASE_URL}/returninventory/${id}`, data);
    return response.data;
  },

  // Delete return inventory
  delete: async (id) => {
    const response = await axios.delete(`${API_BASE_URL}/returninventory/${id}`);
    return response.data;
  },

  // Get lookup data for dropdowns
  getLookupData: async () => {
    const response = await axios.get(`${API_BASE_URL}/returninventory/lookup`);
    return response.data;
  }
};

export default returnInventoryApi;
