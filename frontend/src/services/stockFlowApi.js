import axios from 'axios';

const API_URL = 'http://10.10.10.35:5100/api/stockflow';

export const getStockFlow = async (filters = {}) => {
  const params = new URLSearchParams();
  
  if (filters.startDate) params.append('startDate', filters.startDate);
  if (filters.endDate) params.append('endDate', filters.endDate);
  if (filters.store) params.append('store', filters.store);
  if (filters.item) params.append('item', filters.item);
  if (filters.inventoryNo) params.append('inventoryNo', filters.inventoryNo);
  if (filters.challanNo) params.append('challanNo', filters.challanNo);
  if (filters.invoiceNo) params.append('invoiceNo', filters.invoiceNo);
  if (filters.demandRequestNo) params.append('demandRequestNo', filters.demandRequestNo);
  if (filters.pageNumber) params.append('pageNumber', filters.pageNumber);
  if (filters.pageSize) params.append('pageSize', filters.pageSize);

  const response = await axios.get(`${API_URL}?${params.toString()}`);
  return response.data;
};
