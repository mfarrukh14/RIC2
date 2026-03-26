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
        private readonly IConfiguration _configuration;
        private readonly ILogger<DatabaseInitializationService> _logger;
        private readonly string _connectionString;
        private readonly string _masterConnectionString;

        public DatabaseInitializationService(
            IConfiguration configuration,
            ILogger<DatabaseInitializationService> logger)
        {
            _configuration = configuration;
            _logger = logger;
            _connectionString = _configuration.GetConnectionString("DefaultConnection")!;
            
            // Create master connection string for database creation
            var builder = new SqlConnectionStringBuilder(_connectionString);
            var databaseName = builder.InitialCatalog;
            builder.InitialCatalog = "master";
            _masterConnectionString = builder.ConnectionString;
        }

        public async Task InitializeDatabaseAsync()
        {
            try
            {
                _logger.LogInformation("Starting database initialization...");

                // Check if database exists, if not create it
                await EnsureDatabaseExistsAsync();

                // Run all initialization scripts
                await ExecuteInitializationScriptsAsync();

                _logger.LogInformation("Database initialization completed successfully!");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during database initialization");
                throw;
            }
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

        private async Task ExecuteSqlScriptAsync(SqlConnection connection, string scriptPath)
        {
            var sqlScript = await File.ReadAllTextAsync(scriptPath);
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
                        else if (ex.Number == 1767 || ex.Number == 547) // FK constraint errors - referenced table may not exist yet
                        {
                            _logger.LogWarning($"Foreign key constraint issue in {Path.GetFileName(scriptPath)}: {ex.Message}. This may resolve when all tables are created.");
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

            normalized = normalized.Replace("dbo.Users", "dbo.StoreUsers", StringComparison.OrdinalIgnoreCase);
            normalized = normalized.Replace("name='Users'", "name='StoreUsers'", StringComparison.OrdinalIgnoreCase);
            normalized = normalized.Replace("name = 'Users'", "name = 'StoreUsers'", StringComparison.OrdinalIgnoreCase);
            normalized = normalized.Replace("CREATE TABLE Users", "CREATE TABLE StoreUsers", StringComparison.OrdinalIgnoreCase);
            normalized = normalized.Replace("INSERT INTO Users", "INSERT INTO StoreUsers", StringComparison.OrdinalIgnoreCase);
            normalized = normalized.Replace("REFERENCES Users(", "REFERENCES StoreUsers(", StringComparison.OrdinalIgnoreCase);

            return normalized;
        }
    }
}
