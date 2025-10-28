import axios from 'axios';

const API_URL = 'http://localhost:5000/api/stores';

export const getAllStores = async () => {
  const response = await axios.get(API_URL);
  return response.data;
};

export const getStoreById = async (id) => {
  const response = await axios.get(`${API_URL}/${id}`);
  return response.data;
};
