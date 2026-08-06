import axios from 'axios';
import { attachUserIdHeader } from './httpAuth';

const API_BASE_URL = 'http://localhost:5100/api'; // Backend is running on port 5100

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

attachUserIdHeader(api);

const toOptions = (items) =>
  (items || []).map((item) => ({
    id: item.value ?? item.Value,
    name: item.text ?? item.Text,
  }));

export const locationApi = {
  // Get all countries
  getCountries: async () => {
    const response = await api.get('/location/countries');
    return toOptions(response.data);
  },

  // Get states/provinces for a country
  getProvinces: async (countryId) => {
    if (!countryId) return [];
    const response = await api.get('/location/provinces', { params: { countryId } });
    return toOptions(response.data);
  },

  // Get cities for a state/province
  getCities: async (provinceId) => {
    if (!provinceId) return [];
    const response = await api.get('/location/cities', { params: { provinceId } });
    return toOptions(response.data);
  },
};
