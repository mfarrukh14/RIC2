import axios from 'axios';

const API_URL = 'http://10.10.10.68:5000/api/StockWithExpiry';

export const stockWithExpiryApi = {
    getAll: async (filters = {}) => {
        const params = new URLSearchParams();
        
        if (filters.branchId) params.append('branchId', filters.branchId);
        if (filters.storeId) params.append('storeId', filters.storeId);
        if (filters.itemType) params.append('itemType', filters.itemType);
        if (filters.itemId) params.append('itemId', filters.itemId);
        if (filters.categoryId) params.append('categoryId', filters.categoryId);
        if (filters.isExpensiveItem === true) params.append('isExpensiveItem', 'true');
        if (filters.isFridgeItem === true) params.append('isFridgeItem', 'true');
        if (filters.minimumPanicLevelOnly === true) params.append('minimumPanicLevelOnly', 'true');
        
        const queryString = params.toString();
        const url = queryString ? `${API_URL}?${queryString}` : API_URL;
        
        const response = await axios.get(url);
        return response.data;
    }
};
