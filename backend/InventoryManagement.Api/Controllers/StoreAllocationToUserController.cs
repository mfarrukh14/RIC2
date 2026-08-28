using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StoreAllocationToUserController : BaseController
    {
        private readonly IStoreAllocationToUserService _service;
        private readonly ILogger<StoreAllocationToUserController> _logger;

        public StoreAllocationToUserController(IUserSessionCacheService sessionCache, IStoreAllocationToUserService service, ILogger<StoreAllocationToUserController> logger)
            : base(sessionCache)
        {
            _service = service;
            _logger = logger;
        }

        // Every action here is admin-only, not just hidden from the sidebar: this
        // table (Inv.StoreAllocationToUser) is the source of truth every store-scoped
        // endpoint trusts to decide what a non-admin can see (see BaseController.
        // AllowedStoreIds) - a non-admin who could read or write it could see who's
        // assigned where, or grant themselves any store's access outright.
        // Plain 403, not Forbid() - Forbid() requires an authentication scheme to be
        // registered (there is none; this app authenticates via the X-User-Id header/
        // session cache, not ASP.NET's auth middleware) and throws without one.
        private ActionResult? RequireAdmin() =>
            IsAdmin ? null : StatusCode(403, new { message = "Only administrators can manage store allocations." });

        [HttpGet]
        public async Task<ActionResult<PagedResult<StoreAllocationToUser>>> GetAll(
            [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 5, [FromQuery] string? search = null)
        {
            if (RequireAdmin() is ActionResult forbidden) return forbidden;

            try
            {
                var allocations = await _service.GetAllAsync(pageNumber, pageSize, search);
                return Ok(allocations);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all store allocations");
                return StatusCode(500, new { message = "An error occurred while retrieving allocations" });
            }
        }

        [HttpGet("employee-dropdown")]
        public async Task<ActionResult<IEnumerable<DropdownItem>>> GetEmployeeDropdown()
        {
            if (RequireAdmin() is ActionResult forbidden) return forbidden;

            try
            {
                var employees = await _service.GetEmployeeDropdownAsync();
                return Ok(employees);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving employee dropdown");
                return StatusCode(500, new { message = "An error occurred while retrieving the employee dropdown" });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<StoreAllocationToUser>> GetById(int id)
        {
            if (RequireAdmin() is ActionResult forbidden) return forbidden;

            try
            {
                var allocation = await _service.GetByIdAsync(id);
                
                if (allocation == null)
                {
                    return NotFound(new { message = $"Allocation with ID {id} not found" });
                }

                return Ok(allocation);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving allocation with ID: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the allocation" });
            }
        }

        [HttpPost]
        public async Task<ActionResult<StoreAllocationToUser>> Create([FromBody] StoreAllocationToUserCreateRequest request)
        {
            if (RequireAdmin() is ActionResult forbidden) return forbidden;

            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var allocation = await _service.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = allocation.Id }, allocation);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating store allocation");
                return StatusCode(500, new { message = "An error occurred while creating the allocation" });
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] StoreAllocationToUserUpdateRequest request)
        {
            if (RequireAdmin() is ActionResult forbidden) return forbidden;

            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                if (id != request.Id)
                {
                    return BadRequest(new { message = "ID mismatch" });
                }

                var existing = await _service.GetByIdAsync(id);
                if (existing == null)
                {
                    return NotFound(new { message = $"Allocation with ID {id} not found" });
                }

                await _service.UpdateAsync(id, request);
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating allocation with ID: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the allocation" });
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            if (RequireAdmin() is ActionResult forbidden) return forbidden;

            try
            {
                var existing = await _service.GetByIdAsync(id);
                if (existing == null)
                {
                    return NotFound(new { message = $"Allocation with ID {id} not found" });
                }

                await _service.DeleteAsync(id);
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting allocation with ID: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the allocation" });
            }
        }
    }
}
