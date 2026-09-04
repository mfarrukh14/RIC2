using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface ISaleSummaryDailyService
    {
        Task<PagedResult<SaleSummaryDaily>> GetSaleSummaryAsync(SaleSummarySearchRequest request);
        Task<SaleSummarySummary> GetSaleSummarySummaryAsync(SaleSummarySearchRequest request);
    }
}
