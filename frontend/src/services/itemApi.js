import axios from 'axios';

const API_BASE_URL = 'http://10.10.10.35:5100/api';

const itemApi = {
  // CRUD operations
  getAll: async (filters = {}) => {
    const params = new URLSearchParams();
    if (filters.searchTerm) params.append('searchTerm', filters.searchTerm);
    if (filters.pageNumber) params.append('pageNumber', filters.pageNumber);
    if (filters.pageSize) params.append('pageSize', filters.pageSize);

    const queryString = params.toString();
    const response = await axios.get(`${API_BASE_URL}/items${queryString ? `?${queryString}` : ''}`);
    return response.data;
  },

  getById: async (id) => {
    const response = await axios.get(`${API_BASE_URL}/items/${id}`);
    return response.data;
  },

  // For callers that need every item as a plain array (lookup pickers, client-side
  // reports) rather than one page of the paginated list UI - loops the paginated
  // endpoint (server clamps pageSize to 200) until exhausted.
  getAllUnpaginated: async () => {
    const pageSize = 200;
    let pageNumber = 1;
    let all = [];
    let totalCount = Infinity;

    while (all.length < totalCount) {
      const data = await itemApi.getAll({ pageNumber, pageSize });
      const items = data.items || [];
      totalCount = data.totalCount || 0;
      all = all.concat(items);
      if (items.length === 0) {
        break;
      }
      pageNumber += 1;
    }

    return all;
  },

  // Unified Items + Medicines + Disposables lookup for transaction-entry
  // pickers (Stock Consumption, Stock Adjustment, GRN, Purchase Order,
  // Purchase Requisition, Demand Request). Each row has exactly one of
  // itemId/medicineId/subServiceId set - pass whichever is present back
  // when saving a line.
  getAllWithMedicines: async (search) => {
    const response = await axios.get(`${API_BASE_URL}/items/with-medicines`, {
      params: search ? { search } : undefined,
    });
    return response.data;
  },

  create: async (data) => {
    const response = await axios.post(`${API_BASE_URL}/items`, data);
    return response.data;
  },

  update: async (id, data) => {
    const response = await axios.put(`${API_BASE_URL}/items/${id}`, data);
    return response.data;
  },

  delete: async (id) => {
    const response = await axios.delete(`${API_BASE_URL}/items/${id}`);
    return response.data;
  },

  // Lookup data
  getCategories: async () => {
    const response = await axios.get(`${API_BASE_URL}/items/categories`);
    return response.data;
  },

  getSubCategories: async () => {
    const response = await axios.get(`${API_BASE_URL}/items/subcategories`);
    return response.data;
  },

  getPrices: async () => {
    const response = await axios.get(`${API_BASE_URL}/items/prices`);
    return response.data;
  },

  getTaxRates: async () => {
    const response = await axios.get(`${API_BASE_URL}/items/taxrates`);
    return response.data;
  },

  getTaxDescriptions: async () => {
    const response = await axios.get(`${API_BASE_URL}/items/taxdescriptions`);
    return response.data;
  },

  getTaxTypes: async () => {
    const response = await axios.get(`${API_BASE_URL}/items/taxtypes`);
    return response.data;
  },
};

export default itemApi;
