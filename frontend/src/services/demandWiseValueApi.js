import api from './api';

const demandWiseValueApi = {
  // Server-paginated: usePagedList calls this with { pageNumber, pageSize, ...filters }
  // and expects back { items, totalCount, totals }.
  getAll: async (params = {}) => {
    const response = await api.get('/demandwisevalue', { params });
    return response.data;
  }
};

export default demandWiseValueApi;