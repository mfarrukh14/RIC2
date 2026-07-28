import React, { useState, useEffect } from 'react';
import { locationApi } from '../services/locationApi';

// Staggered Country -> State/Province -> City selects, backed by the live
// Countries/Provinces/Cities reference tables. Values are stored as plain
// names (not ids) so this stays compatible with the string address columns
// already used by Vendor/Manufacturer records.
const LocationFields = ({
  countryValue,
  stateValue,
  cityValue,
  countryFieldName = 'country',
  stateFieldName = 'state',
  cityFieldName = 'city',
  onLocationChange,
  countryLabel = 'Country',
  stateLabel = 'State/Province',
  cityLabel = 'City',
  requiredCountry = false,
  requiredState = false,
  requiredCity = false,
  className = 'grid grid-cols-1 md:grid-cols-3 gap-4',
}) => {
  const [countries, setCountries] = useState([]);
  const [provinces, setProvinces] = useState([]);
  const [cities, setCities] = useState([]);
  const [loadingProvinces, setLoadingProvinces] = useState(false);
  const [loadingCities, setLoadingCities] = useState(false);

  useEffect(() => {
    locationApi.getCountries()
      .then(setCountries)
      .catch((err) => {
        console.error('Error loading countries:', err);
        setCountries([]);
      });
  }, []);

  useEffect(() => {
    const country = countries.find((c) => c.name === countryValue);
    if (!country) {
      setProvinces([]);
      return;
    }
    setLoadingProvinces(true);
    locationApi.getProvinces(country.id)
      .then(setProvinces)
      .catch((err) => {
        console.error('Error loading provinces:', err);
        setProvinces([]);
      })
      .finally(() => setLoadingProvinces(false));
  }, [countryValue, countries]);

  useEffect(() => {
    const province = provinces.find((p) => p.name === stateValue);
    if (!province) {
      setCities([]);
      return;
    }
    setLoadingCities(true);
    locationApi.getCities(province.id)
      .then(setCities)
      .catch((err) => {
        console.error('Error loading cities:', err);
        setCities([]);
      })
      .finally(() => setLoadingCities(false));
  }, [stateValue, provinces]);

  const handleCountryChange = (e) => {
    onLocationChange({
      [countryFieldName]: e.target.value,
      [stateFieldName]: '',
      [cityFieldName]: '',
    });
  };

  const handleStateChange = (e) => {
    onLocationChange({
      [stateFieldName]: e.target.value,
      [cityFieldName]: '',
    });
  };

  const handleCityChange = (e) => {
    onLocationChange({ [cityFieldName]: e.target.value });
  };

  return (
    <div className={className}>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          {countryLabel}{requiredCountry ? ' *' : ''}
        </label>
        <select
          name={countryFieldName}
          value={countryValue || ''}
          onChange={handleCountryChange}
          required={requiredCountry}
          className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">Select Country</option>
          {countries.map((c) => (
            <option key={c.id} value={c.name}>{c.name}</option>
          ))}
        </select>
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          {stateLabel}{requiredState ? ' *' : ''}
        </label>
        <select
          name={stateFieldName}
          value={stateValue || ''}
          onChange={handleStateChange}
          required={requiredState}
          disabled={!countryValue}
          className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
        >
          <option value="">
            {!countryValue ? 'Select Country First' : loadingProvinces ? 'Loading...' : 'Select State/Province'}
          </option>
          {provinces.map((p) => (
            <option key={p.id} value={p.name}>{p.name}</option>
          ))}
        </select>
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          {cityLabel}{requiredCity ? ' *' : ''}
        </label>
        <select
          name={cityFieldName}
          value={cityValue || ''}
          onChange={handleCityChange}
          required={requiredCity}
          disabled={!stateValue}
          className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
        >
          <option value="">
            {!stateValue ? 'Select State/Province First' : loadingCities ? 'Loading...' : 'Select City'}
          </option>
          {cities.map((c) => (
            <option key={c.id} value={c.name}>{c.name}</option>
          ))}
        </select>
      </div>
    </div>
  );
};

export default LocationFields;
