namespace InventoryManagement.Api.Models
{
    // Single source of truth for restricting a store-scoped result to what the
    // calling user is actually allowed to see (BaseController.IsAdmin /
    // AllowedStoreIds, populated at login from Inv.StoreAllocationToUser - see
    // UserSessionCacheService). Store lookup/dropdown lists come from a
    // fragmented mix of C# raw-SQL methods and independent stored procedures
    // with no single choke point (several drift from their tracked .sql files
    // entirely - verify live before touching one), so rather than retrofit each
    // query's SQL individually, every list is filtered here as a final
    // in-memory pass after its existing fetch. Admins get the list untouched.
    public static class StoreScopeHelper
    {
        // Filters any sequence of store-like items down to the caller's allowed
        // stores. getStoreId extracts the store id from whatever shape the
        // caller's list is in (DropdownItem.Value, LookupItem.Id, etc.).
        public static List<T> FilterStores<T>(IEnumerable<T> stores, bool isAdmin, IReadOnlyCollection<int> allowedStoreIds, Func<T, int> getStoreId)
        {
            if (isAdmin)
            {
                return stores.ToList();
            }

            if (allowedStoreIds.Count == 0)
            {
                return new List<T>();
            }

            return stores.Where(s => allowedStoreIds.Contains(getStoreId(s))).ToList();
        }
    }
}
