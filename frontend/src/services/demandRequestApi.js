import api from './api';

const DEMAND_REQUESTS_BASE_URL = '/demandrequests';

const demandRequestApi = {
  getAll: async (params = {}) => {
    const response = await api.get(DEMAND_REQUESTS_BASE_URL, { params });
    return response.data;
  },

  getById: async (id) => {
    const response = await api.get(`${DEMAND_REQUESTS_BASE_URL}/${id}`);
    return response.data;
  },

  getLifeCycle: async (id) => {
    const response = await api.get(`${DEMAND_REQUESTS_BASE_URL}/${id}/lifecycle`);
    return response.data;
  },

  getItemLogs: async (id) => {
    const response = await api.get(`${DEMAND_REQUESTS_BASE_URL}/${id}/itemlogs`);
    return response.data;
  },

  create: async (payload) => {
    const response = await api.post(DEMAND_REQUESTS_BASE_URL, payload);
    return response.data;
  },

  receive: async (id, payload) => {
    const response = await api.post(`${DEMAND_REQUESTS_BASE_URL}/${id}/receive`, payload);
    return response.data;
  },

  update: async (id, payload) => {
    const response = await api.put(`${DEMAND_REQUESTS_BASE_URL}/${id}`, payload);
    return response.data;
  },

  approve: async (id, payload) => {
    const response = await api.post(`${DEMAND_REQUESTS_BASE_URL}/${id}/approve`, payload);
    return response.data;
  },

  dispatch: async (id, payload) => {
    const response = await api.post(`${DEMAND_REQUESTS_BASE_URL}/${id}/dispatch`, payload);
    return response.data;
  },

  reject: async (id, payload) => {
    const response = await api.post(`${DEMAND_REQUESTS_BASE_URL}/${id}/reject`, payload);
    return response.data;
  }
};

export default demandRequestApi;