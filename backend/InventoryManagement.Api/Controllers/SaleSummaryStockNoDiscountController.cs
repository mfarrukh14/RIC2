using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SaleSummaryStockNoDiscountController : BaseController
    {
        private readonly ISaleSummaryStockNoDiscountService _saleSummaryStockNoDiscountService;
        private readonly ILogger<SaleSummaryStockNoDiscountController> _logger;

        public SaleSummaryStockNoDiscountController(IUserSessionCacheService sessionCache, ISaleSummaryStockNoDiscountService saleSummaryStockNoDiscountService, ILogger<SaleSummaryStockNoDiscountController> logger)
            : base(sessionCache)
        {
            _saleSummaryStockNoDiscountService = saleSummaryStockNoDiscountService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetSaleSummaryStockNoDiscount([FromQuery] SaleSummaryStockNoDiscountRequest request)
        {
            try
            {
                var summaries = await _saleSummaryStockNoDiscountService.GetSaleSummaryStockNoDiscountAsync(request);
                return Ok(summaries);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sale summary stock no discount");
                return StatusCode(500, new { message = "An error occurred while retrieving sale summary stock no discount" });
            }
        }

        [HttpGet("totals")]
        public async Task<IActionResult> GetSaleSummaryStockNoDiscountTotals([FromQuery] SaleSummaryStockNoDiscountRequest request)
        {
            try
            {
                var totals = await _saleSummaryStockNoDiscountService.GetSaleSummaryStockNoDiscountTotalsAsync(request);
                return Ok(totals);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sale summary stock no discount totals");
                return StatusCode(500, new { message = "An error occurred while retrieving sale summary stock no discount totals" });
            }
        }
    }
}
