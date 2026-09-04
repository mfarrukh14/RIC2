using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface ISaleSummaryStockNoDiscountService
    {
        Task<PagedResult<SaleSummaryStockNoDiscount>> GetSaleSummaryStockNoDiscountAsync(SaleSummaryStockNoDiscountRequest request);
        Task<SaleSummaryStockNoDiscountTotals> GetSaleSummaryStockNoDiscountTotalsAsync(SaleSummaryStockNoDiscountRequest request);
    }
}
