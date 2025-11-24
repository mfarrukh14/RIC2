import axios from 'axios';

const API_URL = 'http://10.10.10.68:5000/api/itemtypesalelevels';

const itemTypeSaleLevelApi = {
  getAll: async () => {
    const response = await axios.get(API_URL);
    return response.data;
  },

  getById: async (id) => {
    const response = await axios.get(`${API_URL}/${id}`);
    return response.data;
  },

  create: async (data) => {
    const response = await axios.post(API_URL, data);
    return response.data;
  },

  update: async (id, data) => {
    const response = await axios.put(`${API_URL}/${id}`, data);
    return response.data;
  },

  delete: async (id) => {
    const response = await axios.delete(`${API_URL}/${id}`);
    return response.data;
  },

  getLookupData: async () => {
    const response = await axios.get(`${API_URL}/lookup`);
    return response.data;
  }
};

export default itemTypeSaleLevelApi;
