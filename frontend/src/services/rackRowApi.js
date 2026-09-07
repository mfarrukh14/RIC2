import axios from 'axios';

const API_URL = 'http://10.10.10.35:5100/api';

export const rackRowApi = {
  getAll: async () => {
    const response = await axios.get(`${API_URL}/RackRow`);
    return response.data;
  },

  getById: async (id) => {
    const response = await axios.get(`${API_URL}/RackRow/${id}`);
    return response.data;
  },

  getByRackId: async (rackId) => {
    const response = await axios.get(`${API_URL}/RackRow/byrack/${rackId}`);
    return response.data;
  },

  create: async (rackRow) => {
    const response = await axios.post(`${API_URL}/RackRow`, rackRow);
    return response.data;
  },

  update: async (id, rackRow) => {
    const response = await axios.put(`${API_URL}/RackRow/${id}`, rackRow);
    return response.data;
  },

  delete: async (id) => {
    const response = await axios.delete(`${API_URL}/RackRow/${id}`);
    return response.data;
  },
};
