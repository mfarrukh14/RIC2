using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class InventoriesController : BaseController
    {
        private readonly IInventoryService _inventoryService;
        private readonly ILogger<InventoriesController> _logger;

        public InventoriesController(IUserSessionCacheService sessionCache, IInventoryService inventoryService, ILogger<InventoriesController> logger)
            : base(sessionCache)
        {
            _inventoryService = inventoryService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<Inventory>>> GetAll([FromQuery] InventoryFilterRequest? filter)
        {
            try
            {
                if (!IsAdmin && filter?.StoreId.HasValue == true && !IsStoreAllowed(filter.StoreId))
                {
                    return Ok(new PagedResult<Inventory> { Items = new List<Inventory>(), TotalCount = 0, PageNumber = filter.PageNumber, PageSize = filter.PageSize });
                }

                var inventories = await _inventoryService.GetAllAsync(filter, IsAdmin, AllowedStoreIds);
                return Ok(inventories);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving inventories");
                return StatusCode(500, new { message = "An error occurred while retrieving inventories" });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Inventory>> GetById(int id)
        {
            try
            {
                var inventory = await _inventoryService.GetByIdAsync(id);
                
                if (inventory == null)
                {
                    return NotFound(new { message = $"Inventory with ID {id} not found" });
                }

                return Ok(inventory);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving inventory with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the inventory" });
            }
        }

        [HttpGet("{id}/returnable-items")]
        public async Task<ActionResult<InventoryReturnableItemsResponse>> GetReturnableItems(int id)
        {
            try
            {
                var response = await _inventoryService.GetReturnableItemsAsync(id);

                if (response == null)
                {
                    return NotFound(new { message = $"Inventory with ID {id} not found" });
                }

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving returnable items for inventory {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving returnable items" });
            }
        }

        [HttpPost]
        public async Task<ActionResult<Inventory>> Create([FromBody] InventoryCreateRequest request)
        {
            try
            {
                var id = await _inventoryService.CreateAsync(request);
                var inventory = await _inventoryService.GetByIdAsync(id);
                
                return CreatedAtAction(nameof(GetById), new { id }, inventory);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating inventory");
                return StatusCode(500, new { message = "An error occurred while creating the inventory" });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(int id, [FromBody] InventoryUpdateRequest request)
        {
            try
            {
                var success = await _inventoryService.UpdateAsync(id, request);
                
                if (!success)
                {
                    return NotFound(new { message = $"Inventory with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating inventory with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the inventory" });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            try
            {
                var success = await _inventoryService.DeleteAsync(id);
                
                if (!success)
                {
                    return NotFound(new { message = $"Inventory with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting inventory with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the inventory" });
            }
        }

        [HttpPost("details")]
        public async Task<ActionResult> CreateDetail([FromBody] InventoryDetailCreateRequest request)
        {
            try
            {
                var id = await _inventoryService.CreateDetailAsync(request);
                return Ok(new { id });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating inventory detail");
                return StatusCode(500, new { message = "An error occurred while creating the inventory detail" });
            }
        }

        [HttpPut("details/{id}")]
        public async Task<ActionResult> UpdateDetail(int id, [FromBody] InventoryDetailUpdateRequest request)
        {
            try
            {
                var success = await _inventoryService.UpdateDetailAsync(id, request);
                
                if (!success)
                {
                    return NotFound(new { message = $"Inventory detail with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating inventory detail with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the inventory detail" });
            }
        }

        [HttpDelete("details/{id}")]
        public async Task<ActionResult> DeleteDetail(int id)
        {
            try
            {
                var success = await _inventoryService.DeleteDetailAsync(id);
                
                if (!success)
                {
                    return NotFound(new { message = $"Inventory detail with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting inventory detail with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the inventory detail" });
            }
        }

        [HttpGet("lookup")]
        public async Task<ActionResult<InventoryLookupData>> GetLookupData()
        {
            try
            {
                var lookupData = await _inventoryService.GetLookupDataAsync();
                lookupData.Stores = StoreScopeHelper.FilterStores(lookupData.Stores, IsAdmin, AllowedStoreIds, s => s.StoreId);
                return Ok(lookupData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving lookup data");
                return StatusCode(500, new { message = "An error occurred while retrieving lookup data" });
            }
        }
    }
}
