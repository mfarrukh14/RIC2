import axios from 'axios';

const API_URL = 'http://10.10.10.35:5100/api/SaleSummaryItemDiscount';

// Server-paginated, call shape matches usePagedList: { pageNumber, pageSize, ...filters } -> { items, totalCount }
export const getSaleSummaryItemDiscount = async ({ pageNumber, pageSize, store, startDate, endDate, item } = {}) => {
  try {
    const params = { pageNumber, pageSize };
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

export const getSaleSummaryItemDiscountTotals = async ({ store, startDate, endDate, item } = {}) => {
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
