using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BranchController : ControllerBase
    {
        private readonly IBranchService _service;
        private readonly ILogger<BranchController> _logger;

        public BranchController(IBranchService service, ILogger<BranchController> logger)
        {
            _service = service;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Branch>>> GetAll()
        {
            try
            {
                var branches = await _service.GetAllAsync();
                return Ok(branches);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving branches");
                return StatusCode(500, new { message = "An error occurred while retrieving branches" });
            }
        }
    }
}
