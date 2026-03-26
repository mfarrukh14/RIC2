using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class EstimatedPurchaseOrdersController : ControllerBase
    {
        private readonly IEstimatedPurchaseOrderService _estimatedPurchaseOrderService;
        private readonly ILogger<EstimatedPurchaseOrdersController> _logger;

        public EstimatedPurchaseOrdersController(
            IEstimatedPurchaseOrderService estimatedPurchaseOrderService,
            ILogger<EstimatedPurchaseOrdersController> logger)
        {
            _estimatedPurchaseOrderService = estimatedPurchaseOrderService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] EstimatedPurchaseOrderSearchRequest request)
        {
            try
            {
                var result = await _estimatedPurchaseOrderService.GetEstimatedPurchaseOrdersAsync(request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving estimated purchase orders");
                return StatusCode(500, new { message = "An error occurred while retrieving estimated purchase order data." });
            }
        }
    }
}