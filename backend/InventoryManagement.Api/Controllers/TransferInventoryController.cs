using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TransferInventoryController : BaseController
    {
        private readonly ITransferInventoryService _transferInventoryService;
        private readonly ILogger<TransferInventoryController> _logger;

        public TransferInventoryController(IUserSessionCacheService sessionCache, ITransferInventoryService transferInventoryService, ILogger<TransferInventoryController> logger)
            : base(sessionCache)
        {
            _transferInventoryService = transferInventoryService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<List<TransferInventory>>> GetAll()
        {
            try
            {
                var transfers = await _transferInventoryService.GetAllAsync();
                return Ok(transfers);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving transfer inventories");
                return StatusCode(500, new { message = "An error occurred while retrieving transfer inventories" });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<TransferInventory>> GetById(int id)
        {
            try
            {
                var transfer = await _transferInventoryService.GetByIdAsync(id);
                if (transfer == null)
                {
                    return NotFound(new { message = $"Transfer inventory with ID {id} not found" });
                }
                return Ok(transfer);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving transfer inventory with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the transfer inventory" });
            }
        }

        [HttpPost]
        public async Task<ActionResult<TransferInventory>> Create([FromBody] TransferInventoryCreateRequest request)
        {
            try
            {
                var transfer = await _transferInventoryService.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = transfer.Id }, transfer);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating transfer inventory");
                return StatusCode(500, new { message = "An error occurred while creating the transfer inventory" });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(int id, [FromBody] TransferInventoryUpdateRequest request)
        {
            try
            {
                var result = await _transferInventoryService.UpdateAsync(id, request);
                if (!result)
                {
                    return NotFound(new { message = $"Transfer inventory with ID {id} not found" });
                }
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating transfer inventory with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the transfer inventory" });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            try
            {
                var result = await _transferInventoryService.DeleteAsync(id);
                if (!result)
                {
                    return NotFound(new { message = $"Transfer inventory with ID {id} not found" });
                }
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting transfer inventory with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the transfer inventory" });
            }
        }

        [HttpGet("lookup")]
        public async Task<ActionResult<TransferInventoryLookupData>> GetLookupData()
        {
            try
            {
                var lookupData = await _transferInventoryService.GetLookupDataAsync();
                return Ok(lookupData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving transfer inventory lookup data");
                return StatusCode(500, new { message = "An error occurred while retrieving lookup data" });
            }
        }
    }
}
