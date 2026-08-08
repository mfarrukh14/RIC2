using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ItemUnitsController : BaseController
    {
        private readonly IItemUnitService _itemUnitService;

        public ItemUnitsController(IUserSessionCacheService sessionCache, IItemUnitService itemUnitService)
            : base(sessionCache)
        {
            _itemUnitService = itemUnitService;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<ItemUnit>>> GetAllItemUnits()
        {
            try
            {
                if (BranchId is not int branchId)
                {
                    return BadRequest("Current session has no branch assigned.");
                }

                var itemUnits = await _itemUnitService.GetAllItemUnitsAsync(branchId);
                return Ok(itemUnits);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ItemUnit>> GetItemUnit(int id)
        {
            try
            {
                var itemUnit = await _itemUnitService.GetItemUnitByIdAsync(id);
                if (itemUnit == null)
                {
                    return NotFound($"Item unit with ID {id} not found.");
                }
                return Ok(itemUnit);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPost]
        public async Task<ActionResult<int>> CreateItemUnit([FromBody] CreateItemUnitRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest("Item unit name is required.");
                }

                request.BranchId = BranchId;
                var itemUnitId = await _itemUnitService.CreateItemUnitAsync(request);
                return CreatedAtAction(nameof(GetItemUnit), new { id = itemUnitId }, itemUnitId);
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateItemUnit(int id, [FromBody] UpdateItemUnitRequest request)
        {
            try
            {
                if (id != request.Id)
                {
                    return BadRequest("ID mismatch between route and request body.");
                }

                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest("Item unit name is required.");
                }

                request.BranchId = BranchId;
                var success = await _itemUnitService.UpdateItemUnitAsync(request);
                if (!success)
                {
                    return NotFound($"Item unit with ID {id} not found.");
                }

                return NoContent();
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteItemUnit(int id, [FromQuery] int modifiedById = 1)
        {
            try
            {
                var success = await _itemUnitService.DeleteItemUnitAsync(id, modifiedById);
                if (!success)
                {
                    return NotFound($"Item unit with ID {id} not found.");
                }

                return NoContent();
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }
}