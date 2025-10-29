using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SaleSummaryItemDiscountController : ControllerBase
    {
        private readonly ISaleSummaryItemDiscountService _saleSummaryItemDiscountService;
        private readonly ILogger<SaleSummaryItemDiscountController> _logger;

        public SaleSummaryItemDiscountController(ISaleSummaryItemDiscountService saleSummaryItemDiscountService, ILogger<SaleSummaryItemDiscountController> logger)
        {
            _saleSummaryItemDiscountService = saleSummaryItemDiscountService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetSaleSummaryItemDiscount([FromQuery] SaleSummaryItemDiscountRequest request)
        {
            try
            {
                var summaries = await _saleSummaryItemDiscountService.GetSaleSummaryItemDiscountAsync(request);
                return Ok(summaries);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sale summary item discount");
                return StatusCode(500, new { message = "An error occurred while retrieving sale summary item discount" });
            }
        }

        [HttpGet("totals")]
        public async Task<IActionResult> GetSaleSummaryItemDiscountTotals([FromQuery] SaleSummaryItemDiscountRequest request)
        {
            try
            {
                var totals = await _saleSummaryItemDiscountService.GetSaleSummaryItemDiscountTotalsAsync(request);
                return Ok(totals);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sale summary item discount totals");
                return StatusCode(500, new { message = "An error occurred while retrieving sale summary item discount totals" });
            }
        }
    }
}
