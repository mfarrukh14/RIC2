import api from './api';

const PURCHASE_ORDER_TYPE_BASE_URL = '/purchaseordertypes';

const purchaseOrderTypeApi = {
  getAll: async () => {
    const response = await api.get(PURCHASE_ORDER_TYPE_BASE_URL);
    return response.data;
  },

  create: async (payload) => {
    const response = await api.post(PURCHASE_ORDER_TYPE_BASE_URL, payload);
    return response.data;
  },

  update: async (id, payload) => {
    const response = await api.put(`${PURCHASE_ORDER_TYPE_BASE_URL}/${id}`, payload);
    return response.data;
  },

  delete: async (id) => {
    await api.delete(`${PURCHASE_ORDER_TYPE_BASE_URL}/${id}`);
  }
};

export default purchaseOrderTypeApi;