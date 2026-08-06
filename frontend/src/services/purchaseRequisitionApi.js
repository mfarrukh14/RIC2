import api from './api';

const BASE_URL = '/purchaserequisitions';

const purchaseRequisitionApi = {
  getAll: async (params = {}) => {
    const response = await api.get(BASE_URL, { params });
    return response.data;
  },

  getById: async (id) => {
    const response = await api.get(`${BASE_URL}/${id}`);
    return response.data;
  },

  getLifeCycle: async (id) => {
    const response = await api.get(`${BASE_URL}/${id}/lifecycle`);
    return response.data;
  },

  create: async (payload) => {
    const response = await api.post(BASE_URL, payload);
    return response.data;
  },

  forward: async (id, payload) => {
    const response = await api.post(`${BASE_URL}/${id}/forward`, payload);
    return response.data;
  },

  changeStatus: async (id, payload) => {
    const response = await api.post(`${BASE_URL}/${id}/status`, payload);
    return response.data;
  },

  getFinancialYears: async () => {
    const response = await api.get(`${BASE_URL}/lookups/financial-years`);
    return response.data;
  },

  getBudgetHeads: async () => {
    const response = await api.get(`${BASE_URL}/lookups/budget-heads`);
    return response.data;
  }
};

export default purchaseRequisitionApi;
