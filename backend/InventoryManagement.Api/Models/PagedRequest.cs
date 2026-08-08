namespace InventoryManagement.Api.Models
{
    // Every paginated list endpoint's [FromQuery] request type should inherit from
    // this (or, for endpoints with no other filters, bind directly to it) so
    // PageNumber/PageSize are named and defaulted identically everywhere. Pair with
    // PaginationHelper.Normalize server-side - model binder defaults only apply when
    // the query string omits the param, not when it's sent as an invalid value (0, -1).
    public class PagedRequest
    {
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = PaginationHelper.DefaultPageSize;
    }
}
