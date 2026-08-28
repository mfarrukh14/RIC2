import axios from 'axios';
import { attachUserIdHeader } from './httpAuth';

const API_BASE_URL = 'http://localhost:5100/api'; // Backend is running on port 5100

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

attachUserIdHeader(api);

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

export const itemTypeApi = {
  // Get all item types
  getAll: async () => {
    const response = await api.get('/itemtypes');
    return response.data;
  },

  // Get item type by ID
  getById: async (id) => {
    const response = await api.get(`/itemtypes/${id}`);
    return response.data;
  },

  // Create new item type
  create: async (itemType) => {
    const response = await api.post('/itemtypes', itemType);
    return response.data;
  },

  // Update item type
  update: async (id, itemType) => {
    const response = await api.put(`/itemtypes/${id}`, itemType);
    return response.data;
  },

  // Delete item type
  delete: async (id) => {
    await api.delete(`/itemtypes/${id}`);
  },
};

export const brandApi = {
  // Get all brands
  getAll: async () => {
    const response = await api.get('/brands');
    return response.data;
  },

  // Get brand by ID
  getById: async (id) => {
    const response = await api.get(`/brands/${id}`);
    return response.data;
  },

  // Create new brand
  create: async (brand) => {
    const response = await api.post('/brands', brand);
    return response.data;
  },

  // Update brand
  update: async (id, brand) => {
    const response = await api.put(`/brands/${id}`, brand);
    return response.data;
  },

  // Delete brand
  delete: async (id) => {
    await api.delete(`/brands/${id}`);
  },
};

export default api;