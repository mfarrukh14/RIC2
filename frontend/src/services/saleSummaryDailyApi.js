import axios from 'axios';

const API_URL = 'http://10.10.10.35:5100/api/SaleSummaryDaily';

export const getSaleSummary = async (store, startDate, endDate, type) => {
  try {
    const params = {};
    if (store) params.store = store;
    if (startDate) params.startDate = startDate;
    if (endDate) params.endDate = endDate;
    if (type) params.type = type;

    const response = await axios.get(API_URL, { params });
    return response.data;
  } catch (error) {
    console.error('Error fetching sale summary:', error);
    throw error;
  }
};

export const getSaleSummarySummary = async (store, startDate, endDate, type) => {
  try {
    const params = {};
    if (store) params.store = store;
    if (startDate) params.startDate = startDate;
    if (endDate) params.endDate = endDate;
    if (type) params.type = type;

    const response = await axios.get(`${API_URL}/summary`, { params });
    return response.data;
  } catch (error) {
    console.error('Error fetching sale summary totals:', error);
    throw error;
  }
};
