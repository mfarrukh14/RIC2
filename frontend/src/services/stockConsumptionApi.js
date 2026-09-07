import axios from 'axios';

const API_URL = 'http://10.10.10.35:5100/api/stockconsumptions';

export const getAllStockConsumptions = async (filters = {}) => {
  const response = await axios.get(API_URL, { params: filters });
  return response.data;
};

export const getStockConsumptionById = async (id) => {
  const response = await axios.get(`${API_URL}/${id}`);
  return response.data;
};

export const createStockConsumption = async (data) => {
  const response = await axios.post(API_URL, data);
  return response.data;
};

export const updateStockConsumption = async (id, data) => {
  const response = await axios.put(`${API_URL}/${id}`, data);
  return response.data;
};

export const deleteStockConsumption = async (id) => {
  const response = await axios.delete(`${API_URL}/${id}`);
  return response.data;
};
