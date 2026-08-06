import api from './api';

const stockApi = {
  searchStocks: async (filters) => {
    const response = await api.post('/stocks/search', filters);
    return response.data;
  },

  getQuantitiesByStore: async (storeId) => {
    const response = await api.get(`/stocks/quantities-by-store/${storeId}`);
    return response.data;
  },

  updateMinimumPanicLevel: async (stockId, minimumPanicLevel) => {
    const response = await api.put(`/stocks/${stockId}/minimum-panic-level`, { minimumPanicLevel });
    return response.data;
  }
};

export default stockApi;
