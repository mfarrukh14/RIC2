import axios from 'axios';

const API_URL = 'http://10.10.10.35:5100/api';

export const spaceAllocationApi = {
  getAll: async () => {
    const response = await axios.get(`${API_URL}/SpaceAllocation`);
    return response.data;
  },

  getById: async (id) => {
    const response = await axios.get(`${API_URL}/SpaceAllocation/${id}`);
    return response.data;
  },

  create: async (allocation) => {
    const response = await axios.post(`${API_URL}/SpaceAllocation`, allocation);
    return response.data;
  },

  update: async (id, allocation) => {
    const response = await axios.put(`${API_URL}/SpaceAllocation/${id}`, allocation);
    return response.data;
  },

  delete: async (id) => {
    const response = await axios.delete(`${API_URL}/SpaceAllocation/${id}`);
    return response.data;
  },
};
