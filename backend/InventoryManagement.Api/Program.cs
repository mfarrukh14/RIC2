using InventoryManagement.Api.Services;
using InventoryManagement.API.Services;

var builder = WebApplication.CreateBuilder(args);

// Expose Kestrel on all interfaces so other hosts can reach port 5100
builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(5100);
});

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
builder.Services.AddScoped<IStockTypeAssociationService, StockTypeAssociationService>();
builder.Services.AddScoped<IStockExpiringService, StockExpiringService>();
builder.Services.AddScoped<IRackService, RackService>();
builder.Services.AddScoped<IStockService, StockService>();
builder.Services.AddScoped<IStockAuditService, StockAuditService>();
builder.Services.AddScoped<IStockStatsService, StockStatsService>();
builder.Services.AddScoped<IStockAdjustmentService, StockAdjustmentService>();
builder.Services.AddScoped<IStockConsumptionService, StockConsumptionService>();
builder.Services.AddScoped<IStoreService, StoreService>();
builder.Services.AddScoped<IStockFlowService, StockFlowService>();
builder.Services.AddScoped<IExpiredStockService, ExpiredStockService>();
builder.Services.AddScoped<IStockValueItemService, StockValueItemService>();
builder.Services.AddScoped<IStockDetailRecordService, StockDetailRecordService>();
builder.Services.AddScoped<IStockBalanceReportService, StockBalanceReportService>();
builder.Services.AddScoped<ISaleSummaryDailyService, SaleSummaryDailyService>();
builder.Services.AddScoped<ISaleSummaryItemDiscountService, SaleSummaryItemDiscountService>();
builder.Services.AddScoped<ISaleSummaryStockNoDiscountService, SaleSummaryStockNoDiscountService>();
builder.Services.AddScoped<IRackDrawerService, RackDrawerService>();
builder.Services.AddScoped<IRackColumnService, RackColumnService>();
builder.Services.AddScoped<IRackRowService, RackRowService>();
builder.Services.AddScoped<ISpaceAllocationService, SpaceAllocationService>();
builder.Services.AddScoped<IStoreAllocationToUserService, StoreAllocationToUserService>();
builder.Services.AddScoped<IStockWithExpiryService, StockWithExpiryService>();
builder.Services.AddScoped<IBranchService, BranchService>();
builder.Services.AddScoped<IDemandRequestService, DemandRequestService>();
builder.Services.AddScoped<IDemandRequestStatusService, DemandRequestStatusService>();
builder.Services.AddScoped<IDemandWiseValueService, DemandWiseValueService>();
builder.Services.AddScoped<IPurchaseOrderService, PurchaseOrderService>();
builder.Services.AddScoped<IPurchaseOrderTypeService, PurchaseOrderTypeService>();
builder.Services.AddScoped<IPurchaseOrderStatusService, PurchaseOrderStatusService>();
builder.Services.AddScoped<IEstimatedPurchaseOrderService, EstimatedPurchaseOrderService>();

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

// Initialize database on startup unless explicitly skipped for local recovery runs.
var skipDatabaseInitialization = string.Equals(
    Environment.GetEnvironmentVariable("SKIP_DB_INIT"),
    "1",
    StringComparison.OrdinalIgnoreCase);

if (!skipDatabaseInitialization)
{
    using var scope = app.Services.CreateScope();
    var dbInitService = scope.ServiceProvider.GetRequiredService<IDatabaseInitializationService>();
    await dbInitService.InitializeDatabaseAsync();
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Enable CORS - must come before UseAuthorization
app.UseCors("AllowAll");

app.UseAuthorization();

app.MapControllers();

app.Run();