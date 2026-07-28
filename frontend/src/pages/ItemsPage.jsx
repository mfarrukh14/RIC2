import React, { useState, useEffect } from 'react';
import { FiPlus, FiSearch } from 'react-icons/fi';
import ItemList from '../components/ItemList';
import ItemForm from '../components/ItemForm';
import itemApi from '../services/itemApi';
import { itemTypeApi, brandApi, packingApi } from '../services/api';
import { itemUnitApi } from '../services/itemUnitApi';

const ItemsPage = () => {
  const [items, setItems] = useState([]);
  const [filteredItems, setFilteredItems] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Lookup data
  const [itemTypes, setItemTypes] = useState([]);
  const [brands, setBrands] = useState([]);
  const [categories, setCategories] = useState([]);
  const [subCategories, setSubCategories] = useState([]);
  const [packings, setPackings] = useState([]);
  const [itemUnits, setItemUnits] = useState([]);
  const [prices, setPrices] = useState([]);
  const [taxRates, setTaxRates] = useState([]);
  const [taxDescriptions, setTaxDescriptions] = useState([]);
  const [taxTypes, setTaxTypes] = useState([]);

  useEffect(() => {
    fetchItems();
    fetchLookupData();
  }, []);

  useEffect(() => {
    filterItems();
  }, [searchTerm, items]);

  const fetchItems = async () => {
    try {
      setLoading(true);
      const data = await itemApi.getAll();
      setItems(data);
      setFilteredItems(data);
      setError(null);
    } catch (err) {
      console.error('Error fetching items:', err);
      setError('Failed to fetch items. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const fetchLookupData = async () => {
    // Each lookup is fetched independently so one failing endpoint doesn't
    // blank out every dropdown in the form (Promise.all would reject as a whole).
    const safeFetch = async (label, fn) => {
      try {
        return await fn();
      } catch (err) {
        console.error(`Error fetching ${label}:`, err);
        return [];
      }
    };

    const onlyActive = (list) => (list || []).filter((entry) => entry.isActive !== false);

    const [
      itemTypesData,
      brandsData,
      categoriesData,
      subCategoriesData,
      packingsData,
      itemUnitsData,
      pricesData,
      taxRatesData,
      taxDescriptionsData,
      taxTypesData,
    ] = await Promise.all([
      safeFetch('item types', itemTypeApi.getAll),
      safeFetch('brands', brandApi.getAll),
      safeFetch('categories', itemApi.getCategories),
      safeFetch('sub-categories', itemApi.getSubCategories),
      safeFetch('packings', packingApi.getAll),
      safeFetch('item units', itemUnitApi.getAll),
      safeFetch('prices', itemApi.getPrices),
      safeFetch('tax rates', itemApi.getTaxRates),
      safeFetch('tax descriptions', itemApi.getTaxDescriptions),
      safeFetch('tax types', itemApi.getTaxTypes),
    ]);

    setItemTypes(onlyActive(itemTypesData));
    setBrands(onlyActive(brandsData));
    setCategories(onlyActive(categoriesData));
    setSubCategories(onlyActive(subCategoriesData));
    setPackings(onlyActive(packingsData));
    setItemUnits(onlyActive(itemUnitsData));
    setPrices(pricesData);
    setTaxRates(taxRatesData);
    setTaxDescriptions(taxDescriptionsData);
    setTaxTypes(taxTypesData);
  };

  const filterItems = () => {
    if (!searchTerm) {
      setFilteredItems(items);
      return;
    }

    const filtered = items.filter(
      (item) =>
        item.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.itemTypeName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.categoryName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.barCode?.toLowerCase().includes(searchTerm.toLowerCase())
    );
    setFilteredItems(filtered);
  };

  const handleAddNew = () => {
    setSelectedItem(null);
    setShowForm(true);
  };

  const handleEdit = (item) => {
    setSelectedItem(item);
    setShowForm(true);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this item?')) {
      return;
    }

    try {
      await itemApi.delete(id);
      await fetchItems();
    } catch (err) {
      console.error('Error deleting item:', err);
      alert(err.response?.data?.message || 'Failed to delete item. Please try again.');
    }
  };

  const handleSubmit = async (formData) => {
    try {
      if (selectedItem) {
        await itemApi.update(selectedItem.id, formData);
      } else {
        await itemApi.create(formData);
      }
      await fetchItems();
      setShowForm(false);
      setSelectedItem(null);
    } catch (err) {
      console.error('Error saving item:', err);
      const errorMessage = err.response?.data?.message || err.message || 'Failed to save item. Please try again.';
      alert(errorMessage);
    }
  };

  const handleCancel = () => {
    setShowForm(false);
    setSelectedItem(null);
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-screen">
        <div className="text-gray-600">Loading...</div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-800">Items Management</h1>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-md">
          {error}
        </div>
      )}

      {!showForm ? (
        <>
          <div className="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <div className="relative w-full sm:w-96">
              <FiSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Search items..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <button
              onClick={handleAddNew}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <FiPlus className="h-5 w-5" />
              Add New Item
            </button>
          </div>

          <ItemList items={filteredItems} onEdit={handleEdit} onDelete={handleDelete} />
        </>
      ) : (
        <ItemForm
          item={selectedItem}
          onSubmit={handleSubmit}
          onCancel={handleCancel}
          itemTypes={itemTypes}
          brands={brands}
          categories={categories}
          subCategories={subCategories}
          packings={packings}
          itemUnits={itemUnits}
          prices={prices}
          taxRates={taxRates}
          taxDescriptions={taxDescriptions}
          taxTypes={taxTypes}
        />
      )}
    </div>
  );
};

export default ItemsPage;
