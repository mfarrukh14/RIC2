import axios from 'axios';

const API_URL = 'http://10.10.10.67:5100/api/SaleSummaryStockNoDiscount';

export const getSaleSummaryStockNoDiscount = async (store, startDate, endDate) => {
  try {
    const params = {};
    if (store) params.store = store;
    if (startDate) params.startDate = startDate;
    if (endDate) params.endDate = endDate;

    const response = await axios.get(API_URL, { params });
    return response.data;
  } catch (error) {
    console.error('Error fetching sale summary stock no discount:', error);
    throw error;
  }
};

export const getSaleSummaryStockNoDiscountTotals = async (store, startDate, endDate) => {
  try {
    const params = {};
    if (store) params.store = store;
    if (startDate) params.startDate = startDate;
    if (endDate) params.endDate = endDate;

    const response = await axios.get(`${API_URL}/totals`, { params });
    return response.data;
  } catch (error) {
    console.error('Error fetching sale summary stock no discount totals:', error);
    throw error;
  }
};
