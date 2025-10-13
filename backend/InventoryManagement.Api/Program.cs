using InventoryManagement.Api.Services;
using InventoryManagement.API.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add database initialization service
builder.Services.AddSingleton<IDatabaseInitializationService, DatabaseInitializationService>();

// Add services (using stored procedures instead of Entity Framework)
builder.Services.AddScoped<IVendorService, VendorServiceSP>();
builder.Services.AddScoped<IManufacturerService, ManufacturerServiceSP>();
builder.Services.AddScoped<IBrandService, BrandServiceSP>();
builder.Services.AddScoped<IPackingService, PackingServiceSP>();
builder.Services.AddScoped<IItemTypeService, ItemTypeServiceSP>();
builder.Services.AddScoped<IItemUnitService, ItemUnitServiceSP>();
builder.Services.AddScoped<IAssetAllocationService, AssetAllocationService>();
builder.Services.AddScoped<IItemService, ItemService>();
builder.Services.AddScoped<IInventoryService, InventoryService>();
builder.Services.AddScoped<IGRNService, GRNService>();
builder.Services.AddScoped<ITransferInventoryService, TransferInventoryService>();
builder.Services.AddScoped<IReturnInventoryService, ReturnInventoryService>();
builder.Services.AddScoped<IPurchaseSummaryService, PurchaseSummaryService>();
builder.Services.AddScoped<IPurchaseSummaryInvoiceService, PurchaseSummaryInvoiceService>();
builder.Services.AddScoped<ISampleCollectionConsumptionItemService, SampleCollectionConsumptionItemService>();
builder.Services.AddScoped<ISurgicalItemGroupService, SurgicalItemGroupService>();
builder.Services.AddScoped<IItemTypeSaleLevelService, ItemTypeSaleLevelService>();
builder.Services.AddScoped<IContingentBillService, ContingentBillService>();
builder.Services.AddScoped<IStockTypeService, StockTypeService>();

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Initialize database on startup
using (var scope = app.Services.CreateScope())
{
    var dbInitService = scope.ServiceProvider.GetRequiredService<IDatabaseInitializationService>();
    await dbInitService.InitializeDatabaseAsync();
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Enable CORS - must come before UseAuthorization
app.UseCors("AllowAll");

app.UseAuthorization();

app.MapControllers();

app.Run();