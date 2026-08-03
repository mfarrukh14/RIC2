using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IPurchaseRequisitionService
    {
        Task<IReadOnlyList<PurchaseRequisitionListItem>> GetAllAsync(PurchaseRequisitionFilter filter);
        Task<PurchaseRequisitionDetails?> GetByIdAsync(int id);
        Task<PurchaseRequisitionDetails> CreateAsync(PurchaseRequisitionCreateRequest request, int userId);
        Task<PurchaseRequisitionDetails?> ForwardAsync(int id, PurchaseRequisitionForwardRequest request, int userId);
        Task<PurchaseRequisitionDetails?> ChangeStatusAsync(int id, PurchaseRequisitionStatusChangeRequest request, int userId);
        Task<IReadOnlyList<PurchaseRequisitionLifeCycleEntry>> GetLifeCycleAsync(int id);
        Task<IReadOnlyList<PurchaseRequisitionLookupItem>> GetFinancialYearsAsync();
        Task<IReadOnlyList<PurchaseRequisitionLookupItem>> GetBudgetHeadsAsync();
    }
}
