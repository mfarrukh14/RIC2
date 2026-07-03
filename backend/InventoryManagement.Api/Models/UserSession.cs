namespace InventoryManagement.Api.Models
{
    public class UserSession
    {
        public int UserId { get; set; }
        public int? BranchId { get; set; }
        public string? BranchName { get; set; }
        public DateTime LoggedInOn { get; set; }
        public Dictionary<string, object?> User { get; set; } = new();
    }
}
