using InventoryManagement.API.Models;
using InventoryManagement.API.Services;
using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Controllers;

namespace InventoryManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ContingentBillsController : BaseController
    {
        private readonly IContingentBillService _contingentBillService;

        public ContingentBillsController(IUserSessionCacheService sessionCache, IContingentBillService contingentBillService)
            : base(sessionCache)
        {
            _contingentBillService = contingentBillService;
        }

        [HttpGet]
        public async Task<ActionResult<InventoryManagement.Api.Models.PagedResult<ContingentBill>>> GetAll(
            [FromQuery] string? budgetSetupId,
            [FromQuery] int? vendorId,
            [FromQuery] int? financialYearId,
            [FromQuery] int? purchaseOrderTypeId,
            [FromQuery] int? contingentBillStatusId,
            [FromQuery] DateTime? dateStart,
            [FromQuery] DateTime? dateEnd,
            [FromQuery] string? searchTerm,
            [FromQuery] int pageNumber = 1,
            [FromQuery] int pageSize = 10)
        {
            try
            {
                var filter = new ContingentBillFilterRequest
                {
                    BudgetSetupId = budgetSetupId,
                    VendorId = vendorId,
                    FinancialYearId = financialYearId,
                    PurchaseOrderTypeId = purchaseOrderTypeId,
                    ContingentBillStatusId = contingentBillStatusId,
                    DateStart = dateStart,
                    DateEnd = dateEnd,
                    SearchTerm = searchTerm,
                    PageNumber = pageNumber,
                    PageSize = pageSize
                };

                var bills = await _contingentBillService.GetAllAsync(filter);
                return Ok(bills);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving contingent bills", error = ex.Message });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ContingentBill>> GetById(int id)
        {
            try
            {
                var bill = await _contingentBillService.GetByIdAsync(id);
                if (bill == null)
                {
                    return NotFound(new { message = "Contingent bill not found" });
                }
                return Ok(bill);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving contingent bill", error = ex.Message });
            }
        }

        [HttpPost]
        public async Task<ActionResult<int>> Create([FromBody] CreateContingentBillRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var id = await _contingentBillService.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id }, new { id, message = "Contingent bill created successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error creating contingent bill", error = ex.Message });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(int id, [FromBody] UpdateContingentBillRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var success = await _contingentBillService.UpdateAsync(id, request);
                if (!success)
                {
                    return NotFound(new { message = "Contingent bill not found" });
                }

                return Ok(new { message = "Contingent bill updated successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error updating contingent bill", error = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            try
            {
                var success = await _contingentBillService.DeleteAsync(id);
                if (!success)
                {
                    return NotFound(new { message = "Contingent bill not found" });
                }

                return Ok(new { message = "Contingent bill deleted successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error deleting contingent bill", error = ex.Message });
            }
        }

        [HttpGet("lookup")]
        public async Task<ActionResult<ContingentBillLookupData>> GetLookupData()
        {
            try
            {
                var lookupData = await _contingentBillService.GetLookupDataAsync();
                return Ok(lookupData);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving lookup data", error = ex.Message });
            }
        }
    }
}
