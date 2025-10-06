import axios from 'axios';

const API_BASE_URL = 'http://localhost:5000/api';

const itemCategoryApi = {
  async getAll() {
    try {
      const response = await axios.get(`${API_BASE_URL}/items/categories`);
      return response.data;
    } catch (error) {
      console.error('Error fetching item categories:', error);
      throw error;
    }
  },

  async getById(id) {
    try {
      const response = await axios.get(`${API_BASE_URL}/items/categories/${id}`);
      return response.data;
    } catch (error) {
      console.error('Error fetching item category:', error);
      throw error;
    }
  },

  async create(categoryData) {
    try {
      const response = await axios.post(`${API_BASE_URL}/items/categories`, categoryData);
      return response.data;
    } catch (error) {
      console.error('Error creating item category:', error);
      throw error;
    }
  },

  async update(id, categoryData) {
    try {
      const response = await axios.put(`${API_BASE_URL}/items/categories/${id}`, categoryData);
      return response.data;
    } catch (error) {
      console.error('Error updating item category:', error);
      throw error;
    }
  },

  async delete(id) {
    try {
      const response = await axios.delete(`${API_BASE_URL}/items/categories/${id}`);
      return response.data;
    } catch (error) {
      console.error('Error deleting item category:', error);
      throw error;
    }
  }
};

export default itemCategoryApi;
