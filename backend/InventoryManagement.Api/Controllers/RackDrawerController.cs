using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RackDrawerController : BaseController
    {
        private readonly IRackDrawerService _rackDrawerService;
        private readonly ILogger<RackDrawerController> _logger;

        public RackDrawerController(IUserSessionCacheService sessionCache, IRackDrawerService rackDrawerService, ILogger<RackDrawerController> logger)
            : base(sessionCache)
        {
            _rackDrawerService = rackDrawerService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                var rackDrawers = await _rackDrawerService.GetAllAsync();
                return Ok(rackDrawers);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack drawers");
                return StatusCode(500, new { message = "An error occurred while retrieving rack drawers" });
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            try
            {
                var rackDrawer = await _rackDrawerService.GetByIdAsync(id);
                if (rackDrawer == null)
                {
                    return NotFound(new { message = "Rack drawer not found" });
                }
                return Ok(rackDrawer);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack drawer by ID: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the rack drawer" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] RackDrawerCreateRequest request)
        {
            try
            {
                var rackDrawer = await _rackDrawerService.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = rackDrawer.Id }, rackDrawer);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating rack drawer");
                return StatusCode(500, new { message = "An error occurred while creating the rack drawer" });
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] RackDrawerUpdateRequest request)
        {
            try
            {
                if (id != request.Id)
                {
                    return BadRequest(new { message = "ID mismatch" });
                }

                var rackDrawer = await _rackDrawerService.UpdateAsync(request);
                if (rackDrawer == null)
                {
                    return NotFound(new { message = "Rack drawer not found" });
                }
                return Ok(rackDrawer);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating rack drawer with ID: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the rack drawer" });
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                var result = await _rackDrawerService.DeleteAsync(id);
                if (!result)
                {
                    return NotFound(new { message = "Rack drawer not found" });
                }
                return Ok(new { message = "Rack drawer deleted successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting rack drawer with ID: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the rack drawer" });
            }
        }
    }
}
