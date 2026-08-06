using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Models
{
    // Identifies a stock line's product: exactly one of ItemId/MedicineId/
    // SubServiceId is expected to be set, mirroring the three nullable
    // columns present on the stock detail/balance tables (see
    // Item_GetAllWithMedicines / UnifiedItemLookupResult for where these
    // come from). Centralizes the "match on whichever is populated" SQL
    // parameter wiring used by every service that touches Inv.Stocks.
    public readonly struct ProductKey
    {
        public int? ItemId { get; }
        public int? MedicineId { get; }
        public int? SubServiceId { get; }

        public ProductKey(int? itemId, int? medicineId, int? subServiceId)
        {
            ItemId = itemId;
            MedicineId = medicineId;
            SubServiceId = subServiceId;
        }

        public void AddParameters(SqlCommand command)
        {
            command.Parameters.AddWithValue("@ItemId", (object?)ItemId ?? DBNull.Value);
            command.Parameters.AddWithValue("@MedicineId", (object?)MedicineId ?? DBNull.Value);
            command.Parameters.AddWithValue("@SubServiceId", (object?)SubServiceId ?? DBNull.Value);
        }

        public override string ToString() =>
            ItemId.HasValue ? $"Item #{ItemId}" :
            MedicineId.HasValue ? $"Medicine #{MedicineId}" :
            SubServiceId.HasValue ? $"Disposable #{SubServiceId}" :
            "Unknown product";
    }
}
