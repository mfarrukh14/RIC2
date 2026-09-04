const API_URL = 'http://10.10.10.35:5100/api';

export const stockAuditApi = {
    // Get past stock audits (history list, matches the old system's Stock Audit list)
    getAll: async (filters = {}) => {
        const params = new URLSearchParams();
        if (filters.branchId) params.append('branchId', filters.branchId);
        if (filters.storeId) params.append('storeId', filters.storeId);
        if (filters.startDate) params.append('startDate', filters.startDate);
        if (filters.endDate) params.append('endDate', filters.endDate);

        const response = await fetch(`${API_URL}/stockaudits?${params.toString()}`);

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.message || 'Failed to fetch stock audits');
        }

        return response.json();
    },

    // Search stock audit items - server-paginated, call shape matches usePagedList:
    // { pageNumber, pageSize, ...filters } -> { items, totalCount }
    searchItems: async ({ pageNumber, pageSize, ...filters }) => {
        const response = await fetch(`${API_URL}/stockaudits/search`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ...filters, pageNumber, pageSize }),
        });

        if (!response.ok) {
            let message = 'Failed to search stock audit items';
            try {
                const error = await response.json();
                message = error.message || message;
            } catch {
                // Response body wasn't JSON (e.g. a proxy/timeout error page).
            }
            throw new Error(message);
        }

        return response.json();
    },

    // Create stock audit
    createAudit: async (auditData) => {
        const response = await fetch(`${API_URL}/stockaudits`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(auditData),
        });

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.message || 'Failed to create stock audit');
        }

        return response.json();
    },
};
