using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ExpiredStockController : BaseController
    {
        private readonly IExpiredStockService _expiredStockService;
        private readonly ILogger<ExpiredStockController> _logger;

        public ExpiredStockController(IUserSessionCacheService sessionCache, IExpiredStockService expiredStockService, ILogger<ExpiredStockController> logger)
            : base(sessionCache)
        {
            _expiredStockService = expiredStockService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetExpiredStock([FromQuery] ExpiredStockSearchRequest request)
        {
            try
            {
                var expiredStocks = await _expiredStockService.GetExpiredStockAsync(request);
                return Ok(expiredStocks);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving expired stock");
                return StatusCode(500, new { message = "An error occurred while retrieving expired stock data" });
            }
        }
    }
}
