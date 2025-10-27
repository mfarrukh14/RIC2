import api from './api';

const stockApi = {
  searchStocks: async (filters) => {
    const response = await api.post('/stocks/search', filters);
    return response.data;
  }
};

export default stockApi;
