import axios from 'axios';

const API_URL = 'http://10.10.10.35:5100/api/Store';

export const getAllStores = async () => {
  const response = await axios.get(API_URL);
  return response.data;
};

export const getPharmacyStoreDropdown = async (branchId = 1) => {
  const response = await axios.post(`${API_URL}/pharmacy-store-dropdown`, { branchId });
  return response.data?.data ?? [];
};

export const getStoreLocationLookup = async () => {
  const response = await axios.get(`${API_URL}/location-lookup`);
  return response.data;
};

export const getStoreById = async (id) => {
  const response = await axios.get(`${API_URL}/${id}`);
  return response.data;
};

export const createStore = async (data) => {
  const response = await axios.post(API_URL, data);
  return response.data;
};

export const updateStore = async (id, data) => {
  const response = await axios.put(`${API_URL}/${id}`, data);
  return response.data;
};

export const deleteStore = async (id) => {
  const response = await axios.delete(`${API_URL}/${id}`);
  return response.data;
};
