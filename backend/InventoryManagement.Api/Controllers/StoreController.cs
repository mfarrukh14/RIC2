using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;
using System.Data.SqlClient;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StoreController : BaseController
    {
        private readonly IStoreService _storeService;
        private readonly ILogger<StoreController> _logger;

        public StoreController(IUserSessionCacheService sessionCache, IStoreService storeService, ILogger<StoreController> logger)
            : base(sessionCache)
        {
            _storeService = storeService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Store>>> GetAll()
        {
            try
            {
                var stores = await _storeService.GetAllAsync();
                return Ok(stores);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all stores");
                return StatusCode(500, new { message = "An error occurred while retrieving stores" });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Store>> GetById(int id)
        {
            try
            {
                var store = await _storeService.GetByIdAsync(id);
                
                if (store == null)
                {
                    return NotFound(new { message = $"Store with ID {id} not found" });
                }

                return Ok(store);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving store with ID: {StoreId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the store" });
            }
        }

        [HttpPost]
        public async Task<ActionResult<Store>> Create([FromBody] StoreCreateRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                if (BranchId is not int branchId)
                {
                    return BadRequest(new { message = "Your session has no branch assigned; cannot create a store." });
                }

                request.BranchId = branchId;

                var store = await _storeService.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = store.StoreId }, store);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating store");
                return StatusCode(500, new { message = "An error occurred while creating the store" });
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] StoreUpdateRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                if (id != request.StoreId)
                {
                    return BadRequest(new { message = "ID mismatch" });
                }

                var existingStore = await _storeService.GetByIdAsync(id);
                if (existingStore == null)
                {
                    return NotFound(new { message = $"Store with ID {id} not found" });
                }

                if (BranchId is not int branchId)
                {
                    return BadRequest(new { message = "Your session has no branch assigned; cannot update this store." });
                }

                request.BranchId = branchId;

                await _storeService.UpdateAsync(id, request);
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating store with ID: {StoreId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the store" });
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                var existingStore = await _storeService.GetByIdAsync(id);
                if (existingStore == null)
                {
                    return NotFound(new { message = $"Store with ID {id} not found" });
                }

                await _storeService.DeleteAsync(id);
                return NoContent();
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogWarning(ex, "Cannot delete store with ID: {StoreId}", id);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting store with ID: {StoreId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the store" });
            }
        }

        [HttpPost("pharmacy-store-dropdown")]
        public async Task<ActionResult<PharmacyStoreDropdownResponse>> GetPharmacyStoreDropdown(
            [FromBody] PharmacyStoreDropdownRequest? request)
        {
            try
            {
                var payload = request ?? new PharmacyStoreDropdownRequest();
                var items = await _storeService.GetPharmacyStoreDropdownAsync(payload);

                var response = new PharmacyStoreDropdownResponse
                {
                    Data = new List<DropdownItem>(items)
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving pharmacy store dropdown");
                return StatusCode(500, new PharmacyStoreDropdownResponse
                {
                    Status = "Error",
                    StatusCode = 500,
                    Message = "An error occurred while retrieving pharmacy store dropdown."
                });
            }
        }

        [HttpGet("location-lookup")]
        public async Task<ActionResult<StoreLocationLookupResponse>> GetLocationLookup()
        {
            try
            {
                var lookup = await _storeService.GetLocationLookupAsync();
                return Ok(lookup);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving store location lookup");
                return StatusCode(500, new { message = "An error occurred while retrieving store location lookup." });
            }
        }
    }
}
