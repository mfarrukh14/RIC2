import axios from 'axios';

const API_URL = 'http://localhost:5100/api/expiredstock';

export const getExpiredStock = async (filters = {}) => {
  const params = new URLSearchParams();
  
  if (filters.storeName) params.append('storeName', filters.storeName);
  if (filters.startDate) params.append('startDate', filters.startDate);
  if (filters.endDate) params.append('endDate', filters.endDate);
  if (filters.item) params.append('item', filters.item);
  if (filters.searchTerm) params.append('searchTerm', filters.searchTerm);
  if (filters.pageNumber) params.append('pageNumber', filters.pageNumber);
  if (filters.pageSize) params.append('pageSize', filters.pageSize);

  const response = await axios.get(`${API_URL}?${params.toString()}`);
  return response.data;
};
