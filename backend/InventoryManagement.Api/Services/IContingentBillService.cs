using InventoryManagement.API.Models;

namespace InventoryManagement.API.Services
{
    public interface IContingentBillService
    {
        Task<List<ContingentBill>> GetAllAsync(ContingentBillFilterRequest filter);
        Task<ContingentBill?> GetByIdAsync(int id);
        Task<int> CreateAsync(CreateContingentBillRequest request);
        Task<bool> UpdateAsync(int id, UpdateContingentBillRequest request);
        Task<bool> DeleteAsync(int id);
        Task<ContingentBillLookupData> GetLookupDataAsync();
    }
}
