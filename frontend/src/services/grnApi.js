import axios from 'axios';

const API_BASE_URL = 'http://10.10.10.35:5100/api';

const grnApi = {
  getAll: async () => {
    const response = await axios.get(`${API_BASE_URL}/grn`);
    return response.data;
  },

  getById: async (id) => {
    const response = await axios.get(`${API_BASE_URL}/grn/${id}`);
    return response.data;
  },

  create: async (data) => {
    const response = await axios.post(`${API_BASE_URL}/grn`, data);
    return response.data;
  },

  update: async (id, data) => {
    const response = await axios.put(`${API_BASE_URL}/grn/${id}`, data);
    return response.data;
  },

  delete: async (id) => {
    const response = await axios.delete(`${API_BASE_URL}/grn/${id}`);
    return response.data;
  },

  getLookupData: async () => {
    const response = await axios.get(`${API_BASE_URL}/grn/lookup`);
    return response.data;
  }
};

export default grnApi;
