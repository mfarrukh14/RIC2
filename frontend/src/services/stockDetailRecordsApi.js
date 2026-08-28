import axios from 'axios';

const API_URL = 'http://10.10.10.35:5100/api/stockdetailrecords';

export const stockDetailRecordsApi = {
  getAll: async (params) => {
    const response = await axios.get(API_URL, { params });
    return response.data;
  }
};
