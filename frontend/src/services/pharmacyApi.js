import api from './api';

const PHARMACY_BASE_URL = '/pharmacy';

const pharmacyApi = {
  searchPatients: async (q) => {
    const response = await api.get(`${PHARMACY_BASE_URL}/patients/search`, { params: { q } });
    return response.data;
  },

  getActiveItems: async (branchId, storeId) => {
    const response = await api.get(`${PHARMACY_BASE_URL}/items`, { params: { branchId, storeId } });
    return response.data;
  },

  getActiveDoctors: async () => {
    const response = await api.get(`${PHARMACY_BASE_URL}/doctors`);
    return response.data;
  },

  getPendingPrescriptions: async (patientId, storeId) => {
    const response = await api.get(`${PHARMACY_BASE_URL}/patients/${patientId}/pending-prescriptions`, { params: { storeId } });
    return response.data;
  },

  addToProvisional: async (payload) => {
    const response = await api.post(`${PHARMACY_BASE_URL}/dispense/provisional`, payload);
    return response.data;
  },

  finalizeDispense: async (id, payload) => {
    const response = await api.post(`${PHARMACY_BASE_URL}/dispense/${id}/finalize`, payload);
    return response.data;
  },

  getChallan: async (id) => {
    const response = await api.get(`${PHARMACY_BASE_URL}/challans/${id}`);
    return response.data;
  },

  getLookups: async () => {
    const response = await api.get(`${PHARMACY_BASE_URL}/lookups`);
    return response.data;
  },

  // Pharmacy Department Store
  getDepartmentStoreMappings: async () => {
    const response = await api.get(`${PHARMACY_BASE_URL}/department-store`);
    return response.data;
  },

  getBranchDepartments: async () => {
    const response = await api.get(`${PHARMACY_BASE_URL}/departments`);
    return response.data;
  },

  createDepartmentStoreMapping: async (payload) => {
    const response = await api.post(`${PHARMACY_BASE_URL}/department-store`, payload);
    return response.data;
  },

  updateDepartmentStoreMapping: async (id, payload) => {
    const response = await api.put(`${PHARMACY_BASE_URL}/department-store/${id}`, payload);
    return response.data;
  },

  deleteDepartmentStoreMapping: async (id) => {
    await api.delete(`${PHARMACY_BASE_URL}/department-store/${id}`);
  },

  // Refund Medicine
  getRefundableLines: async (storeId, challanNo) => {
    const response = await api.get(`${PHARMACY_BASE_URL}/refund/lines`, { params: { storeId, challanNo } });
    return response.data;
  },

  processRefund: async (payload) => {
    const response = await api.post(`${PHARMACY_BASE_URL}/refund`, payload);
    return response.data;
  },

  // Daily Sale
  getDailySale: async (params) => {
    const response = await api.get(`${PHARMACY_BASE_URL}/daily-sale`, { params });
    return response.data;
  },

  // Item Wise Sale
  getItemWiseSale: async (params) => {
    const response = await api.get(`${PHARMACY_BASE_URL}/item-wise-sale`, { params });
    return response.data;
  },

  // Pharmacy Queue
  getQueue: async (storeId) => {
    const response = await api.get(`${PHARMACY_BASE_URL}/queue`, { params: { storeId } });
    return response.data;
  },

  // Pharmacy Online Order
  getOnlineOrders: async (params) => {
    const response = await api.get(`${PHARMACY_BASE_URL}/online-orders`, { params });
    return response.data;
  },

  // Pharmacy Dashboard
  getDashboard: async (params) => {
    const response = await api.get(`${PHARMACY_BASE_URL}/dashboard`, { params });
    return response.data;
  },

  // Immunization
  getVaccines: async () => {
    const response = await api.get(`${PHARMACY_BASE_URL}/vaccines`);
    return response.data;
  },

  getVaccineRecords: async (params) => {
    const response = await api.get(`${PHARMACY_BASE_URL}/immunizations`, { params });
    return response.data;
  },

  createVaccineRecord: async (payload) => {
    const response = await api.post(`${PHARMACY_BASE_URL}/immunizations`, payload);
    return response.data;
  }
};

export default pharmacyApi;
