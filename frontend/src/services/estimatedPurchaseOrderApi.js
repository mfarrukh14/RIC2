import axios from 'axios';

const API_BASE_URL = 'http://localhost:5100/api';

const estimatedPurchaseOrderApi = {
  getAll: async (params = {}) => {
    const response = await axios.get(`${API_BASE_URL}/estimatedpurchaseorders`, { params });
    return response.data;
  }
};

export default estimatedPurchaseOrderApi;