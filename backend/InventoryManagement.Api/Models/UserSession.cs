namespace InventoryManagement.Api.Models
{
    public class UserSession
    {
        public int UserId { get; set; }
        public int? BranchId { get; set; }
        public string? BranchName { get; set; }
        public DateTime LoggedInOn { get; set; }
        public Dictionary<string, object?> User { get; set; } = new();

        // Super Admin / Organization Admin / Branch Admin (MemberShip.UserTypes
        // UTId 1/2/3) - unrestricted access to every store's data, matching
        // today's behavior for everyone. Everyone else (User/Doctor/Nurse, UTId
        // 4/5/6) is scoped to AllowedStoreIds below.
        public bool IsAdmin { get; set; }

        // Populated from Inv.StoreAllocationToUser for non-admins. Empty means
        // the user has no store assigned yet - they see nothing (fail closed)
        // until an admin assigns one via Store Allocation to User, rather than
        // silently falling back to "no restriction".
        public List<int> AllowedStoreIds { get; set; } = new();
    }
}
