namespace InventoryManagement.Api.DTOs
{
    public class SessionLoginRequest
    {
        public int UserId { get; set; }

        // 1 = login (cache the user's data), 0 = logout (evict the cache entry)
        public int IsLogin { get; set; }
    }
}
