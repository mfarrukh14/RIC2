import React, { useState, useEffect } from 'react';
import { XMarkIcon } from '@heroicons/react/24/outline';
import { manufacturerApi } from '../services/manufacturerApi';
import { locationApi } from '../services/locationApi';
import LocationFields from './LocationFields';

const ManufacturerForm = ({ manufacturer, onSave, onCancel, isEditing = false }) => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    ntn: '',
    stn: '',
    country: '',
    stateProvince: '',
    city: '',
    address: '',
    contactNo: '',
    description: '',
    contactPersonName1: '',
    contactPersonEmail1: '',
    contactPersonPhone1: '',
    contactPersonName2: '',
    contactPersonEmail2: '',
    contactPersonPhone2: '',
    isActive: true,
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (manufacturer) {
      // The API returns these under their real backend property names
      // (ntn, stn, cNo, cpName1, cpEmail1, ... countryName/stateOrProvinceName/
      // cityName for display) - map them into the form's own field names here
      // so previously-saved values actually show up when editing.
      setFormData({
        name: manufacturer.name || '',
        email: manufacturer.email || '',
        ntn: manufacturer.ntn || '',
        stn: manufacturer.stn || '',
        country: manufacturer.countryName || '',
        stateProvince: manufacturer.stateOrProvinceName || '',
        city: manufacturer.cityName || '',
        address: manufacturer.address || '',
        contactNo: manufacturer.cNo || '',
        description: manufacturer.description || '',
        contactPersonName1: manufacturer.cpName1 || '',
        contactPersonEmail1: manufacturer.cpEmail1 || '',
        contactPersonPhone1: manufacturer.cpContactNumber1 || '',
        contactPersonName2: manufacturer.cpName2 || '',
        contactPersonEmail2: manufacturer.cpEmail2 || '',
        contactPersonPhone2: manufacturer.cpContactNumber2 || '',
        isActive: manufacturer.isActive ?? true,
      });
    }
  }, [manufacturer]);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  // Resolves the plain-text country/state/city names held in the form back
  // into the ids the backend actually stores (CountryId/StateOrProvinceId/CityId).
  const resolveLocationIds = async () => {
    let countryId = null;
    let stateOrProvinceId = null;
    let cityId = null;

    if (formData.country) {
      const countries = await locationApi.getCountries();
      const country = countries.find(c => c.name === formData.country);
      countryId = country?.id ?? null;

      if (country && formData.stateProvince) {
        const provinces = await locationApi.getProvinces(country.id);
        const province = provinces.find(p => p.name === formData.stateProvince);
        stateOrProvinceId = province?.id ?? null;

        if (province && formData.city) {
          const cities = await locationApi.getCities(province.id);
          const city = cities.find(c => c.name === formData.city);
          cityId = city?.id ?? null;
        }
      }
    }

    return { countryId, stateOrProvinceId, cityId };
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const { countryId, stateOrProvinceId, cityId } = await resolveLocationIds();

      const payload = {
        name: formData.name,
        email: formData.email || null,
        ntn: formData.ntn || null,
        stn: formData.stn || null,
        countryId,
        stateOrProvinceId,
        cityId,
        address: formData.address || null,
        cNo: formData.contactNo || null,
        description: formData.description || null,
        cpName1: formData.contactPersonName1 || null,
        cpEmail1: formData.contactPersonEmail1 || null,
        cpContactNumber1: formData.contactPersonPhone1 || null,
        cpName2: formData.contactPersonName2 || null,
        cpEmail2: formData.contactPersonEmail2 || null,
        cpContactNumber2: formData.contactPersonPhone2 || null,
        isActive: formData.isActive,
      };

      if (isEditing && manufacturer) {
        await manufacturerApi.update(manufacturer.id, { ...payload, id: manufacturer.id });
      } else {
        await manufacturerApi.create(payload);
      }
      onSave();
    } catch (err) {
      const errorMessage = err.response?.data?.message || 
                          err.response?.data || 
                          err.message || 
                          'An error occurred';
      setError(errorMessage);
      console.error('Error saving manufacturer:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <h1 className="text-2xl font-bold text-gray-900">
              {isEditing ? 'Edit Manufacturer' : 'Add Manufacturer'}
            </h1>
            <button
              onClick={onCancel}
              className="text-gray-400 hover:text-gray-600 transition-colors"
              title="Close"
            >
              <XMarkIcon className="w-6 h-6" />
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <form onSubmit={handleSubmit} className="">
          {error && (
            <div className="mx-6 mt-6 mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
              {typeof error === 'string' ? error : JSON.stringify(error)}
            </div>
          )}

          <div className="px-6 py-6">
          {/* Active Checkbox */}
          <div className="mb-6">
            <label className="flex items-center">
              <input
                type="checkbox"
                name="isActive"
                checked={formData.isActive}
                onChange={handleChange}
                className="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50"
              />
              <span className="ml-2 text-sm font-medium text-gray-700">Active</span>
            </label>
          </div>

          {/* Basic Information Section */}
          <div className="mb-8">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Name *
                </label>
                <input
                  type="text"
                  name="name"
                  required
                  value={formData.name}
                  onChange={handleChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Manufacturer"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Email
                </label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Email"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  NTN
                </label>
                <input
                  type="text"
                  name="ntn"
                  value={formData.ntn}
                  onChange={handleChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="STN"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  STN
                </label>
                <input
                  type="text"
                  name="stn"
                  value={formData.stn}
                  onChange={handleChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="STN"
                />
              </div>
            </div>
          </div>

          {/* Address Information */}
          <div className="mb-8">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="md:col-span-2">
                <LocationFields
                  countryValue={formData.country}
                  stateValue={formData.stateProvince}
                  cityValue={formData.city}
                  countryFieldName="country"
                  stateFieldName="stateProvince"
                  cityFieldName="city"
                  onLocationChange={(fields) => setFormData(prev => ({ ...prev, ...fields }))}
                  requiredCountry
                  requiredState
                  requiredCity
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Contact No *
                </label>
                <input
                  type="tel"
                  name="contactNo"
                  value={formData.contactNo}
                  onChange={handleChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Contact No"
                />
              </div>
              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Address *
                </label>
                <input
                  type="text"
                  name="address"
                  value={formData.address}
                  onChange={handleChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Address"
                />
              </div>
              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Description
                </label>
                <textarea
                  name="description"
                  rows="4"
                  value={formData.description}
                  onChange={handleChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Description"
                />
              </div>
            </div>
          </div>

          {/* Contact Person Info */}
          <div className="mb-8">
            <h4 className="text-lg font-semibold text-gray-900 mb-4 pb-2 border-b border-gray-200">
              Contact Person Info
            </h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Contact Person 1 */}
              <div>
                <h5 className="font-medium text-gray-800 mb-3">Contact Person 1</h5>
                <div className="space-y-3">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
                    <input
                      type="text"
                      name="contactPersonName1"
                      value={formData.contactPersonName1}
                      onChange={handleChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="Contact Person Name 1"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Email 1</label>
                    <input
                      type="email"
                      name="contactPersonEmail1"
                      value={formData.contactPersonEmail1}
                      onChange={handleChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="Email 1"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Cont No 1</label>
                    <input
                      type="tel"
                      name="contactPersonPhone1"
                      value={formData.contactPersonPhone1}
                      onChange={handleChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="Contact No 1"
                    />
                  </div>
                </div>
              </div>

              {/* Contact Person 2 */}
              <div>
                <h5 className="font-medium text-gray-800 mb-3">Contact Person 2</h5>
                <div className="space-y-3">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
                    <input
                      type="text"
                      name="contactPersonName2"
                      value={formData.contactPersonName2}
                      onChange={handleChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="Contact Person Name 2"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Email 2</label>
                    <input
                      type="email"
                      name="contactPersonEmail2"
                      value={formData.contactPersonEmail2}
                      onChange={handleChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="Email 2"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Cont No 2</label>
                    <input
                      type="tel"
                      name="contactPersonPhone2"
                      value={formData.contactPersonPhone2}
                      onChange={handleChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="Contact No 2"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
          </div>

          {/* Action Buttons */}
          <div className="flex justify-end space-x-3 px-6 py-4 bg-gray-50 border-t border-gray-200">
            <button
              type="button"
              onClick={onCancel}
              className="px-6 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              disabled={loading}
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="px-6 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
              {loading ? 'Saving...' : 'Submit'}
            </button>
          </div>
        </form>
        </div>
      </div>
    </div>
  );
};

export default ManufacturerForm;