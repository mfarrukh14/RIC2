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
  },

  update: async (id, payload) => {
    await api.put(`${PURCHASE_ORDERS_BASE_URL}/${id}`, payload);
  },

  reject: async (id, remarks) => {
    await api.post(`${PURCHASE_ORDERS_BASE_URL}/${id}/reject`, { remarks });
  },

  getLog: async (id) => {
    const response = await api.get(`${PURCHASE_ORDERS_BASE_URL}/${id}/log`);
    return response.data;
  },

  getAttachments: async (id) => {
    const response = await api.get(`${PURCHASE_ORDERS_BASE_URL}/${id}/attachments`);
    return response.data;
  },

  uploadAttachment: async (id, file, title) => {
    const formData = new FormData();
    formData.append('file', file);
    if (title) {
      formData.append('title', title);
    }
    const response = await api.post(`${PURCHASE_ORDERS_BASE_URL}/${id}/attachments`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    });
    return response.data;
  },

  downloadAttachment: async (attachmentId, fileName) => {
    const response = await api.get(`${PURCHASE_ORDERS_BASE_URL}/attachments/${attachmentId}/download`, {
      responseType: 'blob'
    });
    const url = URL.createObjectURL(response.data);
    const link = document.createElement('a');
    link.href = url;
    link.download = fileName || 'attachment';
    link.click();
    URL.revokeObjectURL(url);
  },

  deleteAttachment: async (attachmentId) => {
    await api.delete(`${PURCHASE_ORDERS_BASE_URL}/attachments/${attachmentId}`);
  }
};

export default purchaseOrderApi;
