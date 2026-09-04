using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PharmacyController : BaseController
    {
        private readonly IPharmacyService _pharmacyService;
        private readonly ILogger<PharmacyController> _logger;

        public PharmacyController(IUserSessionCacheService sessionCache, IPharmacyService pharmacyService, ILogger<PharmacyController> logger)
            : base(sessionCache)
        {
            _pharmacyService = pharmacyService;
            _logger = logger;
        }

        [HttpGet("patients/search")]
        public async Task<ActionResult<IReadOnlyList<PharmacyPatientSearchResult>>> SearchPatients([FromQuery] string q)
        {
            try
            {
                var results = await _pharmacyService.SearchPatientsAsync(q ?? string.Empty);
                return Ok(results);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error searching pharmacy patients");
                return StatusCode(500, new { message = "An error occurred while searching patients." });
            }
        }

        [HttpGet("items")]
        public async Task<ActionResult<IReadOnlyList<PharmacyItemSearchResult>>> GetActiveItems([FromQuery] int branchId, [FromQuery] int storeId)
        {
            try
            {
                var results = await _pharmacyService.GetActiveItemsAsync(branchId, storeId);
                return Ok(results);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving active pharmacy items");
                return StatusCode(500, new { message = "An error occurred while retrieving items." });
            }
        }

        [HttpGet("doctors")]
        public async Task<ActionResult<IReadOnlyList<PharmacyDoctorSearchResult>>> GetActiveDoctors()
        {
            try
            {
                var results = await _pharmacyService.GetActiveDoctorsAsync();
                return Ok(results);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving active doctors");
                return StatusCode(500, new { message = "An error occurred while retrieving doctors." });
            }
        }

        [HttpGet("patients/{patientId:int}/pending-prescriptions")]
        public async Task<ActionResult<IReadOnlyList<PharmacyPendingPrescriptionItem>>> GetPendingPrescriptions(int patientId, [FromQuery] int storeId)
        {
            try
            {
                var results = await _pharmacyService.GetPendingPrescriptionsAsync(patientId, storeId);
                return Ok(results);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving pending prescriptions for patient {PatientId}", patientId);
                return StatusCode(500, new { message = "An error occurred while retrieving pending prescriptions." });
            }
        }

        [HttpPost("dispense/provisional")]
        public async Task<ActionResult<PharmacyChallanDetails>> AddToProvisional([FromBody] PharmacyProvisionalDispenseRequest request)
        {
            try
            {
                if (BranchId == null)
                {
                    return BadRequest(new { message = "No branch is associated with the current session." });
                }

                var result = await _pharmacyService.CreateOrAppendProvisionalAsync(request, BranchId.Value, UserId);
                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding items to pharmacy basket");
                return StatusCode(500, new { message = "An error occurred while adding items to the basket." });
            }
        }

        [HttpPost("dispense/{id:int}/finalize")]
        public async Task<ActionResult<PharmacyChallanDetails>> Finalize(int id, [FromBody] PharmacyFinalizeDispenseRequest request)
        {
            try
            {
                var result = await _pharmacyService.FinalizeDispenseAsync(id, request, UserId);
                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error finalizing pharmacy dispense {ChallanId}", id);
                return StatusCode(500, new { message = "An error occurred while generating the challan." });
            }
        }

        [HttpGet("challans/{id:int}")]
        public async Task<ActionResult<PharmacyChallanDetails>> GetChallan(int id)
        {
            try
            {
                var result = await _pharmacyService.GetChallanByIdAsync(id);
                if (result == null)
                {
                    return NotFound(new { message = $"Challan with ID {id} not found." });
                }

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving pharmacy challan {ChallanId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the challan." });
            }
        }

        [HttpGet("lookups")]
        public async Task<ActionResult<PharmacyLookups>> GetLookups()
        {
            try
            {
                if (BranchId == null)
                {
                    return BadRequest(new { message = "No branch is associated with the current session." });
                }

                var result = await _pharmacyService.GetLookupsAsync(BranchId.Value);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving pharmacy lookups");
                return StatusCode(500, new { message = "An error occurred while retrieving lookups." });
            }
        }

        // ==================== Pharmacy Department Store ====================

        [HttpGet("department-store")]
        public async Task<ActionResult<IReadOnlyList<PharmacyDepartmentStoreMapping>>> GetDepartmentStoreMappings()
        {
            try
            {
                return Ok(await _pharmacyService.GetDepartmentStoreMappingsAsync());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving pharmacy department store mappings");
                return StatusCode(500, new { message = "An error occurred while retrieving department store mappings." });
            }
        }

        [HttpGet("departments")]
        public async Task<ActionResult<IReadOnlyList<PharmacyLookupItem>>> GetBranchDepartments()
        {
            try
            {
                if (BranchId == null)
                {
                    return BadRequest(new { message = "No branch is associated with the current session." });
                }

                return Ok(await _pharmacyService.GetBranchDepartmentsAsync(BranchId.Value));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving branch departments");
                return StatusCode(500, new { message = "An error occurred while retrieving departments." });
            }
        }

        [HttpPost("department-store")]
        public async Task<ActionResult<PharmacyDepartmentStoreMapping>> CreateDepartmentStoreMapping([FromBody] PharmacyDepartmentStoreMappingRequest request)
        {
            try
            {
                var result = await _pharmacyService.CreateDepartmentStoreMappingAsync(request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating pharmacy department store mapping");
                return StatusCode(500, new { message = "An error occurred while creating the mapping." });
            }
        }

        [HttpPut("department-store/{id:int}")]
        public async Task<ActionResult<PharmacyDepartmentStoreMapping>> UpdateDepartmentStoreMapping(int id, [FromBody] PharmacyDepartmentStoreMappingRequest request)
        {
            try
            {
                var result = await _pharmacyService.UpdateDepartmentStoreMappingAsync(id, request);
                if (result == null)
                {
                    return NotFound(new { message = $"Mapping with ID {id} not found." });
                }

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating pharmacy department store mapping {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the mapping." });
            }
        }

        [HttpDelete("department-store/{id:int}")]
        public async Task<ActionResult> DeleteDepartmentStoreMapping(int id)
        {
            try
            {
                var deleted = await _pharmacyService.DeleteDepartmentStoreMappingAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"Mapping with ID {id} not found." });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting pharmacy department store mapping {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the mapping." });
            }
        }

        // ==================== Refund Medicine ====================

        [HttpGet("refund/lines")]
        public async Task<ActionResult<IReadOnlyList<PharmacyRefundLineItem>>> GetRefundableLines([FromQuery] int storeId, [FromQuery] string challanNo)
        {
            try
            {
                return Ok(await _pharmacyService.GetRefundableLinesAsync(storeId, challanNo ?? string.Empty));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving refundable lines for challan {ChallanNo}", challanNo);
                return StatusCode(500, new { message = "An error occurred while retrieving refundable items." });
            }
        }

        [HttpPost("refund")]
        public async Task<ActionResult<PharmacyChallanDetails>> ProcessRefund([FromBody] PharmacyRefundRequest request)
        {
            try
            {
                var result = await _pharmacyService.ProcessRefundAsync(request, UserId);
                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing pharmacy refund");
                return StatusCode(500, new { message = "An error occurred while processing the refund." });
            }
        }

        // ==================== Daily Sale ====================

        [HttpGet("daily-sale")]
        public async Task<ActionResult<PharmacyDailySaleReport>> GetDailySale(
            [FromQuery] int? storeId, [FromQuery] DateTime? dateFrom, [FromQuery] DateTime? dateTo, [FromQuery] string? challanType,
            [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 10)
        {
            try
            {
                return Ok(await _pharmacyService.GetDailySaleAsync(storeId, dateFrom, dateTo, challanType, pageNumber, pageSize));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving pharmacy daily sale");
                return StatusCode(500, new { message = "An error occurred while retrieving the daily sale." });
            }
        }

        // ==================== Item Wise Sale ====================

        [HttpGet("item-wise-sale")]
        public async Task<ActionResult<PharmacyItemWiseSaleReport>> GetItemWiseSale(
            [FromQuery] int? storeId, [FromQuery] int? itemId, [FromQuery] DateTime? dateFrom, [FromQuery] DateTime? dateTo,
            [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 10)
        {
            try
            {
                return Ok(await _pharmacyService.GetItemWiseSaleAsync(storeId, itemId, dateFrom, dateTo, pageNumber, pageSize));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving pharmacy item wise sale");
                return StatusCode(500, new { message = "An error occurred while retrieving the item wise sale." });
            }
        }

        // ==================== Pharmacy Queue ====================

        [HttpGet("queue")]
        public async Task<ActionResult<IReadOnlyList<PharmacyQueueEntry>>> GetQueue([FromQuery] int storeId)
        {
            try
            {
                return Ok(await _pharmacyService.GetQueueAsync(storeId));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving pharmacy queue");
                return StatusCode(500, new { message = "An error occurred while retrieving the queue." });
            }
        }

        // ==================== Pharmacy Online Order ====================

        [HttpGet("online-orders")]
        public async Task<ActionResult<PagedResult<PharmacyOnlineOrderEntry>>> GetOnlineOrders(
            [FromQuery] DateTime? dateFrom, [FromQuery] DateTime? dateTo, [FromQuery] int? storeId, [FromQuery] string? status,
            [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 10)
        {
            try
            {
                return Ok(await _pharmacyService.GetOnlineOrdersAsync(dateFrom, dateTo, storeId, status, pageNumber, pageSize));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving pharmacy online orders");
                return StatusCode(500, new { message = "An error occurred while retrieving online orders." });
            }
        }

        // ==================== Pharmacy Dashboard ====================

        [HttpGet("dashboard")]
        public async Task<ActionResult<PharmacyDashboardSummary>> GetDashboard(
            [FromQuery] int? storeId, [FromQuery] DateTime? dateFrom, [FromQuery] DateTime? dateTo)
        {
            try
            {
                if (BranchId == null)
                {
                    return BadRequest(new { message = "No branch is associated with the current session." });
                }

                return Ok(await _pharmacyService.GetDashboardSummaryAsync(BranchId.Value, storeId, dateFrom, dateTo));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving pharmacy dashboard");
                return StatusCode(500, new { message = "An error occurred while retrieving the dashboard." });
            }
        }

        // ==================== Immunization ====================

        [HttpGet("vaccines")]
        public async Task<ActionResult<IReadOnlyList<PharmacyLookupItem>>> GetVaccines()
        {
            try
            {
                return Ok(await _pharmacyService.GetVaccinesAsync());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving vaccines");
                return StatusCode(500, new { message = "An error occurred while retrieving vaccines." });
            }
        }

        [HttpGet("immunizations")]
        public async Task<ActionResult<PagedResult<PharmacyVaccineRecord>>> GetVaccineRecords(
            [FromQuery] DateTime? dateFrom, [FromQuery] DateTime? dateTo, [FromQuery] int? patientId,
            [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 10)
        {
            try
            {
                return Ok(await _pharmacyService.GetVaccineRecordsAsync(dateFrom, dateTo, patientId, pageNumber, pageSize));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving immunization records");
                return StatusCode(500, new { message = "An error occurred while retrieving immunization records." });
            }
        }

        [HttpPost("immunizations")]
        public async Task<ActionResult<PharmacyVaccineRecord>> CreateVaccineRecord([FromBody] PharmacyVaccineCreateRequest request)
        {
            try
            {
                var result = await _pharmacyService.CreateVaccineRecordAsync(request, UserId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating immunization record");
                return StatusCode(500, new { message = "An error occurred while creating the immunization record." });
            }
        }
    }
}
