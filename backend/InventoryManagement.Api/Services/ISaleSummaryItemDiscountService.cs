using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface ISaleSummaryItemDiscountService
    {
        Task<PagedResult<SaleSummaryItemDiscount>> GetSaleSummaryItemDiscountAsync(SaleSummaryItemDiscountRequest request);
        Task<SaleSummaryItemDiscountTotals> GetSaleSummaryItemDiscountTotalsAsync(SaleSummaryItemDiscountRequest request);
    }
}
