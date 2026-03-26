using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IDemandWiseValueService
    {
        Task<DemandWiseValueResponse> GetAsync(DemandWiseValueFilter filter);
    }
}