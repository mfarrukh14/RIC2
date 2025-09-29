import axios from 'axios';

const API_BASE_URL = 'http://localhost:5000/api'; // Backend is running on port 5000

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const vendorApi = {
  // Get all vendors
  getAll: async () => {
    const response = await api.get('/vendors');
    return response.data;
  },

  // Get vendor by ID
  getById: async (id) => {
    const response = await api.get(`/vendors/${id}`);
    return response.data;
  },

  // Create new vendor
  create: async (vendor) => {
    const response = await api.post('/vendors', vendor);
    return response.data;
  },

  // Update vendor
  update: async (id, vendor) => {
    const response = await api.put(`/vendors/${id}`, vendor);
    return response.data;
  },

  // Delete vendor
  delete: async (id) => {
    await api.delete(`/vendors/${id}`);
  },
};

export default api;