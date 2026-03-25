import axios from 'axios';

const API_BASE_URL = 'http://localhost:5100/api';

const purchaseSummaryInvoiceApi = {
  // Get all purchase summary invoice records with filters
  getAll: async (filters = {}) => {
    const params = new URLSearchParams();
    
    if (filters.branchId) params.append('branchId', filters.branchId);
    if (filters.storeId) params.append('storeId', filters.storeId);
    if (filters.inventoryDateStart) params.append('inventoryDateStart', filters.inventoryDateStart);
    if (filters.inventoryDateEnd) params.append('inventoryDateEnd', filters.inventoryDateEnd);
    if (filters.vendorId) params.append('vendorId', filters.vendorId);
    if (filters.invoiceDateStart) params.append('invoiceDateStart', filters.invoiceDateStart);
    if (filters.invoiceDateEnd) params.append('invoiceDateEnd', filters.invoiceDateEnd);
    if (filters.invoiceNo) params.append('invoiceNo', filters.invoiceNo);
    if (filters.reportType) params.append('reportType', filters.reportType);
    if (filters.invoiceType) params.append('invoiceType', filters.invoiceType);
    
    const queryString = params.toString();
    const url = `${API_BASE_URL}/purchasesummaryinvoice${queryString ? `?${queryString}` : ''}`;
    
    const response = await axios.get(url);
    return response.data;
  },

  // Get single purchase summary invoice by ID
  getById: async (id) => {
    const response = await axios.get(`${API_BASE_URL}/purchasesummaryinvoice/${id}`);
    return response.data;
  },

  // Create new purchase summary invoice
  create: async (data) => {
    const response = await axios.post(`${API_BASE_URL}/purchasesummaryinvoice`, data);
    return response.data;
  },

  // Update existing purchase summary invoice
  update: async (id, data) => {
    const response = await axios.put(`${API_BASE_URL}/purchasesummaryinvoice/${id}`, data);
    return response.data;
  },

  // Delete purchase summary invoice
  delete: async (id) => {
    const response = await axios.delete(`${API_BASE_URL}/purchasesummaryinvoice/${id}`);
    return response.data;
  },

  // Get lookup data for dropdowns
  getLookupData: async () => {
    const response = await axios.get(`${API_BASE_URL}/purchasesummaryinvoice/lookup`);
    return response.data;
  }
};

export default purchaseSummaryInvoiceApi;
