const API_BASE_URL = 'http://10.10.10.35:5100/api';

export const itemUnitApi = {
  // Get all item units
  getAll: async () => {
    const response = await fetch(`${API_BASE_URL}/itemunits`);
    if (!response.ok) {
      throw new Error('Failed to fetch item units');
    }
    return response.json();
  },

  // Get item unit by id
  getById: async (id) => {
    const response = await fetch(`${API_BASE_URL}/itemunits/${id}`);
    if (!response.ok) {
      throw new Error('Failed to fetch item unit');
    }
    return response.json();
  },

  // Create new item unit
  create: async (itemUnitData) => {
    const response = await fetch(`${API_BASE_URL}/itemunits`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(itemUnitData),
    });
    if (!response.ok) {
      throw new Error('Failed to create item unit');
    }
    return response.json();
  },

  // Update item unit
  update: async (id, itemUnitData) => {
    const response = await fetch(`${API_BASE_URL}/itemunits/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(itemUnitData),
    });
    if (!response.ok) {
      throw new Error('Failed to update item unit');
    }
    return response.ok;
  },

  // Delete item unit
  delete: async (id) => {
    const response = await fetch(`${API_BASE_URL}/itemunits/${id}?modifiedById=1`, {
      method: 'DELETE',
    });
    if (!response.ok) {
      throw new Error('Failed to delete item unit');
    }
    return response.ok;
  },
};