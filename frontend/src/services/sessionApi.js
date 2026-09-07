import axios from 'axios';

const API_URL = 'http://localhost:5100/api/Session';

export const sessionApi = {
    // isLogin=1 under the hood - caches the user's data on the server
    login: async (userId) => {
        const response = await axios.post(API_URL, { userId: Number(userId), isLogin: 1 });
        return response.data;
    },

    // isLogin=0 under the hood - clears the cached data on the server
    logout: async (userId) => {
        const response = await axios.post(API_URL, { userId: Number(userId), isLogin: 0 });
        return response.data;
    },

    getSession: async (userId) => {
        const response = await axios.get(`${API_URL}/${userId}`);
        return response.data;
    }
};
