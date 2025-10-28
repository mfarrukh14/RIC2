using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StockBalanceReportController : ControllerBase
    {
        private readonly IStockBalanceReportService _stockBalanceReportService;
        private readonly ILogger<StockBalanceReportController> _logger;

        public StockBalanceReportController(IStockBalanceReportService stockBalanceReportService, ILogger<StockBalanceReportController> logger)
        {
            _stockBalanceReportService = stockBalanceReportService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetStockBalanceReport([FromQuery] StockBalanceSearchRequest request)
        {
            try
            {
                var report = await _stockBalanceReportService.GetStockBalanceReportAsync(request);
                return Ok(report);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock balance report");
                return StatusCode(500, new { message = "An error occurred while retrieving the stock balance report" });
            }
        }
    }
}
