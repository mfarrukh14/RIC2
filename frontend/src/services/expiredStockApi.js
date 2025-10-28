import axios from 'axios';

const API_URL = 'http://localhost:5000/api/expiredstock';

export const getExpiredStock = async (filters = {}) => {
  const params = new URLSearchParams();
  
  if (filters.storeName) params.append('storeName', filters.storeName);
  if (filters.startDate) params.append('startDate', filters.startDate);
  if (filters.endDate) params.append('endDate', filters.endDate);
  if (filters.item) params.append('item', filters.item);

  const response = await axios.get(`${API_URL}?${params.toString()}`);
  return response.data;
};
