import axios from 'axios';

const API_BASE_URL = 'http://localhost:5000/api';

const contingentBillsApi = {
  async getAll(filters = {}) {
    try {
      const params = new URLSearchParams();
      
      if (filters.budgetSetupId) params.append('budgetSetupId', filters.budgetSetupId);
      if (filters.vendorId) params.append('vendorId', filters.vendorId);
      if (filters.financialYearId) params.append('financialYearId', filters.financialYearId);
      if (filters.poType) params.append('purchaseOrderTypeId', filters.poType);
      if (filters.status) params.append('contingentBillStatusId', filters.status);
      if (filters.dateStart) params.append('dateStart', filters.dateStart);
      if (filters.dateEnd) params.append('dateEnd', filters.dateEnd);

      const response = await axios.get(`${API_BASE_URL}/contingentbills?${params.toString()}`);
      return response.data;
    } catch (error) {
      console.error('Error fetching contingent bills:', error);
      throw error;
    }
  },

  async getById(id) {
    try {
      const response = await axios.get(`${API_BASE_URL}/contingentbills/${id}`);
      return response.data;
    } catch (error) {
      console.error('Error fetching contingent bill:', error);
      throw error;
    }
  },

  async create(billData) {
    try {
      const response = await axios.post(`${API_BASE_URL}/contingentbills`, billData);
      return response.data;
    } catch (error) {
      console.error('Error creating contingent bill:', error);
      throw error;
    }
  },

  async update(id, billData) {
    try {
      const response = await axios.put(`${API_BASE_URL}/contingentbills/${id}`, billData);
      return response.data;
    } catch (error) {
      console.error('Error updating contingent bill:', error);
      throw error;
    }
  },

  async delete(id) {
    try {
      const response = await axios.delete(`${API_BASE_URL}/contingentbills/${id}`);
      return response.data;
    } catch (error) {
      console.error('Error deleting contingent bill:', error);
      throw error;
    }
  },

  async getLookupData() {
    try {
      const response = await axios.get(`${API_BASE_URL}/contingentbills/lookup`);
      return response.data;
    } catch (error) {
      console.error('Error fetching lookup data:', error);
      throw error;
    }
  }
};

export default contingentBillsApi;
