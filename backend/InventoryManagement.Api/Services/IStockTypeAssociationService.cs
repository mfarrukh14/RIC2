using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockTypeAssociationService
    {
        Task<IEnumerable<StockTypeAssociation>> GetAllStockTypeAssociationsAsync();
        Task<StockTypeAssociation?> GetStockTypeAssociationByIdAsync(int id);
        Task<int> CreateStockTypeAssociationAsync(StockTypeAssociationRequest request);
        Task<bool> UpdateStockTypeAssociationAsync(int id, StockTypeAssociationRequest request);
        Task<bool> DeleteStockTypeAssociationAsync(int id);
    }
}
