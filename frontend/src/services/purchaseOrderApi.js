import api from './api';

const PURCHASE_ORDERS_BASE_URL = '/purchaseorders';

const purchaseOrderApi = {
  getAll: async (params = {}) => {
    const response = await api.get(PURCHASE_ORDERS_BASE_URL, { params });
    return response.data;
  },

  getById: async (id) => {
    const response = await api.get(`${PURCHASE_ORDERS_BASE_URL}/${id}`);
    return response.data;
  },

  create: async (payload) => {
    const response = await api.post(PURCHASE_ORDERS_BASE_URL, payload);
    return response.data;
  }
};

export default purchaseOrderApi;