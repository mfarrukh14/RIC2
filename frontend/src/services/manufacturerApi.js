import axios from 'axios';

const API_BASE_URL = 'http://localhost:5100/api'; // Backend is running on port 5100

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const manufacturerApi = {
  // Get all manufacturers
  getAll: async () => {
    const response = await api.get('/manufacturers');
    return response.data;
  },

  // Get manufacturer by ID
  getById: async (id) => {
    const response = await api.get(`/manufacturers/${id}`);
    return response.data;
  },

  // Create new manufacturer
  create: async (manufacturer) => {
    const response = await api.post('/manufacturers', manufacturer);
    return response.data;
  },

  // Update manufacturer
  update: async (id, manufacturer) => {
    const response = await api.put(`/manufacturers/${id}`, manufacturer);
    return response.data;
  },

  // Delete manufacturer
  delete: async (id) => {
    await api.delete(`/manufacturers/${id}`);
  },
};