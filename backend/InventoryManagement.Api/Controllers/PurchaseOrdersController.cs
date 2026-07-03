using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PurchaseOrdersController : BaseController
    {
        private readonly IPurchaseOrderService _purchaseOrderService;
        private readonly ILogger<PurchaseOrdersController> _logger;

        public PurchaseOrdersController(IUserSessionCacheService sessionCache, IPurchaseOrderService purchaseOrderService, ILogger<PurchaseOrdersController> logger)
            : base(sessionCache)
        {
            _purchaseOrderService = purchaseOrderService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<PurchaseOrderSummary>>> GetAll([FromQuery] PurchaseOrderFilter filter)
        {
            try
            {
                var purchaseOrders = await _purchaseOrderService.GetAllAsync(filter);
                return Ok(purchaseOrders);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase orders");
                return StatusCode(500, new { message = "An error occurred while retrieving purchase orders." });
            }
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<PurchaseOrderDetails>> GetById(int id)
        {
            try
            {
                var purchaseOrder = await _purchaseOrderService.GetByIdAsync(id);
                if (purchaseOrder == null)
                {
                    return NotFound(new { message = $"Purchase order with ID {id} not found." });
                }

                return Ok(purchaseOrder);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase order with ID {PurchaseOrderId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the purchase order." });
            }
        }

        [HttpPost]
        public async Task<ActionResult<PurchaseOrderDetails>> Create([FromBody] PurchaseOrderCreateRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return ValidationProblem(ModelState);
                }

                var purchaseOrder = await _purchaseOrderService.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = purchaseOrder.PurchaseOrderId }, purchaseOrder);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating purchase order");
                return StatusCode(500, new { message = "An error occurred while creating the purchase order." });
            }
        }
    }
}