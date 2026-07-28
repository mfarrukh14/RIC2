const API_BASE_URL = 'http://localhost:5100/api';

export const itemTypeApi = {
  // Get all item types
  getAll: async () => {
    const response = await fetch(`${API_BASE_URL}/itemtypes`);
    if (!response.ok) {
      throw new Error('Failed to fetch item types');
    }
    return response.json();
  },

  // Get item type by id
  getById: async (id) => {
    const response = await fetch(`${API_BASE_URL}/itemtypes/${id}`);
    if (!response.ok) {
      throw new Error('Failed to fetch item type');
    }
    return response.json();
  },

  // Create new item type
  create: async (itemTypeData) => {
    const response = await fetch(`${API_BASE_URL}/itemtypes`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(itemTypeData),
    });
    if (!response.ok) {
      throw new Error('Failed to create item type');
    }
    return response.json();
  },

  // Update item type
  update: async (id, itemTypeData) => {
    const response = await fetch(`${API_BASE_URL}/itemtypes/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(itemTypeData),
    });
    if (!response.ok) {
      throw new Error('Failed to update item type');
    }
    return response.ok;
  },

  // Delete item type
  delete: async (id) => {
    const response = await fetch(`${API_BASE_URL}/itemtypes/${id}?modifiedById=1`, {
      method: 'DELETE',
    });
    if (!response.ok) {
      throw new Error('Failed to delete item type');
    }
    return response.ok;
  },
};