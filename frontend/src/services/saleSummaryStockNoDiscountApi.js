import axios from 'axios';

const API_URL = 'http://10.10.10.35:5100/api/SaleSummaryStockNoDiscount';

// Server-paginated - call shape matches usePagedList: { pageNumber, pageSize, ...filters } -> { items, totalCount }
export const getSaleSummaryStockNoDiscount = async ({ pageNumber, pageSize, store, startDate, endDate } = {}) => {
  try {
    const params = { pageNumber, pageSize };
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

// Always aggregates over the full filtered result server-side, independent of the list's
// current page - see SaleSummaryStockNoDiscountService.GetSaleSummaryStockNoDiscountTotalsAsync.
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
