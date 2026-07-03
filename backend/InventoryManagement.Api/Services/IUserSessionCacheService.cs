using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IUserSessionCacheService
    {
        Task<UserSession?> LoginAsync(int userId);
        void Logout(int userId);
        bool TryGet(int userId, out UserSession? session);
    }
}
