using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface ISaleSummaryItemDiscountService
    {
        Task<IEnumerable<SaleSummaryItemDiscount>> GetSaleSummaryItemDiscountAsync(SaleSummaryItemDiscountRequest request);
        Task<SaleSummaryItemDiscountTotals> GetSaleSummaryItemDiscountTotalsAsync(SaleSummaryItemDiscountRequest request);
    }
}
