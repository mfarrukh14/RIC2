using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LocationController : BaseController
    {
        private readonly ILocationService _locationService;
        private readonly ILogger<LocationController> _logger;

        public LocationController(IUserSessionCacheService sessionCache, ILocationService locationService, ILogger<LocationController> logger)
            : base(sessionCache)
        {
            _locationService = locationService;
            _logger = logger;
        }

        [HttpGet("countries")]
        public async Task<ActionResult<IEnumerable<DropdownItem>>> GetCountries()
        {
            try
            {
                var countries = await _locationService.GetCountriesAsync();
                return Ok(countries);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving countries");
                return StatusCode(500, new { message = "An error occurred while retrieving countries" });
            }
        }

        [HttpGet("provinces")]
        public async Task<ActionResult<IEnumerable<DropdownItem>>> GetProvinces([FromQuery] int countryId)
        {
            if (countryId <= 0)
            {
                return Ok(Array.Empty<DropdownItem>());
            }

            try
            {
                var provinces = await _locationService.GetProvincesByCountryAsync(countryId);
                return Ok(provinces);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving provinces for country {CountryId}", countryId);
                return StatusCode(500, new { message = "An error occurred while retrieving provinces" });
            }
        }

        [HttpGet("cities")]
        public async Task<ActionResult<IEnumerable<DropdownItem>>> GetCities([FromQuery] int provinceId)
        {
            if (provinceId <= 0)
            {
                return Ok(Array.Empty<DropdownItem>());
            }

            try
            {
                var cities = await _locationService.GetCitiesByProvinceAsync(provinceId);
                return Ok(cities);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving cities for province {ProvinceId}", provinceId);
                return StatusCode(500, new { message = "An error occurred while retrieving cities" });
            }
        }
    }
}
