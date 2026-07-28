import axios from 'axios';

const API_BASE_URL = 'http://localhost:5100/api';

export const rackRowApi = {
  getAll: async () => {
    const response = await axios.get(`${API_BASE_URL}/RackRow`);
    return response.data;
  },
  getByRackId: async (rackId) => {
    const response = await axios.get(`${API_BASE_URL}/RackRow/byrack/${rackId}`);
    return response.data;
  },
};

export const rackColumnApi = {
  getAll: async () => {
    const response = await axios.get(`${API_BASE_URL}/RackColumn`);
    return response.data;
  },
  getByRackId: async (rackId) => {
    const response = await axios.get(`${API_BASE_URL}/RackColumn/byrack/${rackId}`);
    return response.data;
  },
};
