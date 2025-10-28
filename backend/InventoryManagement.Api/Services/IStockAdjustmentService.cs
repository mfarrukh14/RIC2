using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockAdjustmentService
    {
        Task<IEnumerable<StockAdjustmentView>> GetAllAsync(StockAdjustmentSearchRequest? request = null);
        Task<StockAdjustment?> GetByIdAsync(int id);
        Task<StockAdjustment> CreateAsync(StockAdjustmentCreateRequest request);
        Task<StockAdjustment> UpdateAsync(StockAdjustmentUpdateRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
