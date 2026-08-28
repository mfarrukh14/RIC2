import axios from 'axios';

const API_BASE_URL = 'http://localhost:5100/api';

const transferInventoryApi = {
  getAll: async (filters = {}) => {
    const params = new URLSearchParams();
    if (filters.searchTerm) params.append('searchTerm', filters.searchTerm);
    if (filters.pageNumber) params.append('pageNumber', filters.pageNumber);
    if (filters.pageSize) params.append('pageSize', filters.pageSize);

    const queryString = params.toString();
    const response = await axios.get(`${API_BASE_URL}/transferinventory${queryString ? `?${queryString}` : ''}`);
    return response.data;
  },

  getById: async (id) => {
    const response = await axios.get(`${API_BASE_URL}/transferinventory/${id}`);
    return response.data;
  },

  create: async (data) => {
    const response = await axios.post(`${API_BASE_URL}/transferinventory`, data);
    return response.data;
  },

  update: async (id, data) => {
    const response = await axios.put(`${API_BASE_URL}/transferinventory/${id}`, data);
    return response.data;
  },

  delete: async (id) => {
    const response = await axios.delete(`${API_BASE_URL}/transferinventory/${id}`);
    return response.data;
  },

  getLookupData: async () => {
    const response = await axios.get(`${API_BASE_URL}/transferinventory/lookup`);
    return response.data;
  },

  getAvailableQuantity: async (storeId, itemId) => {
    const response = await axios.get(`${API_BASE_URL}/transferinventory/available-quantity`, {
      params: { storeId, itemId }
    });
    return response.data.quantity;
  }
};

export default transferInventoryApi;
