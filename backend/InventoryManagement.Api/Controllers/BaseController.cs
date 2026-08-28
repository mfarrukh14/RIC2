using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace InventoryManagement.Api.Controllers
{
    // Parent for all API controllers that need to know who the current user is.
    // There is no real auth pipeline yet, so the caller identifies itself via the
    // X-User-Id header, which must match a user cached by a prior POST /api/session login.
    // Requests without a valid, still-cached session are rejected with 401.
    public abstract class BaseController : ControllerBase, IActionFilter
    {
        private const string UserIdHeader = "X-User-Id";
        private readonly IUserSessionCacheService _sessionCache;

        protected int UserId { get; private set; }
        protected int? BranchId { get; private set; }
        protected string? BranchName { get; private set; }
        protected UserSession? CurrentUserSession { get; private set; }

        // Super Admin / Organization Admin / Branch Admin - unrestricted access
        // to every store. Everyone else is scoped to AllowedStoreIds.
        protected bool IsAdmin { get; private set; }
        protected IReadOnlyList<int> AllowedStoreIds { get; private set; } = Array.Empty<int>();

        // True for admins unconditionally; for everyone else, only when storeId
        // is set and is one of the caller's allowed stores. Use this to validate
        // a request's StoreId server-side rather than trusting it outright -
        // never let a non-admin's own choice of storeId bypass their scope.
        protected bool IsStoreAllowed(int? storeId) =>
            IsAdmin || (storeId.HasValue && AllowedStoreIds.Contains(storeId.Value));

        protected BaseController(IUserSessionCacheService sessionCache)
        {
            _sessionCache = sessionCache;
        }

        [NonAction]
        public void OnActionExecuting(ActionExecutingContext context)
        {
            var header = context.HttpContext.Request.Headers[UserIdHeader].FirstOrDefault();

            if (!int.TryParse(header, out var userId) || !_sessionCache.TryGet(userId, out var session) || session == null)
            {
                context.Result = new UnauthorizedObjectResult(new
                {
                    message = $"No active session. Send a '{UserIdHeader}' header for a user that has logged in via POST /api/session."
                });
                return;
            }

            UserId = session.UserId;
            BranchId = session.BranchId;
            BranchName = session.BranchName;
            CurrentUserSession = session;
            IsAdmin = session.IsAdmin;
            AllowedStoreIds = session.AllowedStoreIds;
        }

        [NonAction]
        public void OnActionExecuted(ActionExecutedContext context)
        {
        }
    }
}
