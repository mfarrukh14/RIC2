const API_URL = 'http://10.10.10.35:5100/api';

export const stockStatsApi = {
    // Search stock stats
    searchStats: async (searchData) => {
        const response = await fetch(`${API_URL}/stockstats/search`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(searchData),
        });

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.message || 'Failed to search stock stats');
        }

        return response.json();
    },
};
