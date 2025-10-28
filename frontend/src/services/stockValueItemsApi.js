import axios from 'axios';

const API_URL = 'http://localhost:5000/api/stockvalueitems';

export const stockValueItemsApi = {
  getAll: async (params) => {
    const response = await axios.get(API_URL, { params });
    return response.data;
  },

  getGRNReport: async (batchNo, itemName) => {
    const response = await axios.get(`${API_URL}/report`, {
      params: { batchNo, itemName }
    });
    return response.data;
  }
};
