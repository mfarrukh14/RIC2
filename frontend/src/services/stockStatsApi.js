const API_URL = 'http://10.10.10.35:5100/api';

export const stockStatsApi = {
    // Search stock stats - server-paginated, call shape matches usePagedList:
    // { pageNumber, pageSize, ...filters } -> { items, totalCount }
    searchStats: async ({ pageNumber, pageSize, ...filters }) => {
        const response = await fetch(`${API_URL}/stockstats/search`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ...filters, pageNumber, pageSize }),
        });

        if (!response.ok) {
            let message = 'Failed to search stock stats';
            try {
                const error = await response.json();
                message = error.message || message;
            } catch {
                // Response body wasn't JSON (e.g. a proxy/timeout error page) - fall
                // back to the generic message instead of throwing a raw parse error.
            }
            throw new Error(message);
        }

        return response.json();
    },
};
