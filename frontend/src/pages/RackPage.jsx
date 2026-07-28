import React,{ useState, useEffect } from 'react';
import { QuestionMarkCircleIcon } from '@heroicons/react/24/outline';
import RackList from '../components/RackList';
import RackForm from '../components/RackForm';
import racksApi from '../services/racksApi';
import inventoryApi from '../services/inventoryApi';

const normalizeStores = (stores) =>
  (stores || [])
    .map((store, index) => {
      const id = store?.id ?? store?.storeId;
      if (id === null || id === undefined || id === '') {
        return null;
      }

      return {
        id,
        name: store?.name ?? store?.storeName ?? `Store ${index + 1}`,
      };
    })
    .filter(Boolean);

const RackPage = () => {
  const [racks, setRacks] = useState([]);
  const [stores, setStores] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [editingRack, setEditingRack] = useState(null);

  useEffect(() => {
    loadRacks();
    loadStores();
  }, []);

  const loadRacks = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await racksApi.getAllRacks();
      setRacks(data);
    } catch (err) {
      setError('Failed to load racks');
      console.error('Error loading racks:', err);
    } finally {
      setLoading(false);
    }
  };

  // Enrich racks with store names from the stores list
  const enrichedRacks = racks.map(rack => {
    const store = stores.find(s => Number(s.id) === Number(rack.storeId));
    
    return {
      ...rack,
      storeName: store ? store.name : rack.storeName
    };
  });

  const loadStores = async () => {
    try {
      const data = await inventoryApi.getLookupData();
      setStores(normalizeStores(data.stores));
    } catch (err) {
      console.error('Error loading stores:', err);
    }
  };

  const handleAddNew = () => {
    setEditingRack(null);
    setShowForm(true);
  };

  const handleEdit = (rack) => {
    setEditingRack(rack);
    setShowForm(true);
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this rack?')) {
      try {
        await racksApi.deleteRack(id);
        await loadRacks();
      } catch (err) {
        alert(err.response?.data?.message || err.response?.data || 'Failed to delete rack');
        console.error('Error deleting rack:', err);
      }
    }
  };

  const handleSubmit = async (formData) => {
    try {
      if (editingRack) {
        await racksApi.updateRack(editingRack.id, formData);
      } else {
        await racksApi.createRack(formData);
      }
      setShowForm(false);
      setEditingRack(null);
      await loadRacks();
    } catch (err) {
      alert('Failed to save rack');
      console.error('Error saving rack:', err);
    }
  };

  const handleCancel = () => {
    setShowForm(false);
    setEditingRack(null);
  };

  if (loading && racks.length === 0) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading...</div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <QuestionMarkCircleIcon className="h-6 w-6 text-blue-600" />
          <h1 className="text-2xl font-semibold text-gray-800">
            {showForm ? (editingRack ? 'Edit Rack' : 'Add Racks') : 'Racks'}
          </h1>
        </div>
        {!showForm && (
          <button
            onClick={handleAddNew}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            + Add New
          </button>
        )}
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Content */}
      {showForm ? (
        <RackForm
          rack={editingRack}
          stores={stores}
          onSubmit={handleSubmit}
          onCancel={handleCancel}
        />
      ) : (
        <RackList
          racks={enrichedRacks}
          onEdit={handleEdit}
          onDelete={handleDelete}
        />
      )}
    </div>
  );
};

export default RackPage;
