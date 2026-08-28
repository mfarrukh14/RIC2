import api from './api';

const departmentApi = {
  getDropdown: async () => {
    const response = await api.get('/List/DepartmentsDropdown');
    return response.data;
  }
};

export default departmentApi;
