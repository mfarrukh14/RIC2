import api from './api';

const PURCHASE_ORDER_STATUS_BASE_URL = '/purchaseorderstatuses';

const purchaseOrderStatusApi = {
  getAll: async () => {
    const response = await api.get(PURCHASE_ORDER_STATUS_BASE_URL);
    return response.data;
  },

  create: async (payload) => {
    const response = await api.post(PURCHASE_ORDER_STATUS_BASE_URL, payload);
    return response.data;
  },

  update: async (id, payload) => {
    const response = await api.put(`${PURCHASE_ORDER_STATUS_BASE_URL}/${id}`, payload);
    return response.data;
  }
};

export default purchaseOrderStatusApi;