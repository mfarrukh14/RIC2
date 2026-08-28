using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IExpiredStockService
    {
        Task<PagedResult<ExpiredStock>> GetExpiredStockAsync(ExpiredStockSearchRequest request);
    }
}
