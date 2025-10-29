import axios from 'axios';

const API_URL = 'http://localhost:5000/api/SaleSummaryItemDiscount';

export const getSaleSummaryItemDiscount = async (store, startDate, endDate, item) => {
  try {
    const params = {};
    if (store) params.store = store;
    if (startDate) params.startDate = startDate;
    if (endDate) params.endDate = endDate;
    if (item) params.item = item;

    const response = await axios.get(API_URL, { params });
    return response.data;
  } catch (error) {
    console.error('Error fetching sale summary item discount:', error);
    throw error;
  }
};

export const getSaleSummaryItemDiscountTotals = async (store, startDate, endDate, item) => {
  try {
    const params = {};
    if (store) params.store = store;
    if (startDate) params.startDate = startDate;
    if (endDate) params.endDate = endDate;
    if (item) params.item = item;

    const response = await axios.get(`${API_URL}/totals`, { params });
    return response.data;
  } catch (error) {
    console.error('Error fetching sale summary item discount totals:', error);
    throw error;
  }
};
