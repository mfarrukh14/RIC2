using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DemandWiseValueController : ControllerBase
    {
        private readonly IDemandWiseValueService _demandWiseValueService;
        private readonly ILogger<DemandWiseValueController> _logger;

        public DemandWiseValueController(IDemandWiseValueService demandWiseValueService, ILogger<DemandWiseValueController> logger)
        {
            _demandWiseValueService = demandWiseValueService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<DemandWiseValueResponse>> Get([FromQuery] DemandWiseValueFilter filter)
        {
            try
            {
                var response = await _demandWiseValueService.GetAsync(filter);
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving demand wise value report");
                return StatusCode(500, new { message = "An error occurred while retrieving demand wise value data." });
            }
        }
    }
}