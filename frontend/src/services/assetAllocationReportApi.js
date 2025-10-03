import axios from 'axios';

const API_BASE_URL = 'http://localhost:5000/api';

export const assetAllocationReportApi = {
  // Get report data
  getReport: async (filters) => {
    const response = await axios.post(`${API_BASE_URL}/assetallocations/report`, filters);
    return response.data;
  },

  // Get buildings
  getBuildings: async () => {
    const response = await axios.get(`${API_BASE_URL}/assetallocations/buildings`);
    return response.data;
  },

  // Get floors by building
  getFloors: async (building) => {
    const response = await axios.get(`${API_BASE_URL}/assetallocations/floors`, {
      params: { building }
    });
    return response.data;
  },

  // Get users (from asset allocations)
  getUsers: async () => {
    const response = await axios.get(`${API_BASE_URL}/assetallocations/users`);
    return response.data;
  },

  // Get rooms (from asset allocations)
  getRooms: async () => {
    const response = await axios.get(`${API_BASE_URL}/assetallocations/rooms`);
    return response.data;
  },

  // Get inventory items
  getInventoryItems: async () => {
    const response = await axios.get(`${API_BASE_URL}/assetallocations/inventory-items`);
    return response.data;
  }
};
