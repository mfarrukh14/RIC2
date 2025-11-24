const API_URL = 'http://10.10.10.68:5000/api';

export const stockAuditApi = {
    // Search stock audit items
    searchItems: async (searchData) => {
        const response = await fetch(`${API_URL}/stockaudits/search`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(searchData),
        });

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.message || 'Failed to search stock audit items');
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
