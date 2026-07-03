using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ItemTypesController : BaseController
    {
        private readonly IItemTypeService _itemTypeService;

        public ItemTypesController(IUserSessionCacheService sessionCache, IItemTypeService itemTypeService)
            : base(sessionCache)
        {
            _itemTypeService = itemTypeService;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<ItemType>>> GetAllItemTypes()
        {
            try
            {
                var itemTypes = await _itemTypeService.GetAllItemTypesAsync();
                return Ok(itemTypes);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ItemType>> GetItemType(int id)
        {
            try
            {
                var itemType = await _itemTypeService.GetItemTypeByIdAsync(id);
                if (itemType == null)
                {
                    return NotFound($"Item type with ID {id} not found.");
                }
                return Ok(itemType);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPost]
        public async Task<ActionResult<int>> CreateItemType([FromBody] CreateItemTypeRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest("Item type name is required.");
                }

                var itemTypeId = await _itemTypeService.CreateItemTypeAsync(request);
                return CreatedAtAction(nameof(GetItemType), new { id = itemTypeId }, itemTypeId);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateItemType(int id, [FromBody] UpdateItemTypeRequest request)
        {
            try
            {
                if (id != request.Id)
                {
                    return BadRequest("ID mismatch between route and request body.");
                }

                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest("Item type name is required.");
                }

                var success = await _itemTypeService.UpdateItemTypeAsync(request);
                if (!success)
                {
                    return NotFound($"Item type with ID {id} not found.");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteItemType(int id, [FromQuery] int modifiedById = 1)
        {
            try
            {
                var success = await _itemTypeService.DeleteItemTypeAsync(id, modifiedById);
                if (!success)
                {
                    return NotFound($"Item type with ID {id} not found.");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }
}