using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;
using System.Linq;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ListController : BaseController
    {
        private readonly IAssetAllocationService _assetAllocationService;
        private readonly ILogger<ListController> _logger;

        public ListController(IUserSessionCacheService sessionCache, IAssetAllocationService assetAllocationService, ILogger<ListController> logger)
            : base(sessionCache)
        {
            _assetAllocationService = assetAllocationService;
            _logger = logger;
        }

        [HttpGet("DepartmentsDropdown")]
        public async Task<ActionResult<IEnumerable<DropdownItem>>> GetDepartmentsDropdown()
        {
            try
            {
                var departments = await _assetAllocationService.GetDepartmentsAsync();
                var items = departments
                    .Select(department => new DropdownItem
                    {
                        Value = department.Id,
                        Text = department.Name
                    })
                    .ToList();

                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving departments dropdown");
                return StatusCode(500, new { message = "An error occurred while retrieving departments" });
            }
        }
    }
}
