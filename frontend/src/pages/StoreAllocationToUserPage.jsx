import React,{ useState, useEffect } from 'react';
import { storeAllocationToUserApi } from '../services/storeAllocationToUserApi';
import { getPharmacyStoreDropdown } from '../services/storeApi';

function StoreAllocationToUserPage() {
    const [allocations, setAllocations] = useState([]);
    const [stores, setStores] = useState([]);
    const [employees, setEmployees] = useState([]);
    const [isFormOpen, setIsFormOpen] = useState(false);
    const [editingAllocation, setEditingAllocation] = useState(null);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentPage, setCurrentPage] = useState(1);
    const itemsPerPage = 10;
    
    const [formData, setFormData] = useState({
        storeId: '',
        userId: '',
        isActive: true
    });

    useEffect(() => {
        fetchAllocations();
        fetchStores();
        fetchEmployees();
    }, []);

    const fetchAllocations = async () => {
        try {
            const data = await storeAllocationToUserApi.getAll();
            setAllocations(data);
        } catch (error) {
            console.error('Error fetching allocations:', error);
            alert('Failed to fetch allocations');
        }
    };

    const fetchStores = async () => {
        try {
            const data = await getPharmacyStoreDropdown();
            setStores(data);
        } catch (error) {
            console.error('Error fetching stores:', error);
        }
    };

    const fetchEmployees = async () => {
        try {
            const data = await storeAllocationToUserApi.getEmployeeDropdown();
            setEmployees(data);
        } catch (error) {
            console.error('Error fetching employees:', error);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        
        try {
            if (editingAllocation) {
                await storeAllocationToUserApi.update(editingAllocation.id, {
                    id: editingAllocation.id,
                    ...formData
                });
            } else {
                await storeAllocationToUserApi.create(formData);
            }
            
            fetchAllocations();
            resetForm();
            alert(editingAllocation ? 'Allocation updated successfully' : 'Allocation created successfully');
        } catch (error) {
            console.error('Error saving allocation:', error);
            alert('Failed to save allocation');
        }
    };

    const handleEdit = (allocation) => {
        setEditingAllocation(allocation);
        setFormData({
            storeId: allocation.storeId,
            userId: allocation.userId ?? '',
            isActive: allocation.isActive
        });
        setIsFormOpen(true);
    };

    const handleDelete = async (id) => {
        if (window.confirm('Are you sure you want to delete this allocation?')) {
            try {
                await storeAllocationToUserApi.delete(id);
                fetchAllocations();
                alert('Allocation deleted successfully');
            } catch (error) {
                console.error('Error deleting allocation:', error);
                alert('Failed to delete allocation');
            }
        }
    };

    const resetForm = () => {
        setFormData({
            storeId: '',
            userId: '',
            isActive: true
        });
        setEditingAllocation(null);
        setIsFormOpen(false);
    };

    const filteredAllocations = allocations.filter(allocation =>
        allocation.storeName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        allocation.employeeName?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const indexOfLastItem = currentPage * itemsPerPage;
    const indexOfFirstItem = indexOfLastItem - itemsPerPage;
    const currentAllocations = filteredAllocations.slice(indexOfFirstItem, indexOfLastItem);
    const totalPages = Math.ceil(filteredAllocations.length / itemsPerPage);

    const paginate = (pageNumber) => setCurrentPage(pageNumber);

    return (
        <div className="container mx-auto px-4 py-8">
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-3xl font-bold text-gray-800 flex items-center gap-2">
                    <span className="text-blue-600">🏪</span> Store Allocation to User
                </h1>
                <button 
                    className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2" 
                    onClick={() => setIsFormOpen(true)}
                >
                    <span>+</span> Add New Allocation
                </button>
            </div>

            {isFormOpen && (
                <div className="bg-white rounded-lg shadow-md p-6 mb-6">
                    <h2 className="text-xl font-semibold mb-4">
                        {editingAllocation ? 'Edit Allocation' : 'Add New Allocation'}
                    </h2>
                    <form onSubmit={handleSubmit}>
                        <div className="mb-4">
                            <label className="flex items-center gap-2">
                                <input
                                    type="checkbox"
                                    checked={formData.isActive}
                                    onChange={(e) => setFormData({...formData, isActive: e.target.checked})}
                                    className="w-4 h-4"
                                />
                                <span className="font-medium">Active</span>
                            </label>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                            <div>
                                <label htmlFor="storeId" className="block text-sm font-medium text-gray-700 mb-2">
                                    Store *
                                </label>
                                <select
                                    id="storeId"
                                    value={formData.storeId}
                                    onChange={(e) => setFormData({...formData, storeId: e.target.value})}
                                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    required
                                >
                                    <option value="">Select Store</option>
                                    {stores.map(store => (
                                        <option key={store.value} value={store.value}>
                                            {store.text}
                                        </option>
                                    ))}
                                </select>
                            </div>

                            <div>
                                <label htmlFor="userId" className="block text-sm font-medium text-gray-700 mb-2">
                                    Employee *
                                </label>
                                <select
                                    id="userId"
                                    value={formData.userId}
                                    onChange={(e) => setFormData({...formData, userId: e.target.value})}
                                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    required
                                >
                                    <option value="">Select Employee</option>
                                    {employees.map(employee => (
                                        <option key={employee.value} value={employee.value}>
                                            {employee.text}
                                        </option>
                                    ))}
                                </select>
                            </div>
                        </div>

                        <div className="flex gap-2">
                            <button type="submit" className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                                {editingAllocation ? 'Update' : 'Create'}
                            </button>
                            <button type="button" className="px-6 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600" onClick={resetForm}>
                                Cancel
                            </button>
                        </div>
                    </form>
                </div>
            )}

            <div className="mb-4">
                <input
                    type="text"
                    placeholder="Search by store or employee..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
            </div>

            <div className="bg-white rounded-lg shadow-md overflow-hidden">
                <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                        <tr>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Store</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Employee Name</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created On</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
                        </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                        {currentAllocations.length === 0 ? (
                            <tr>
                                <td colSpan="5" className="px-6 py-4 text-center text-gray-500">No allocations found</td>
                            </tr>
                        ) : (
                            currentAllocations.map((allocation) => (
                                <tr key={allocation.id} className="hover:bg-gray-50">
                                    <td className="px-6 py-4 whitespace-nowrap">{allocation.storeName}</td>
                                    <td className="px-6 py-4 whitespace-nowrap">{allocation.employeeName}</td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                                            allocation.isActive 
                                            ? 'bg-green-100 text-green-800' 
                                            : 'bg-red-100 text-red-800'
                                        }`}>
                                            {allocation.isActive ? 'Active' : 'Inactive'}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">{new Date(allocation.createdOn).toLocaleDateString()}</td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                        <button 
                                            className="text-blue-600 hover:text-blue-900 mr-3" 
                                            onClick={() => handleEdit(allocation)}
                                            title="Edit"
                                        >
                                            ✏️
                                        </button>
                                        <button 
                                            className="text-red-600 hover:text-red-900" 
                                            onClick={() => handleDelete(allocation.id)}
                                            title="Delete"
                                        >
                                            🗑️
                                        </button>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {totalPages > 1 && (
                <div className="flex justify-center items-center gap-4 mt-6">
                    <button 
                        onClick={() => paginate(currentPage - 1)} 
                        disabled={currentPage === 1}
                        className="px-4 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 disabled:bg-gray-300 disabled:cursor-not-allowed"
                    >
                        Previous
                    </button>
                    <span className="text-gray-700">
                        Page {currentPage} of {totalPages}
                    </span>
                    <button 
                        onClick={() => paginate(currentPage + 1)} 
                        disabled={currentPage === totalPages}
                        className="px-4 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 disabled:bg-gray-300 disabled:cursor-not-allowed"
                    >
                        Next
                    </button>
                </div>
            )}
        </div>
    );
}

export default StoreAllocationToUserPage;
