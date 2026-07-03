using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AssetAllocationsController : BaseController
    {
        private readonly IAssetAllocationService _assetAllocationService;
        private readonly ILogger<AssetAllocationsController> _logger;

        public AssetAllocationsController(IUserSessionCacheService sessionCache, IAssetAllocationService assetAllocationService, ILogger<AssetAllocationsController> logger)
            : base(sessionCache)
        {
            _assetAllocationService = assetAllocationService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<AssetAllocation>>> GetAll()
        {
            try
            {
                var assetAllocations = await _assetAllocationService.GetAllAsync();
                return Ok(assetAllocations);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving asset allocations");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<AssetAllocation>> GetById(int id)
        {
            try
            {
                var assetAllocation = await _assetAllocationService.GetByIdAsync(id);
                if (assetAllocation == null)
                {
                    return NotFound();
                }
                return Ok(assetAllocation);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving asset allocation with ID {Id}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPost]
        public async Task<ActionResult<int>> Create([FromBody] AssetAllocationCreateRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var id = await _assetAllocationService.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id }, id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating asset allocation");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(int id, [FromBody] AssetAllocationUpdateRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var success = await _assetAllocationService.UpdateAsync(id, request);
                if (!success)
                {
                    return NotFound();
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating asset allocation with ID {Id}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            try
            {
                var success = await _assetAllocationService.DeleteAsync(id);
                if (!success)
                {
                    return NotFound();
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting asset allocation with ID {Id}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("users")]
        public async Task<ActionResult<IEnumerable<User>>> GetUsers()
        {
            try
            {
                var users = await _assetAllocationService.GetUsersAsync();
                return Ok(users);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving users");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("rooms")]
        public async Task<ActionResult<IEnumerable<Room>>> GetRooms()
        {
            try
            {
                var rooms = await _assetAllocationService.GetRoomsAsync();
                return Ok(rooms);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rooms");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("departments")]
        public async Task<ActionResult<IEnumerable<Department>>> GetDepartments()
        {
            try
            {
                var departments = await _assetAllocationService.GetDepartmentsAsync();
                return Ok(departments);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving departments");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("sub-departments")]
        public async Task<ActionResult<IEnumerable<SubDepartment>>> GetSubDepartments()
        {
            try
            {
                var subDepartments = await _assetAllocationService.GetSubDepartmentsAsync();
                return Ok(subDepartments);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sub-departments");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("inventory-items")]
        public async Task<ActionResult<IEnumerable<InventoryItem>>> GetAvailableInventoryItems()
        {
            try
            {
                var items = await _assetAllocationService.GetAvailableInventoryItemsAsync();
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving available inventory items");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPost("report")]
        public async Task<ActionResult<IEnumerable<AssetAllocationReport>>> GetReport([FromBody] AssetAllocationReportFilter filter)
        {
            try
            {
                var report = await _assetAllocationService.GetReportAsync(filter);
                return Ok(report);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating asset allocation report");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("buildings")]
        public async Task<ActionResult<IEnumerable<string>>> GetBuildings()
        {
            try
            {
                var buildings = await _assetAllocationService.GetBuildingsAsync();
                return Ok(buildings);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving buildings");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("floors")]
        public async Task<ActionResult<IEnumerable<string>>> GetFloors([FromQuery] string? building = null)
        {
            try
            {
                var floors = await _assetAllocationService.GetFloorsByBuildingAsync(building);
                return Ok(floors);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving floors");
                return StatusCode(500, "Internal server error");
            }
        }
    }
}