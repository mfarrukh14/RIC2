import axios from 'axios';

const API_URL = 'http://10.10.10.68:5000/api/Branch';

export const branchApi = {
    getAll: async () => {
        const response = await axios.get(API_URL);
        return response.data;
    }
};
