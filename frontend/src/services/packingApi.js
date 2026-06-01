import axios from 'axios';

const API_BASE_URL = 'http://10.10.10.67:5100/api'; // Backend is running on port 5100

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const packingApi = {
  // Get all packings
  getAll: async () => {
    const response = await api.get('/packings');
    return response.data;
  },

  // Get packing by ID
  getById: async (id) => {
    const response = await api.get(`/packings/${id}`);
    return response.data;
  },

  // Create new packing
  create: async (packing) => {
    const response = await api.post('/packings', packing);
    return response.data;
  },

  // Update packing
  update: async (id, packing) => {
    const response = await api.put(`/packings/${id}`, packing);
    return response.data;
  },

  // Delete packing
  delete: async (id) => {
    await api.delete(`/packings/${id}`);
  },
};