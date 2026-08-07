import axios from 'axios';

const API_BASE_URL = 'http://10.10.10.35:5100/api';

const purchaseSummaryApi = {
  // Get all purchase summary records with filters
  getAll: async (filters = {}) => {
    const params = new URLSearchParams();
    
    if (filters.branchId) params.append('branchId', filters.branchId);
    if (filters.storeId) params.append('storeId', filters.storeId);
    if (filters.itemTypeId) params.append('itemTypeId', filters.itemTypeId);
    if (filters.itemType) params.append('itemType', filters.itemType);
    if (filters.invoiceDateStart) params.append('invoiceDateStart', filters.invoiceDateStart);
    if (filters.invoiceDateEnd) params.append('invoiceDateEnd', filters.invoiceDateEnd);
    if (filters.inventoryDateStart) params.append('inventoryDateStart', filters.inventoryDateStart);
    if (filters.inventoryDateEnd) params.append('inventoryDateEnd', filters.inventoryDateEnd);
    if (filters.itemId) params.append('itemId', filters.itemId);
    if (filters.invoiceNo) params.append('invoiceNo', filters.invoiceNo);
    if (filters.reportType) params.append('reportType', filters.reportType);
    
    const queryString = params.toString();
    const url = `${API_BASE_URL}/purchasesummary${queryString ? `?${queryString}` : ''}`;
    
    const response = await axios.get(url);
    return response.data;
  },

  // Get single purchase summary by ID
  getById: async (id) => {
    const response = await axios.get(`${API_BASE_URL}/purchasesummary/${id}`);
    return response.data;
  },

  // Create new purchase summary
  create: async (data) => {
    const response = await axios.post(`${API_BASE_URL}/purchasesummary`, data);
    return response.data;
  },

  // Update existing purchase summary
  update: async (id, data) => {
    const response = await axios.put(`${API_BASE_URL}/purchasesummary/${id}`, data);
    return response.data;
  },

  // Delete purchase summary
  delete: async (id) => {
    const response = await axios.delete(`${API_BASE_URL}/purchasesummary/${id}`);
    return response.data;
  },

  // Get lookup data for dropdowns
  getLookupData: async () => {
    const response = await axios.get(`${API_BASE_URL}/purchasesummary/lookup`);
    return response.data;
  }
};

export default purchaseSummaryApi;
