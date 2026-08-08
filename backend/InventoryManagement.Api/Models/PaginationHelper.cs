using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Models
{
    // Single source of truth for the paging convention every list endpoint follows:
    // default to 10 rows/page when the frontend sends nothing, clamp to a sane
    // upper bound so a bad/malicious pageSize can't force an unbounded fetch. Every
    // GetAll_/_Search stored proc pairs this with @PageNumber/@PageSize params, an
    // OFFSET/FETCH, and a COUNT(*) OVER() AS TotalCount column (see GRN_GetAll for
    // the reference shape) so paging + total count come back in one round trip.
    public static class PaginationHelper
    {
        public const int DefaultPageSize = 10;
        public const int MaxPageSize = 200;

        public static (int PageNumber, int PageSize) Normalize(int pageNumber, int pageSize)
        {
            var normalizedPageNumber = pageNumber < 1 ? 1 : pageNumber;
            var normalizedPageSize = pageSize < 1 ? DefaultPageSize : Math.Min(pageSize, MaxPageSize);
            return (normalizedPageNumber, normalizedPageSize);
        }

        public static void AddPagingParameters(SqlCommand command, int pageNumber, int pageSize)
        {
            command.Parameters.AddWithValue("@PageNumber", pageNumber);
            command.Parameters.AddWithValue("@PageSize", pageSize);
        }

        // Call once per row while reading a proc that includes COUNT(*) OVER() AS
        // TotalCount - cheap to re-read every row instead of branching on "first row
        // only", and avoids every call site needing its own guard.
        public static int ReadTotalCount(SqlDataReader reader) => reader.GetInt32(reader.GetOrdinal("TotalCount"));
    }
}
