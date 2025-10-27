import api from './api';

const STOCK_EXPIRING_BASE_URL = '/stockexpiring';

export const stockExpiringApi = {
  // Search for expiring stock with filters
  searchExpiringStock: async (filters) => {
    try {
      const response = await api.post(`${STOCK_EXPIRING_BASE_URL}/search`, filters);
      return response.data;
    } catch (error) {
      console.error('Error searching expiring stock:', error);
      throw error;
    }
  },
};

export default stockExpiringApi;
