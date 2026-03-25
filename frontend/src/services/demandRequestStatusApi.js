import api from './api';

const DEMAND_REQUEST_STATUS_BASE_URL = '/demandrequeststatuses';

const demandRequestStatusApi = {
  getAll: async () => {
    const response = await api.get(DEMAND_REQUEST_STATUS_BASE_URL);
    return response.data;
  },

  create: async (payload) => {
    const response = await api.post(DEMAND_REQUEST_STATUS_BASE_URL, payload);
    return response.data;
  },

  update: async (id, payload) => {
    const response = await api.put(`${DEMAND_REQUEST_STATUS_BASE_URL}/${id}`, payload);
    return response.data;
  }
};

export default demandRequestStatusApi;