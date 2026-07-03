using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StockExpiringController : BaseController
    {
        private readonly IStockExpiringService _stockExpiringService;
        private readonly ILogger<StockExpiringController> _logger;

        public StockExpiringController(
            IUserSessionCacheService sessionCache,
            IStockExpiringService stockExpiringService,
            ILogger<StockExpiringController> logger)
            : base(sessionCache)
        {
            _stockExpiringService = stockExpiringService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<StockExpiringItem>>> GetExpiringStock(
            [FromQuery] int? storeId,
            [FromQuery] DateTime? startDate,
            [FromQuery] DateTime? endDate,
            [FromQuery] string? itemIds)
        {
            try
            {
                var request = new StockExpiringRequest
                {
                    StoreId = storeId,
                    StartDate = startDate,
                    EndDate = endDate,
                    ItemIds = itemIds
                };
                
                var items = await _stockExpiringService.GetExpiringStockAsync(request);
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving expiring stock");
                return StatusCode(500, "An error occurred while retrieving expiring stock");
            }
        }
        
        [HttpPost("search")]
        public async Task<ActionResult<IEnumerable<StockExpiringItem>>> SearchExpiringStock([FromBody] StockExpiringRequest request)
        {
            try
            {
                var items = await _stockExpiringService.GetExpiringStockAsync(request);
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving expiring stock");
                return StatusCode(500, "An error occurred while retrieving expiring stock");
            }
        }
    }
}
