import api from './api';

const STOCK_TYPE_ASSOCIATIONS_BASE_URL = '/stocktypeassociations';

export const stockTypeAssociationsApi = {
  // Get all stock type associations
  getAllStockTypeAssociations: async () => {
    try {
      const response = await api.get(STOCK_TYPE_ASSOCIATIONS_BASE_URL);
      return response.data;
    } catch (error) {
      console.error('Error fetching stock type associations:', error);
      throw error;
    }
  },

  // Get stock type association by ID
  getStockTypeAssociationById: async (id) => {
    try {
      const response = await api.get(`${STOCK_TYPE_ASSOCIATIONS_BASE_URL}/${id}`);
      return response.data;
    } catch (error) {
      console.error(`Error fetching stock type association with ID ${id}:`, error);
      throw error;
    }
  },

  // Create new stock type association
  createStockTypeAssociation: async (associationData) => {
    try {
      const response = await api.post(STOCK_TYPE_ASSOCIATIONS_BASE_URL, associationData);
      return response.data;
    } catch (error) {
      console.error('Error creating stock type association:', error);
      throw error;
    }
  },

  // Update stock type association
  updateStockTypeAssociation: async (id, associationData) => {
    try {
      const response = await api.put(`${STOCK_TYPE_ASSOCIATIONS_BASE_URL}/${id}`, associationData);
      return response.data;
    } catch (error) {
      console.error(`Error updating stock type association with ID ${id}:`, error);
      throw error;
    }
  },

  // Delete stock type association
  deleteStockTypeAssociation: async (id) => {
    try {
      const response = await api.delete(`${STOCK_TYPE_ASSOCIATIONS_BASE_URL}/${id}`);
      return response.data;
    } catch (error) {
      console.error(`Error deleting stock type association with ID ${id}:`, error);
      throw error;
    }
  },
};

export default stockTypeAssociationsApi;
