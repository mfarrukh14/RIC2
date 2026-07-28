const API_BASE_URL = 'http://localhost:5100/api';

export const assetAllocationApi = {
  // Asset Allocations CRUD
  getAll: async () => {
    const response = await fetch(`${API_BASE_URL}/assetallocations`);
    if (!response.ok) {
      throw new Error('Failed to fetch asset allocations');
    }
    return response.json();
  },

  getById: async (id) => {
    const response = await fetch(`${API_BASE_URL}/assetallocations/${id}`);
    if (!response.ok) {
      throw new Error('Failed to fetch asset allocation');
    }
    return response.json();
  },

  create: async (data) => {
    const response = await fetch(`${API_BASE_URL}/assetallocations`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });
    if (!response.ok) {
      throw new Error('Failed to create asset allocation');
    }
    return response.json();
  },

  update: async (id, data) => {
    const response = await fetch(`${API_BASE_URL}/assetallocations/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });
    if (!response.ok) {
      throw new Error('Failed to update asset allocation');
    }
    return response.ok;
  },

  delete: async (id) => {
    const response = await fetch(`${API_BASE_URL}/assetallocations/${id}`, {
      method: 'DELETE',
    });
    if (!response.ok) {
      throw new Error('Failed to delete asset allocation');
    }
    return response.ok;
  },

  // Lookup data endpoints
  getUsers: async () => {
    const response = await fetch(`${API_BASE_URL}/assetallocations/users`);
    if (!response.ok) {
      throw new Error('Failed to fetch users');
    }
    return response.json();
  },

  getRooms: async () => {
    const response = await fetch(`${API_BASE_URL}/assetallocations/rooms`);
    if (!response.ok) {
      throw new Error('Failed to fetch rooms');
    }
    return response.json();
  },

  getDepartments: async () => {
    const response = await fetch(`${API_BASE_URL}/assetallocations/departments`);
    if (!response.ok) {
      throw new Error('Failed to fetch departments');
    }
    return response.json();
  },

  getSubDepartments: async () => {
    const response = await fetch(`${API_BASE_URL}/assetallocations/sub-departments`);
    if (!response.ok) {
      throw new Error('Failed to fetch sub-departments');
    }
    return response.json();
  },

  getBuildings: async () => {
    const response = await fetch(`${API_BASE_URL}/assetallocations/buildings`);
    if (!response.ok) {
      throw new Error('Failed to fetch buildings');
    }
    return response.json();
  },

  getFloors: async (building) => {
    const url = new URL(`${API_BASE_URL}/assetallocations/floors`);
    if (building) url.searchParams.set('building', building);
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error('Failed to fetch floors');
    }
    return response.json();
  },

  getAvailableInventoryItems: async () => {
    const response = await fetch(`${API_BASE_URL}/assetallocations/inventory-items`);
    if (!response.ok) {
      throw new Error('Failed to fetch available inventory items');
    }
    return response.json();
  },
};