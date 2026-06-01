import axios from 'axios';

const API_BASE_URL = 'http://10.10.10.67:5100/api';

const vendorApi = {
  getAll: async () => {
    const response = await axios.get(`${API_BASE_URL}/vendors`);
    return response.data;
  },

  getById: async (id) => {
    const response = await axios.get(`${API_BASE_URL}/vendors/${id}`);
    return response.data;
  },

  create: async (data) => {
    const response = await axios.post(`${API_BASE_URL}/vendors`, data);
    return response.data;
  },

  update: async (id, data) => {
    const response = await axios.put(`${API_BASE_URL}/vendors/${id}`, data);
    return response.data;
  },

  delete: async (id) => {
    const response = await axios.delete(`${API_BASE_URL}/vendors/${id}`);
    return response.data;
  }
};

export default vendorApi;
