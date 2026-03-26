import api from './api';

const demandWiseValueApi = {
  getAll: async (params = {}) => {
    const response = await api.get('/demandwisevalue', { params });
    return response.data;
  }
};

export default demandWiseValueApi;