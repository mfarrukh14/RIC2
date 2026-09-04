using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StockDetailRecordsController : BaseController
    {
        private readonly IStockDetailRecordService _stockDetailRecordService;
        private readonly ILogger<StockDetailRecordsController> _logger;

        public StockDetailRecordsController(IUserSessionCacheService sessionCache, IStockDetailRecordService stockDetailRecordService, ILogger<StockDetailRecordsController> logger)
            : base(sessionCache)
        {
            _stockDetailRecordService = stockDetailRecordService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetStockDetailRecords([FromQuery] StockDetailRecordSearchRequest request)
        {
            try
            {
                var result = await _stockDetailRecordService.GetStockDetailRecordsAsync(request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock detail records");
                return StatusCode(500, new { message = "An error occurred while retrieving stock detail records" });
            }
        }
    }
}
