using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BrandsController : BaseController
    {
        private readonly IBrandService _brandService;

        public BrandsController(IUserSessionCacheService sessionCache, IBrandService brandService)
            : base(sessionCache)
        {
            _brandService = brandService;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Brand>>> GetAllBrands()
        {
            try
            {
                if (BranchId is not int branchId)
                {
                    return BadRequest("Current session has no branch assigned.");
                }

                var brands = await _brandService.GetAllBrandsAsync(branchId);
                return Ok(brands);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Brand>> GetBrand(int id)
        {
            try
            {
                var brand = await _brandService.GetBrandByIdAsync(id);
                if (brand == null)
                {
                    return NotFound($"Brand with ID {id} not found.");
                }
                return Ok(brand);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPost]
        public async Task<ActionResult<int>> CreateBrand([FromBody] CreateBrandRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest("Brand name is required.");
                }

                request.BranchId = BranchId;
                var brandId = await _brandService.CreateBrandAsync(request);
                return CreatedAtAction(nameof(GetBrand), new { id = brandId }, brandId);
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateBrand(int id, [FromBody] UpdateBrandRequest request)
        {
            try
            {
                if (id != request.Id)
                {
                    return BadRequest("ID mismatch between route and request body.");
                }

                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest("Brand name is required.");
                }

                request.BranchId = BranchId;
                var success = await _brandService.UpdateBrandAsync(request);
                if (!success)
                {
                    return NotFound($"Brand with ID {id} not found.");
                }

                return NoContent();
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteBrand(int id, [FromQuery] int modifiedById = 1, [FromQuery] bool force = false)
        {
            try
            {
                var success = await _brandService.DeleteBrandAsync(id, modifiedById, force);
                if (!success)
                {
                    return NotFound($"Brand with ID {id} not found.");
                }

                return NoContent();
            }
            catch (BrandInUseException ex)
            {
                return Conflict(new { message = ex.Message, requiresConfirmation = true, itemCount = ex.ItemCount });
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }
}