import axios from 'axios';

const API_URL = 'http://10.10.10.35:5100/api/System';

// Debug utility: switches which database the whole backend process talks to.
// Global for every connected user, not per-session - see SystemController.
export const systemApi = {
  getCurrentDatabase: async () => {
    const response = await axios.get(`${API_URL}/database`);
    return response.data;
  },

  switchDatabase: async (database) => {
    const response = await axios.post(`${API_URL}/database`, { database });
    return response.data;
  }
};
