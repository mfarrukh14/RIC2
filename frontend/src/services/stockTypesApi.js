import api from './api';

const STOCK_TYPES_BASE_URL = '/stocktypes';

export const stockTypesApi = {
  // Get all stock types
  getAllStockTypes: async () => {
    try {
      const response = await api.get(STOCK_TYPES_BASE_URL);
      return response.data;
    } catch (error) {
      console.error('Error fetching stock types:', error);
      throw error;
    }
  },

  // Get stock type by ID
  getStockTypeById: async (id) => {
    try {
      const response = await api.get(`${STOCK_TYPES_BASE_URL}/${id}`);
      return response.data;
    } catch (error) {
      console.error(`Error fetching stock type with ID ${id}:`, error);
      throw error;
    }
  },

  // Create new stock type
  createStockType: async (stockTypeData) => {
    try {
      const response = await api.post(STOCK_TYPES_BASE_URL, stockTypeData);
      return response.data;
    } catch (error) {
      console.error('Error creating stock type:', error);
      throw error;
    }
  },

  // Update stock type
  updateStockType: async (id, stockTypeData) => {
    try {
      const response = await api.put(`${STOCK_TYPES_BASE_URL}/${id}`, stockTypeData);
      return response.data;
    } catch (error) {
      console.error(`Error updating stock type with ID ${id}:`, error);
      throw error;
    }
  },

  // Delete stock type
  deleteStockType: async (id) => {
    try {
      const response = await api.delete(`${STOCK_TYPES_BASE_URL}/${id}`);
      return response.data;
    } catch (error) {
      console.error(`Error deleting stock type with ID ${id}:`, error);
      throw error;
    }
  },
};

export default stockTypesApi;
