import axios from 'axios';

const API_URL = 'http://10.10.10.35:5100/api/contingentbills';

export const contingentBillApi = {
  getAll: async (filters = {}) => {
    const params = new URLSearchParams();
    if (filters.budgetSetupId) params.append('budgetSetupId', filters.budgetSetupId);
    if (filters.vendorId) params.append('vendorId', filters.vendorId);
    if (filters.financialYearId) params.append('financialYearId', filters.financialYearId);
    if (filters.purchaseOrderTypeId) params.append('purchaseOrderTypeId', filters.purchaseOrderTypeId);
    if (filters.contingentBillStatusId) params.append('contingentBillStatusId', filters.contingentBillStatusId);
    if (filters.dateStart) params.append('dateStart', filters.dateStart);
    if (filters.dateEnd) params.append('dateEnd', filters.dateEnd);
    
    const response = await axios.get(`${API_URL}?${params.toString()}`);
    return response.data;
  },

  getById: async (id) => {
    const response = await axios.get(`${API_URL}/${id}`);
    return response.data;
  },

  create: async (data) => {
    const response = await axios.post(API_URL, data);
    return response.data;
  },

  update: async (id, data) => {
    const response = await axios.put(`${API_URL}/${id}`, data);
    return response.data;
  },

  delete: async (id) => {
    const response = await axios.delete(`${API_URL}/${id}`);
    return response.data;
  },

  getLookupData: async () => {
    const response = await axios.get(`${API_URL}/lookup`);
    return response.data;
  },
};
