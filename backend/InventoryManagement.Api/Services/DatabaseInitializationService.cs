using Microsoft.Data.SqlClient;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public interface IDatabaseInitializationService
    {
        Task InitializeDatabaseAsync();
    }

    public class DatabaseInitializationService : IDatabaseInitializationService
    {
        private readonly ILogger<DatabaseInitializationService> _logger;
        private readonly IHostEnvironment _hostEnvironment;
        private readonly string _connectionString;
        private readonly string _masterConnectionString;
        private readonly bool _ensureDatabaseExists;
        private readonly bool _runScripts;

        public DatabaseInitializationService(
            IConfiguration configuration,
            IHostEnvironment hostEnvironment,
            ILogger<DatabaseInitializationService> logger)
        {
            _logger = logger;
            _hostEnvironment = hostEnvironment;
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

            // Create master connection string for database creation
            var builder = new SqlConnectionStringBuilder(_connectionString);
            var defaultBootstrapBehavior = hostEnvironment.IsDevelopment() && IsLocalSqlServerTarget(builder.DataSource);
            var databaseInitializationSection = configuration.GetSection("DatabaseInitialization");

            _ensureDatabaseExists = databaseInitializationSection.GetValue<bool?>("EnsureDatabaseExists")
                ?? defaultBootstrapBehavior;
            _runScripts = databaseInitializationSection.GetValue<bool?>("RunScripts")
                ?? defaultBootstrapBehavior;

            builder.InitialCatalog = "master";
            _masterConnectionString = builder.ConnectionString;
        }

        public async Task InitializeDatabaseAsync()
        {
            try
            {
                _logger.LogInformation("Starting database initialization...");

                var connectionDetails = new SqlConnectionStringBuilder(_connectionString);
                _logger.LogInformation(
                    "Database initialization target resolved to server '{Server}' and database '{Database}'. Content root: '{ContentRoot}'. Base directory: '{BaseDirectory}'. Working directory: '{WorkingDirectory}'.",
                    connectionDetails.DataSource,
                    connectionDetails.InitialCatalog,
                    _hostEnvironment.ContentRootPath,
                    AppContext.BaseDirectory,
                    Directory.GetCurrentDirectory());

                if (_ensureDatabaseExists)
                {
                    await EnsureDatabaseExistsAsync();
                }
                else
                {
                    _logger.LogInformation(
                        "Skipping database existence check for server '{Server}'. Set 'DatabaseInitialization:EnsureDatabaseExists' to true to enable it.",
                        connectionDetails.DataSource);
                }

                if (_runScripts)
                {
                    await ExecuteInitializationScriptsAsync();
                }
                else
                {
                    _logger.LogInformation(
                        "Skipping database script execution for server '{Server}'. Set 'DatabaseInitialization:RunScripts' to true to enable it.",
                        connectionDetails.DataSource);
                }

                _logger.LogInformation("Database initialization completed successfully!");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during database initialization");
                throw;
            }
        }

        private static bool IsLocalSqlServerTarget(string dataSource)
        {
            if (string.IsNullOrWhiteSpace(dataSource))
            {
                return false;
            }

            var normalizedDataSource = dataSource.Trim();
            var serverName = normalizedDataSource.Split(',', 2)[0].Split('\\', 2)[0].Trim();

            return serverName.Equals(".", StringComparison.OrdinalIgnoreCase)
                || serverName.Equals("(local)", StringComparison.OrdinalIgnoreCase)
                || serverName.Equals("10.10.10.67", StringComparison.OrdinalIgnoreCase)
                || serverName.Equals("127.0.0.1", StringComparison.OrdinalIgnoreCase)
                || serverName.Equals(Environment.MachineName, StringComparison.OrdinalIgnoreCase)
                || normalizedDataSource.StartsWith("(localdb)", StringComparison.OrdinalIgnoreCase);
        }

        private async Task EnsureDatabaseExistsAsync()
        {
            var builder = new SqlConnectionStringBuilder(_connectionString);
            var databaseName = builder.InitialCatalog;

            _logger.LogInformation($"Checking if database '{databaseName}' exists...");

            using var connection = new SqlConnection(_masterConnectionString);
            await connection.OpenAsync();

            var checkDbQuery = $"SELECT database_id FROM sys.databases WHERE Name = '{databaseName}'";
            using var checkCmd = new SqlCommand(checkDbQuery, connection);
            var result = await checkCmd.ExecuteScalarAsync();

            if (result == null)
            {
                _logger.LogInformation($"Database '{databaseName}' does not exist. Creating it...");
                var createDbQuery = $"CREATE DATABASE [{databaseName}]";
                using var createCmd = new SqlCommand(createDbQuery, connection);
                await createCmd.ExecuteNonQueryAsync();
                _logger.LogInformation($"Database '{databaseName}' created successfully.");
            }
            else
            {
                _logger.LogInformation($"Database '{databaseName}' already exists.");
            }
        }

        private async Task ExecuteInitializationScriptsAsync()
        {
            var baseDir = AppContext.BaseDirectory;
            var scriptsPath = Path.Combine(baseDir, "Database");

            if (!Directory.Exists(scriptsPath))
            {
                // Fallback for local dev when scripts are not copied to output yet.
                scriptsPath = Path.Combine(baseDir, "..", "..", "..", "..", "Database");
            }
            
            if (!Directory.Exists(scriptsPath))
            {
                _logger.LogWarning($"Database scripts directory not found at: {scriptsPath}");
                return;
            }

            _logger.LogInformation($"Looking for SQL scripts in: {scriptsPath}");

            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();

            var hasSharedManufacturerSurface = await HasCompatibleSharedManufacturersAsync(connection);
            if (hasSharedManufacturerSurface)
            {
                _logger.LogInformation("Detected shared manufacturer surface at 'Pharmacy.Manufacturers'; local manufacturer table creation scripts will be skipped.");
            }

            var hasSharedBrandSurface = await HasCompatibleSharedBrandsAsync(connection);
            if (hasSharedBrandSurface)
            {
                _logger.LogInformation("Detected shared brand surface at 'Data.Brands'; local brand table creation scripts will be skipped.");
            }

            // Phase 0: Run HMS setup script (creates views, missing tables, adds columns)
            var hmsSetupPath = Path.Combine(scriptsPath, "HMS", "HMS_Setup.sql");
            if (File.Exists(hmsSetupPath))
            {
                _logger.LogInformation("Phase 0: Executing HMS setup script...");
                try
                {
                    await ExecuteSqlScriptAsync(connection, hmsSetupPath, skipNormalization: true);
                    _logger.LogInformation("HMS setup script executed successfully.");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error executing HMS setup script");
                }
            }

            var executedRootScripts = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            // Phase 1: Execute root-level scripts in a preferred order (core tables first)
            var orderedRootScripts = new List<string>
            {
                "CreateDatabase.sql",
                "CreateItemLookupTables.sql",
                "CreateManufacturersTable.sql",
                "CreateBrandsTable.sql",
                "CreatePackingsTable.sql",
                "CreateItemTypesTable.sql",
                "CreateItemUnitsTable.sql",
                "CreateAssetAllocationsTable.sql"
            };

            _logger.LogInformation("Phase 1: Executing ordered root scripts...");
            foreach (var scriptFile in orderedRootScripts)
            {
                if (ShouldSkipRootScript(scriptFile, hasSharedManufacturerSurface, hasSharedBrandSurface))
                {
                    _logger.LogInformation("Skipping script: {ScriptFile} because a shared remote compatibility surface is available.", scriptFile);
                    continue;
                }

                var scriptPath = Path.Combine(scriptsPath, scriptFile);
                if (File.Exists(scriptPath))
                {
                    _logger.LogInformation($"Executing script: {scriptFile}");
                    try
                    {
                        await ExecuteSqlScriptAsync(connection, scriptPath);
                        executedRootScripts.Add(scriptFile);
                        _logger.LogInformation($"Successfully executed: {scriptFile}");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, $"Error executing script {scriptFile}");
                    }
                }
                else
                {
                    _logger.LogWarning($"Script not found: {scriptPath}");
                }
            }

            // Phase 2: Execute scripts from Tables subdirectory (includes prerequisite tables)
            await ExecuteTablesScriptsAsync(connection, scriptsPath);

            // Phase 3: Execute any remaining root-level scripts to avoid misses
            var remainingRootScripts = Directory.GetFiles(scriptsPath, "*.sql", SearchOption.TopDirectoryOnly)
                .Select(Path.GetFileName)
                .Where(fileName => !string.IsNullOrWhiteSpace(fileName))
                .Where(fileName => !executedRootScripts.Contains(fileName!))
                .OrderBy(fileName => fileName, StringComparer.OrdinalIgnoreCase)
                .ToList();

            _logger.LogInformation("Phase 3: Executing remaining root scripts...");
            foreach (var scriptFile in remainingRootScripts)
            {
                if (ShouldSkipRootScript(scriptFile!, hasSharedManufacturerSurface, hasSharedBrandSurface))
                {
                    _logger.LogInformation("Skipping script: {ScriptFile} because a shared remote compatibility surface is available.", scriptFile);
                    continue;
                }

                var scriptPath = Path.Combine(scriptsPath, scriptFile!);
                if (File.Exists(scriptPath))
                {
                    _logger.LogInformation($"Executing script: {scriptFile}");
                    try
                    {
                        await ExecuteSqlScriptAsync(connection, scriptPath);
                        executedRootScripts.Add(scriptFile!);
                        _logger.LogInformation($"Successfully executed: {scriptFile}");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, $"Error executing script {scriptFile}");
                    }
                }
                else
                {
                    _logger.LogWarning($"Script not found: {scriptPath}");
                }
            }

            // Phase 4: Execute ALTER table scripts (schema modifications)
            await ExecuteAlterScriptsAsync(connection, scriptsPath);

            // Phase 5: Execute stored procedure scripts
            await ExecuteStoredProcedureScriptsAsync(connection, scriptsPath);
        }

        private async Task ExecuteTablesScriptsAsync(SqlConnection connection, string scriptsPath)
        {
            var tablesPath = Path.Combine(scriptsPath, "Tables");
            if (!Directory.Exists(tablesPath))
            {
                _logger.LogWarning($"Tables directory not found at: {tablesPath}");
                return;
            }

            _logger.LogInformation($"Phase 2: Executing scripts from Tables directory...");
            
            // Define specific order for Tables scripts - prerequisite tables first!
            var tableScriptFiles = new List<string>
            {
                "CreateLookupTables.sql",
                "CreateStoresTable.sql", // MUST be before Inventories, PurchaseSummary, etc.
                "CreateStockTypesTable.sql", // MUST be before GRN and Inventories
                "CreateItemCategoriesTable.sql",
                "CreateItemsTable.sql",
                "CreateDemandRequestsTables.sql",
                "CreatePurchaseOrdersTable.sql",
                "CreatePurchaseOrderStatusesTable.sql",
                "CreateEstimatedPurchaseOrderSeed.sql",
                "CreateInventoryTables.sql", // Now Stores and StockTypes exist
                "CreateItemTypeSaleLevelsTable.sql",
                "CreateSurgicalItemGroupsTable.sql",
                "CreateSampleCollectionConsumptionItemsTable.sql",
                "CreatePurchaseSummaryTable.sql",
                "CreateDemandWiseValueSeed.sql",
                "CreatePurchaseSummaryInvoiceTable.sql",
                "CreateReturnInventoryTable.sql",
                "CreateContingentBillsTable.sql",
                "CreateRacksTable.sql",
                "CreateRackDrawersTable.sql",
                "CreateSpaceAllocationsTable.sql",
                "CreateStocksTable.sql",
                "CreateStockAuditsTable.sql",
                "CreateStoreAllocationToUserTable.sql",
                "StockTypeAssociations.sql"
            };

            foreach (var scriptFile in tableScriptFiles)
            {
                var scriptPath = Path.Combine(tablesPath, scriptFile);
                if (File.Exists(scriptPath))
                {
                    _logger.LogInformation($"Executing table script: {scriptFile}");
                    try
                    {
                        await ExecuteSqlScriptAsync(connection, scriptPath);
                        _logger.LogInformation($"Successfully executed: {scriptFile}");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, $"Error executing table script {scriptFile}");
                    }
                }
                else
                {
                    _logger.LogWarning($"Table script not found: {scriptPath}");
                }
            }
        }

        private static bool ShouldSkipRootScript(string scriptFile, bool hasSharedManufacturerSurface, bool hasSharedBrandSurface)
        {
            return (hasSharedManufacturerSurface
                    && scriptFile.Equals("CreateManufacturersTable.sql", StringComparison.OrdinalIgnoreCase))
                || (hasSharedBrandSurface
                    && scriptFile.Equals("CreateBrandsTable.sql", StringComparison.OrdinalIgnoreCase));
        }

        private static async Task<bool> HasCompatibleSharedManufacturersAsync(SqlConnection connection)
        {
            const string sql = @"
DECLARE @ManufacturersObjectId INT = OBJECT_ID('Pharmacy.Manufacturers');

SELECT CASE
    WHEN @ManufacturersObjectId IS NOT NULL
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ManufacturersObjectId AND name = 'ManufacturerId')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ManufacturersObjectId AND name = 'Name')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ManufacturersObjectId AND name = 'Description')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ManufacturersObjectId AND name = 'Email')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ManufacturersObjectId AND name = 'Address')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ManufacturersObjectId AND name = 'CreatedById')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ManufacturersObjectId AND name = 'CreatedOn')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ManufacturersObjectId AND name = 'ModifiedById')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ManufacturersObjectId AND name = 'ModifiedOn')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ManufacturersObjectId AND name = 'IsActive')
    THEN 1
    ELSE 0
END;";

            using var command = new SqlCommand(sql, connection);
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result) == 1;
        }

        private static async Task<bool> HasCompatibleSharedBrandsAsync(SqlConnection connection)
        {
            const string sql = @"
DECLARE @BrandsObjectId INT = OBJECT_ID('Data.Brands');

SELECT CASE
    WHEN @BrandsObjectId IS NOT NULL
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BrandsObjectId AND name = 'Id')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BrandsObjectId AND name = 'Name')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BrandsObjectId AND name = 'Description')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BrandsObjectId AND name = 'BranchId')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BrandsObjectId AND name = 'IsActive')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BrandsObjectId AND name = 'CreatedById')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BrandsObjectId AND name = 'CreatedOn')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BrandsObjectId AND name = 'ModifiedById')
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BrandsObjectId AND name = 'ModifiedOn')
    THEN 1
    ELSE 0
END;";

            using var command = new SqlCommand(sql, connection);
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result) == 1;
        }

        private async Task ExecuteAlterScriptsAsync(SqlConnection connection, string scriptsPath)
        {
            var tablesPath = Path.Combine(scriptsPath, "Tables");
            if (!Directory.Exists(tablesPath))
            {
                _logger.LogWarning($"Tables directory not found at: {tablesPath}");
                return;
            }

            _logger.LogInformation($"Phase 4: Executing ALTER table scripts...");
            
            // Execute all ALTER scripts in the Tables directory
            var alterScripts = Directory.GetFiles(tablesPath, "Alter*.sql");
            
            foreach (var scriptPath in alterScripts)
            {
                var fileName = Path.GetFileName(scriptPath);
                _logger.LogInformation($"Executing ALTER script: {fileName}");
                try
                {
                    await ExecuteSqlScriptAsync(connection, scriptPath);
                    _logger.LogInformation($"Successfully executed: {fileName}");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Error executing ALTER script {fileName}");
                    // Continue with other scripts even if one fails
                }
            }
        }

        private async Task ExecuteStoredProcedureScriptsAsync(SqlConnection connection, string basePath)
        {
            var spPath = Path.Combine(basePath, "StoredProcedures");
            if (!Directory.Exists(spPath))
            {
                _logger.LogWarning($"Stored procedures directory not found at: {spPath}");
                return;
            }

            var spFiles = Directory.GetFiles(spPath, "*.sql");
            _logger.LogInformation($"Found {spFiles.Length} stored procedure scripts.");

            // Execute stored procedures in a specific order if they exist
            var priorityScripts = new List<string>
            {
                "Item_LookupData.sql",
                "Country_GetAll.sql",
                "City_GetByStateOrProvince.sql",
                "Department_GetAll.sql"
            };

            // Execute priority scripts first
            foreach (var priorityScript in priorityScripts)
            {
                var scriptPath = Path.Combine(spPath, priorityScript);
                if (File.Exists(scriptPath))
                {
                    _logger.LogInformation($"Executing stored procedure: {priorityScript}");
                    try
                    {
                        await ExecuteSqlScriptAsync(connection, scriptPath);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, $"Error executing stored procedure {priorityScript}");
                    }
                }
            }

            // Then execute all other SP scripts
            foreach (var spFile in spFiles)
            {
                var fileName = Path.GetFileName(spFile);
                if (!priorityScripts.Contains(fileName))
                {
                    _logger.LogInformation($"Executing stored procedure: {fileName}");
                    try
                    {
                        await ExecuteSqlScriptAsync(connection, spFile);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, $"Error executing stored procedure {fileName}");
                    }
                }
            }
        }

        private async Task ExecuteSqlScriptAsync(SqlConnection connection, string scriptPath, bool skipNormalization = false)
        {
            var sqlScript = await File.ReadAllTextAsync(scriptPath);
            if (!skipNormalization)
                sqlScript = NormalizeScriptForSharedDatabase(sqlScript);
            
            // Split by GO statements (case-insensitive)
            var batches = System.Text.RegularExpressions.Regex.Split(
                sqlScript, 
                @"^\s*GO\s*$", 
                System.Text.RegularExpressions.RegexOptions.Multiline | System.Text.RegularExpressions.RegexOptions.IgnoreCase
            );

            foreach (var batch in batches)
            {
                var trimmedBatch = batch.Trim();
                if (!string.IsNullOrWhiteSpace(trimmedBatch))
                {
                    try
                    {
                        using var command = new SqlCommand(trimmedBatch, connection);
                        command.CommandTimeout = 120; // 2 minutes timeout
                        await command.ExecuteNonQueryAsync();
                    }
                    catch (SqlException ex)
                    {
                        // Log but continue if the object already exists or FK constraint issues (will retry)
                        if (ex.Number == 2714 || ex.Number == 2715 || ex.Number == 2716) // Object already exists
                        {
                            _logger.LogDebug($"Object already exists (continuing): {ex.Message}");
                        }
                        else if (ex.Number == 4902) // Cannot find column - already dropped or doesn't exist
                        {
                            _logger.LogDebug($"Column operation skipped (already applied or N/A): {ex.Message}");
                        }
                        else if (ex.Number == 2705) // Column names must be unique - already exists
                        {
                            _logger.LogDebug($"Column already exists (continuing): {ex.Message}");
                        }
                        else if (ex.Number == 207) // Invalid column name - HMS table has different column names
                        {
                            _logger.LogWarning($"Column name mismatch (HMS compatibility): {ex.Message}");
                        }
                        else if (ex.Number == 206) // Operand type clash - HMS table has different column types
                        {
                            _logger.LogWarning($"Type mismatch (HMS compatibility): {ex.Message}");
                        }
                        else if (ex.Number == 1767 || ex.Number == 547) // FK constraint errors - referenced table may not exist yet
                        {
                            _logger.LogWarning($"Foreign key constraint issue in {Path.GetFileName(scriptPath)}: {ex.Message}. This may resolve when all tables are created.");
                        }
                        else if (ex.Number == 2627 || ex.Number == 2601) // Duplicate key / unique constraint
                        {
                            _logger.LogDebug($"Duplicate key (seed data already exists): {ex.Message}");
                        }
                        else
                        {
                            _logger.LogError(ex, $"SQL Error executing batch from {Path.GetFileName(scriptPath)}");
                            throw;
                        }
                    }
                }
            }
        }

        private string NormalizeScriptForSharedDatabase(string script)
        {
            var builder = new SqlConnectionStringBuilder(_connectionString);
            var configuredDatabaseName = builder.InitialCatalog;

            var normalized = script;

            if (!string.IsNullOrWhiteSpace(configuredDatabaseName))
            {
                normalized = normalized.Replace("InventoryManagementDB_SP", configuredDatabaseName, StringComparison.OrdinalIgnoreCase);
            }

            // --- HMS Schema Remapping ---
            // All store-specific tables live in the Inv schema.
            // Lookup tables (Countries, Branches, etc.) are Inv schema views
            // that alias HMS column names to the names the SPs expect.

            // Store-specific tables → Inv schema
            var invTables = new[]
            {
                "Vendors", "Manufacturers", "Brands", "ItemTypes", "ItemUnits",
                "Packings", "Items", "Categories", "SubCategories", "Prices",
                "TaxRates", "TaxDescriptions", "TaxTypes", "TaxPayerCategories",
                "AccountCOAs", "Stores", "StockTypes", "Stocks",
                "Inventories", "InventoryDetails", "InventoryItems",
                "GoodsReceivingNotes", "GRNItems",
                "PurchaseOrders", "PurchaseOrderItems", "PurchaseOrderTypes",
                "PurchaseOrderStatus", "PurchaseOrderStatusItems",
                "StockConsumptions", "StockConsumptionDetails",
                "StockAdjustments", "StockAdjustmentDetails",
                "StockAudits", "StockAuditItems",
                "TransferInventory", "TransferInventoryItems",
                "ReturnInventory", "ReturnInventoryItems",
                "ContingentBills", "AssetAllocations",
                "DemandRequests", "DemandRequestStatus", "DemandRequestItems",
                "DemandRequestLifeCycles",
                "Racks", "RackRows", "RackColumns", "RackDrawers",
                "SpaceAllocations", "StoreAllocationToUser",
                "FinancialYears", "ItemTypeSaleLevels",
                "StockTypeAssociations", "ItemCategories",
                "PurchaseSummaries", "PurchaseSummaryInvoices",
                "EstimatedPurchaseOrders", "DemandWiseValues",
                "SurgicalItemGroups", "SampleCollectionConsumptionItems"
            };

            // Lookup tables backed by Inv views over HMS tables
            var viewTables = new[]
            {
                "Countries", "StateOrProvinces", "Branches", "Cities",
                "Departments", "SubDepartments", "Rooms"
            };

            // Replace schema-qualified references for store tables
            foreach (var table in invTables)
            {
                normalized = normalized.Replace($"[dbo].[{table}]", $"[Inv].[{table}]", StringComparison.OrdinalIgnoreCase);
                normalized = normalized.Replace($"dbo.{table}", $"Inv.{table}", StringComparison.OrdinalIgnoreCase);
            }

            // Replace schema-qualified references for view-backed lookup tables
            foreach (var table in viewTables)
            {
                normalized = normalized.Replace($"[dbo].[{table}]", $"[Inv].[{table}]", StringComparison.OrdinalIgnoreCase);
                normalized = normalized.Replace($"dbo.{table}", $"Inv.{table}", StringComparison.OrdinalIgnoreCase);
            }

            // Keep HMS user lookups on dbo.Users and map store-user links to the pharmacy table.
            normalized = normalized.Replace("dbo.StoreUsers", "Pharmacy.UserPharmacyStores", StringComparison.OrdinalIgnoreCase);
            normalized = normalized.Replace("[dbo].[StoreUsers]", "[Pharmacy].[UserPharmacyStores]", StringComparison.OrdinalIgnoreCase);

            // Fix IF NOT EXISTS checks to be schema-aware for Inv schema
            // Pattern: name='TableName' → add schema check
            foreach (var table in invTables.Concat(viewTables))
            {
                normalized = normalized.Replace(
                    $"name='{table}' AND xtype='U'",
                    $"name='{table}' AND xtype='U' AND uid = SCHEMA_ID('Inv')",
                    StringComparison.OrdinalIgnoreCase);
                normalized = normalized.Replace(
                    $"name = '{table}' AND xtype='U'",
                    $"name = '{table}' AND xtype='U' AND uid = SCHEMA_ID('Inv')",
                    StringComparison.OrdinalIgnoreCase);
            }

            // Fix sys.tables checks
            foreach (var table in invTables.Concat(viewTables))
            {
                // Handle: sys.tables WHERE name = 'X') - add schema_id check
                var oldCheck1 = $"sys.tables WHERE name = '{table}')";
                var newCheck1 = $"sys.tables WHERE name = '{table}' AND schema_id = SCHEMA_ID('Inv'))";
                normalized = normalized.Replace(oldCheck1, newCheck1, StringComparison.OrdinalIgnoreCase);

                var oldCheck2 = $"sys.tables WHERE name = '{table}' AND schema_id = SCHEMA_ID('dbo'))";
                var newCheck2 = $"sys.tables WHERE name = '{table}' AND schema_id = SCHEMA_ID('Inv'))";
                normalized = normalized.Replace(oldCheck2, newCheck2, StringComparison.OrdinalIgnoreCase);
            }

            // Fix bare table references in CREATE TABLE statements
            // CREATE TABLE TableName → CREATE TABLE Inv.TableName
            foreach (var table in invTables)
            {
                normalized = normalized.Replace($"CREATE TABLE {table} ", $"CREATE TABLE Inv.{table} ", StringComparison.OrdinalIgnoreCase);
                normalized = normalized.Replace($"CREATE TABLE {table}(", $"CREATE TABLE Inv.{table}(", StringComparison.OrdinalIgnoreCase);
                normalized = normalized.Replace($"INSERT INTO {table} ", $"INSERT INTO Inv.{table} ", StringComparison.OrdinalIgnoreCase);
                normalized = normalized.Replace($"INSERT INTO {table}(", $"INSERT INTO Inv.{table}(", StringComparison.OrdinalIgnoreCase);
                normalized = normalized.Replace($"FROM {table} ", $"FROM Inv.{table} ", StringComparison.OrdinalIgnoreCase);
                normalized = normalized.Replace($"REFERENCES {table}(", $"REFERENCES Inv.{table}(", StringComparison.OrdinalIgnoreCase);
            }

            // Route HMS-backed compatibility surfaces away from accidentally created Inv tables
            // after all schema normalization has run, including bare CREATE/INSERT references.
            normalized = RedirectInvCompatibilitySurface(normalized, "Manufacturers", "PharmacyManufacturers");
            normalized = RedirectInvCompatibilitySurface(normalized, "Brands", "DataBrands");
            normalized = RedirectInvCompatibilitySurface(normalized, "Stores", "PharmacyStores");
            normalized = RedirectInvCompatibilitySurface(normalized, "SurgicalItemGroups", "SurgicalGroups");

            // Remove FK constraints that reference tables not in Inv schema
            // (these will be handled at the application level)
            normalized = System.Text.RegularExpressions.Regex.Replace(
                normalized,
                @",?\s*CONSTRAINT\s+\[?FK_\w+\]?\s+FOREIGN\s+KEY\s*\([^)]+\)\s*REFERENCES\s+\S+\s*\([^)]+\)",
                "",
                System.Text.RegularExpressions.RegexOptions.IgnoreCase);

            // HMS table name typos: RackDrawers → RackDrawrs, RackDrawerId → RackDrawrId in SpaceAllocations
            normalized = normalized.Replace("Inv.RackDrawers", "Inv.RackDrawrs", StringComparison.OrdinalIgnoreCase);
            normalized = normalized.Replace("[Inv].[RackDrawers]", "[Inv].[RackDrawrs]", StringComparison.OrdinalIgnoreCase);

            return normalized;
        }

        private static string RedirectInvCompatibilitySurface(string script, string legacyName, string targetName)
        {
            var normalized = script.Replace(
                $"[Inv].[{legacyName}]",
                $"[Inv].[{targetName}]",
                StringComparison.OrdinalIgnoreCase);

            normalized = normalized.Replace(
                $"Inv.{legacyName}",
                $"Inv.{targetName}",
                StringComparison.OrdinalIgnoreCase);

            return normalized;
        }
    }
}
