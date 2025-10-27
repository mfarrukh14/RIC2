import api from './api';

const racksApi = {
  getAllRacks: async () => {
    const response = await api.get('/racks');
    return response.data;
  },

  getRackById: async (id) => {
    const response = await api.get(`/racks/${id}`);
    return response.data;
  },

  createRack: async (rackData) => {
    const response = await api.post('/racks', rackData);
    return response.data;
  },

  updateRack: async (id, rackData) => {
    const response = await api.put(`/racks/${id}`, rackData);
    return response.data;
  },

  deleteRack: async (id) => {
    const response = await api.delete(`/racks/${id}`);
    return response.data;
  }
};

export default racksApi;
