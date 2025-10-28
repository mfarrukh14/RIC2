using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StockDetailRecordsController : ControllerBase
    {
        private readonly IStockDetailRecordService _stockDetailRecordService;
        private readonly ILogger<StockDetailRecordsController> _logger;

        public StockDetailRecordsController(IStockDetailRecordService stockDetailRecordService, ILogger<StockDetailRecordsController> logger)
        {
            _stockDetailRecordService = stockDetailRecordService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetStockDetailRecords([FromQuery] StockDetailRecordSearchRequest request)
        {
            try
            {
                var records = await _stockDetailRecordService.GetStockDetailRecordsAsync(request);
                return Ok(records);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock detail records");
                return StatusCode(500, new { message = "An error occurred while retrieving stock detail records" });
            }
        }
    }
}
