using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockService
    {
        Task<IEnumerable<Stock>> SearchStocksAsync(StockSearchRequest request);
    }
}
