import axios from 'axios';

const API_BASE_URL = 'http://localhost:5000/api';

export const rackColumnApi = {
  getAll: async () => {
    const response = await axios.get(`${API_BASE_URL}/RackColumn`);
    return response.data;
  },

  getById: async (id) => {
    const response = await axios.get(`${API_BASE_URL}/RackColumn/${id}`);
    return response.data;
  },

  getByRackId: async (rackId) => {
    const response = await axios.get(`${API_BASE_URL}/RackColumn/byrack/${rackId}`);
    return response.data;
  },

  create: async (rackColumn) => {
    const response = await axios.post(`${API_BASE_URL}/RackColumn`, rackColumn);
    return response.data;
  },

  update: async (id, rackColumn) => {
    const response = await axios.put(`${API_BASE_URL}/RackColumn/${id}`, rackColumn);
    return response.data;
  },

  delete: async (id) => {
    const response = await axios.delete(`${API_BASE_URL}/RackColumn/${id}`);
    return response.data;
  },
};

export default rackColumnApi;
