import axios from 'axios';

const API_BASE_URL = 'http://localhost:5100/api';

const itemApi = {
  // CRUD operations
  getAll: async () => {
    const response = await axios.get(`${API_BASE_URL}/items`);
    return response.data;
  },

  getById: async (id) => {
    const response = await axios.get(`${API_BASE_URL}/items/${id}`);
    return response.data;
  },

  create: async (data) => {
    const response = await axios.post(`${API_BASE_URL}/items`, data);
    return response.data;
  },

  update: async (id, data) => {
    const response = await axios.put(`${API_BASE_URL}/items/${id}`, data);
    return response.data;
  },

  delete: async (id) => {
    const response = await axios.delete(`${API_BASE_URL}/items/${id}`);
    return response.data;
  },

  // Lookup data
  getCategories: async () => {
    const response = await axios.get(`${API_BASE_URL}/items/categories`);
    return response.data;
  },

  getSubCategories: async () => {
    const response = await axios.get(`${API_BASE_URL}/items/subcategories`);
    return response.data;
  },

  getPrices: async () => {
    const response = await axios.get(`${API_BASE_URL}/items/prices`);
    return response.data;
  },

  getTaxRates: async () => {
    const response = await axios.get(`${API_BASE_URL}/items/taxrates`);
    return response.data;
  },

  getTaxDescriptions: async () => {
    const response = await axios.get(`${API_BASE_URL}/items/taxdescriptions`);
    return response.data;
  },

  getTaxTypes: async () => {
    const response = await axios.get(`${API_BASE_URL}/items/taxtypes`);
    return response.data;
  },
};

export default itemApi;
