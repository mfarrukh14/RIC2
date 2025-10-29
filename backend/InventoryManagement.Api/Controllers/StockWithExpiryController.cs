using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StockWithExpiryController : ControllerBase
    {
        private readonly IStockWithExpiryService _service;
        private readonly ILogger<StockWithExpiryController> _logger;

        public StockWithExpiryController(IStockWithExpiryService service, ILogger<StockWithExpiryController> logger)
        {
            _service = service;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<StockWithExpiry>>> GetAll(
            [FromQuery] int? branchId,
            [FromQuery] int? storeId,
            [FromQuery] string? itemType,
            [FromQuery] int? itemId,
            [FromQuery] int? categoryId,
            [FromQuery] bool? isExpensiveItem,
            [FromQuery] bool? isFridgeItem,
            [FromQuery] bool minimumPanicLevelOnly = false)
        {
            try
            {
                var filter = new StockWithExpiryFilter
                {
                    BranchId = branchId,
                    StoreId = storeId,
                    ItemType = itemType,
                    ItemId = itemId,
                    CategoryId = categoryId,
                    IsExpensiveItem = isExpensiveItem,
                    IsFridgeItem = isFridgeItem,
                    MinimumPanicLevelOnly = minimumPanicLevelOnly
                };

                var stocks = await _service.GetAllAsync(filter);
                return Ok(stocks);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock with expiry");
                return StatusCode(500, new { message = "An error occurred while retrieving stock data" });
            }
        }
    }
}
