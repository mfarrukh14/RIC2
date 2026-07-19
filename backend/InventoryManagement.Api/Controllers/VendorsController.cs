using InventoryManagement.Api.DTOs;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class VendorsController : BaseController
    {
        private readonly IVendorService _vendorService;

        public VendorsController(IUserSessionCacheService sessionCache, IVendorService vendorService)
            : base(sessionCache)
        {
            _vendorService = vendorService;
        }

        /// <summary>
        /// Get all vendors
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<IEnumerable<VendorDto>>> GetVendors()
        {
            var vendors = await _vendorService.GetAllVendorsAsync();
            return Ok(vendors);
        }

        /// <summary>
        /// Get a vendor by ID
        /// </summary>
        [HttpGet("{id}")]
        public async Task<ActionResult<VendorDto>> GetVendor(int id)
        {
            var vendor = await _vendorService.GetVendorByIdAsync(id);
            if (vendor == null)
                return NotFound($"Vendor with ID {id} not found");

            return Ok(vendor);
        }

        /// <summary>
        /// Create a new vendor
        /// </summary>
        [HttpPost]
        public async Task<ActionResult<VendorDto>> CreateVendor(CreateVendorDto createVendorDto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            try
            {
                var vendor = await _vendorService.CreateVendorAsync(createVendorDto);
                return CreatedAtAction(nameof(GetVendor), new { id = vendor.Id }, vendor);
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        /// <summary>
        /// Update a vendor
        /// </summary>
        [HttpPut("{id}")]
        public async Task<ActionResult<VendorDto>> UpdateVendor(int id, UpdateVendorDto updateVendorDto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            try
            {
                var vendor = await _vendorService.UpdateVendorAsync(id, updateVendorDto);
                if (vendor == null)
                    return NotFound($"Vendor with ID {id} not found");

                return Ok(vendor);
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        /// <summary>
        /// Delete a vendor
        /// </summary>
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteVendor(int id)
        {
            try
            {
                var success = await _vendorService.DeleteVendorAsync(id);
                if (!success)
                    return NotFound($"Vendor with ID {id} not found");

                return NoContent();
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
        }
    }
}