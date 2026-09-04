import axios from 'axios';

const API_URL = 'http://10.10.10.35:5100/api/StockWithExpiry';

export const stockWithExpiryApi = {
    // Server-paginated, call shape matches usePagedList:
    // { pageNumber, pageSize, ...filters } -> { items, totalCount }
    getAll: async ({ pageNumber, pageSize, ...filters } = {}) => {
        const params = new URLSearchParams();

        if (filters.branchId) params.append('branchId', filters.branchId);
        if (filters.storeId) params.append('storeId', filters.storeId);
        if (filters.itemType) params.append('itemType', filters.itemType);
        if (filters.itemId) params.append('itemId', filters.itemId);
        if (filters.categoryId) params.append('categoryId', filters.categoryId);
        if (filters.isExpensiveItem === true) params.append('isExpensiveItem', 'true');
        if (filters.isFridgeItem === true) params.append('isFridgeItem', 'true');
        if (filters.minimumPanicLevelOnly === true) params.append('minimumPanicLevelOnly', 'true');
        if (pageNumber) params.append('pageNumber', pageNumber);
        if (pageSize) params.append('pageSize', pageSize);

        const queryString = params.toString();
        const url = queryString ? `${API_URL}?${queryString}` : API_URL;

        const response = await axios.get(url);
        return response.data;
    }
};
