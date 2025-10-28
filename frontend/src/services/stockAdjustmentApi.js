import api from './api';

const stockAdjustmentApi = {
  getAll: async (filters = {}) => {
    const params = new URLSearchParams();
    if (filters.branchId) params.append('branchId', filters.branchId);
    if (filters.storeId) params.append('storeId', filters.storeId);
    if (filters.startDate) params.append('startDate', filters.startDate);
    if (filters.endDate) params.append('endDate', filters.endDate);
    
    const response = await api.get(`/stockadjustments?${params.toString()}`);
    return response.data;
  },

  getById: async (id) => {
    const response = await api.get(`/stockadjustments/${id}`);
    return response.data;
  },

  create: async (data) => {
    const response = await api.post('/stockadjustments', data);
    return response.data;
  },

  update: async (id, data) => {
    const response = await api.put(`/stockadjustments/${id}`, data);
    return response.data;
  },

  delete: async (id) => {
    const response = await api.delete(`/stockadjustments/${id}`);
    return response.data;
  }
};

export default stockAdjustmentApi;
