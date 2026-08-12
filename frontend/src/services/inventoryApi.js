import axios from 'axios';

const API_BASE_URL = 'http://10.10.10.35:5100/api';

const inventoryApi = {
  // Inventory header operations
  getAll: async (filters = {}) => {
    const params = new URLSearchParams();
    if (filters.searchTerm) params.append('searchTerm', filters.searchTerm);
    if (filters.vendorId) params.append('vendorId', filters.vendorId);
    if (filters.storeId) params.append('storeId', filters.storeId);
    if (filters.dateFrom) params.append('dateFrom', filters.dateFrom);
    if (filters.dateTo) params.append('dateTo', filters.dateTo);
    if (filters.pageNumber) params.append('pageNumber', filters.pageNumber);
    if (filters.pageSize) params.append('pageSize', filters.pageSize);

    const queryString = params.toString();
    const response = await axios.get(`${API_BASE_URL}/inventories${queryString ? `?${queryString}` : ''}`);
    return response.data;
  },

  getById: async (id) => {
    const response = await axios.get(`${API_BASE_URL}/inventories/${id}`);
    return response.data;
  },

  create: async (data) => {
    const response = await axios.post(`${API_BASE_URL}/inventories`, data);
    return response.data;
  },

  update: async (id, data) => {
    const response = await axios.put(`${API_BASE_URL}/inventories/${id}`, data);
    return response.data;
  },

  delete: async (id) => {
    const response = await axios.delete(`${API_BASE_URL}/inventories/${id}`);
    return response.data;
  },

  // Inventory detail operations
  createDetail: async (data) => {
    const response = await axios.post(`${API_BASE_URL}/inventories/details`, data);
    return response.data;
  },

  updateDetail: async (id, data) => {
    const response = await axios.put(`${API_BASE_URL}/inventories/details/${id}`, data);
    return response.data;
  },

  deleteDetail: async (id) => {
    const response = await axios.delete(`${API_BASE_URL}/inventories/details/${id}`);
    return response.data;
  },

  // Lookup data
  getLookupData: async () => {
    const response = await axios.get(`${API_BASE_URL}/inventories/lookup`);
    return response.data;
  },
};

export default inventoryApi;
