-- =============================================
-- HMS Database Setup for Store/Inventory Module
-- Creates compatibility views for HMS lookup tables
-- and missing tables in Inv schema
-- =============================================

-- Ensure Inv schema exists
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Inv')
    EXEC('CREATE SCHEMA Inv');
GO

-- =============================================
-- PHASE 1: Compatibility Views
-- These present HMS tables with column names
-- the store module stored procedures expect
-- =============================================

-- Countries view
IF OBJECT_ID('Inv.Countries', 'V') IS NOT NULL DROP VIEW Inv.Countries;
GO
DECLARE @CountriesSource NVARCHAR(200) = CASE
    WHEN (OBJECT_ID('Dropdown.dd_Countries', 'U') IS NOT NULL OR OBJECT_ID('Dropdown.dd_Countries', 'V') IS NOT NULL)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Countries') AND name IN ('Id', 'ID', 'CountryId', 'CountryID'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Countries') AND name IN ('Name', 'CountryName'))
        THEN 'Dropdown.dd_Countries'
    WHEN (OBJECT_ID('Dropdown.dd_Country', 'U') IS NOT NULL OR OBJECT_ID('Dropdown.dd_Country', 'V') IS NOT NULL)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Country') AND name IN ('Id', 'ID', 'CountryId', 'CountryID'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Country') AND name IN ('Name', 'CountryName'))
        THEN 'Dropdown.dd_Country'
    ELSE 'dbo.Countries'
END;

DECLARE @CountriesObjectId INT = OBJECT_ID(@CountriesSource);
DECLARE @CountriesIdColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CountriesObjectId AND name = 'Id') THEN 'Id'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CountriesObjectId AND name = 'ID') THEN 'ID'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CountriesObjectId AND name = 'CountryId') THEN 'CountryId'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CountriesObjectId AND name = 'CountryID') THEN 'CountryID'
    ELSE NULL
END;
DECLARE @CountriesNameColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CountriesObjectId AND name = 'Name') THEN 'Name'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CountriesObjectId AND name = 'CountryName') THEN 'CountryName'
    ELSE NULL
END;
DECLARE @CountriesCodeColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CountriesObjectId AND name = 'Code') THEN 'Code'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CountriesObjectId AND name = 'CountryCode') THEN 'CountryCode'
    ELSE NULL
END;
DECLARE @CountriesStatusColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CountriesObjectId AND name = 'IsActive') THEN 'IsActive'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CountriesObjectId AND name = 'Status') THEN 'Status'
    ELSE NULL
END;
DECLARE @CountriesCreatedOnColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CountriesObjectId AND name = 'CreatedOn') THEN 'CreatedOn'
    ELSE NULL
END;
DECLARE @CountriesModifiedOnColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CountriesObjectId AND name = 'ModifiedOn') THEN 'ModifiedOn'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CountriesObjectId AND name = 'UpdatedOn') THEN 'UpdatedOn'
    ELSE NULL
END;

DECLARE @CountriesSql NVARCHAR(MAX) = N'CREATE VIEW Inv.Countries AS
SELECT
    ' + QUOTENAME(@CountriesIdColumn) + N' AS Id,
    ' + QUOTENAME(@CountriesNameColumn) + N' AS Name,
    ' + COALESCE(QUOTENAME(@CountriesCodeColumn), N'CAST(NULL AS NVARCHAR(50))') + N' AS Code,
    ' + CASE
        WHEN @CountriesStatusColumn IS NULL THEN N'CAST(1 AS BIT)'
        WHEN @CountriesStatusColumn = 'Status' THEN N'CAST(CASE WHEN [Status] IS NULL OR [Status] = 1 THEN 1 ELSE 0 END AS BIT)'
        ELSE N'CAST(ISNULL(' + QUOTENAME(@CountriesStatusColumn) + N', 1) AS BIT)'
    END + N' AS IsActive,
    ' + COALESCE(QUOTENAME(@CountriesCreatedOnColumn), N'CAST(NULL AS DATETIME)') + N' AS CreatedOn,
    ' + COALESCE(QUOTENAME(@CountriesModifiedOnColumn), N'CAST(NULL AS DATETIME)') + N' AS ModifiedOn
FROM ' + @CountriesSource + N';';

EXEC sys.sp_executesql @CountriesSql;
GO

-- StateOrProvinces view (HMS uses dbo.Provinces)
IF OBJECT_ID('Inv.StateOrProvinces', 'V') IS NOT NULL DROP VIEW Inv.StateOrProvinces;
GO
DECLARE @ProvincesSource NVARCHAR(200) = CASE
    WHEN (OBJECT_ID('Dropdown.dd_StateOrProvinces', 'U') IS NOT NULL OR OBJECT_ID('Dropdown.dd_StateOrProvinces', 'V') IS NOT NULL)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_StateOrProvinces') AND name IN ('Id', 'ID', 'ProvinceId', 'ProvinceID'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_StateOrProvinces') AND name IN ('Name', 'ProvinceName'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_StateOrProvinces') AND name IN ('CountryId', 'CountryID'))
        THEN 'Dropdown.dd_StateOrProvinces'
    WHEN (OBJECT_ID('Dropdown.dd_StateOrProvince', 'U') IS NOT NULL OR OBJECT_ID('Dropdown.dd_StateOrProvince', 'V') IS NOT NULL)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_StateOrProvince') AND name IN ('Id', 'ID', 'ProvinceId', 'ProvinceID'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_StateOrProvince') AND name IN ('Name', 'ProvinceName'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_StateOrProvince') AND name IN ('CountryId', 'CountryID'))
        THEN 'Dropdown.dd_StateOrProvince'
    WHEN (OBJECT_ID('Dropdown.dd_Provinces', 'U') IS NOT NULL OR OBJECT_ID('Dropdown.dd_Provinces', 'V') IS NOT NULL)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Provinces') AND name IN ('Id', 'ID', 'ProvinceId', 'ProvinceID'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Provinces') AND name IN ('Name', 'ProvinceName'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Provinces') AND name IN ('CountryId', 'CountryID'))
        THEN 'Dropdown.dd_Provinces'
    WHEN (OBJECT_ID('Dropdown.dd_Province', 'U') IS NOT NULL OR OBJECT_ID('Dropdown.dd_Province', 'V') IS NOT NULL)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Province') AND name IN ('Id', 'ID', 'ProvinceId', 'ProvinceID'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Province') AND name IN ('Name', 'ProvinceName'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Province') AND name IN ('CountryId', 'CountryID'))
        THEN 'Dropdown.dd_Province'
    ELSE 'dbo.Provinces'
END;

DECLARE @ProvincesObjectId INT = OBJECT_ID(@ProvincesSource);
DECLARE @ProvincesIdColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'Id') THEN 'Id'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'ID') THEN 'ID'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'ProvinceId') THEN 'ProvinceId'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'ProvinceID') THEN 'ProvinceID'
    ELSE NULL
END;
DECLARE @ProvincesNameColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'Name') THEN 'Name'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'ProvinceName') THEN 'ProvinceName'
    ELSE NULL
END;
DECLARE @ProvincesCountryIdColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'CountryId') THEN 'CountryId'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'CountryID') THEN 'CountryID'
    ELSE NULL
END;
DECLARE @ProvincesCodeColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'Code') THEN 'Code'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'ProvinceCode') THEN 'ProvinceCode'
    ELSE NULL
END;
DECLARE @ProvincesStatusColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'IsActive') THEN 'IsActive'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'Status') THEN 'Status'
    ELSE NULL
END;
DECLARE @ProvincesCreatedOnColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'CreatedOn') THEN 'CreatedOn'
    ELSE NULL
END;
DECLARE @ProvincesModifiedOnColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'ModifiedOn') THEN 'ModifiedOn'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @ProvincesObjectId AND name = 'UpdatedOn') THEN 'UpdatedOn'
    ELSE NULL
END;

DECLARE @ProvincesSql NVARCHAR(MAX) = N'CREATE VIEW Inv.StateOrProvinces AS
SELECT
    ' + QUOTENAME(@ProvincesIdColumn) + N' AS Id,
    ' + QUOTENAME(@ProvincesNameColumn) + N' AS Name,
    ' + COALESCE(QUOTENAME(@ProvincesCountryIdColumn), N'CAST(NULL AS INT)') + N' AS CountryId,
    ' + COALESCE(QUOTENAME(@ProvincesCodeColumn), N'CAST(NULL AS NVARCHAR(50))') + N' AS Code,
    ' + CASE
        WHEN @ProvincesStatusColumn IS NULL THEN N'CAST(1 AS BIT)'
        WHEN @ProvincesStatusColumn = 'Status' THEN N'CAST(CASE WHEN [Status] IS NULL OR [Status] = 1 THEN 1 ELSE 0 END AS BIT)'
        ELSE N'CAST(ISNULL(' + QUOTENAME(@ProvincesStatusColumn) + N', 1) AS BIT)'
    END + N' AS IsActive,
    ' + COALESCE(QUOTENAME(@ProvincesCreatedOnColumn), N'CAST(NULL AS DATETIME)') + N' AS CreatedOn,
    ' + COALESCE(QUOTENAME(@ProvincesModifiedOnColumn), N'CAST(NULL AS DATETIME)') + N' AS ModifiedOn
FROM ' + @ProvincesSource + N';';

EXEC sys.sp_executesql @ProvincesSql;
GO

-- Cities view
IF OBJECT_ID('Inv.Cities', 'V') IS NOT NULL DROP VIEW Inv.Cities;
GO
DECLARE @CitiesSource NVARCHAR(200) = CASE
    WHEN (OBJECT_ID('Dropdown.dd_Cities', 'U') IS NOT NULL OR OBJECT_ID('Dropdown.dd_Cities', 'V') IS NOT NULL)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Cities') AND name IN ('Id', 'ID', 'CityId', 'CityID'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Cities') AND name IN ('Name', 'CityName'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Cities') AND name IN ('StateOrProvinceId', 'ProvinceId', 'ProvinceID'))
        THEN 'Dropdown.dd_Cities'
    WHEN (OBJECT_ID('Dropdown.dd_City', 'U') IS NOT NULL OR OBJECT_ID('Dropdown.dd_City', 'V') IS NOT NULL)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_City') AND name IN ('Id', 'ID', 'CityId', 'CityID'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_City') AND name IN ('Name', 'CityName'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_City') AND name IN ('StateOrProvinceId', 'ProvinceId', 'ProvinceID'))
        THEN 'Dropdown.dd_City'
    ELSE 'dbo.Cities'
END;

DECLARE @CitiesObjectId INT = OBJECT_ID(@CitiesSource);
DECLARE @CitiesIdColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CitiesObjectId AND name = 'Id') THEN 'Id'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CitiesObjectId AND name = 'ID') THEN 'ID'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CitiesObjectId AND name = 'CityId') THEN 'CityId'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CitiesObjectId AND name = 'CityID') THEN 'CityID'
    ELSE NULL
END;
DECLARE @CitiesNameColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CitiesObjectId AND name = 'Name') THEN 'Name'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CitiesObjectId AND name = 'CityName') THEN 'CityName'
    ELSE NULL
END;
DECLARE @CitiesProvinceIdColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CitiesObjectId AND name = 'StateOrProvinceId') THEN 'StateOrProvinceId'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CitiesObjectId AND name = 'ProvinceId') THEN 'ProvinceId'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CitiesObjectId AND name = 'ProvinceID') THEN 'ProvinceID'
    ELSE NULL
END;
DECLARE @CitiesStatusColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CitiesObjectId AND name = 'IsActive') THEN 'IsActive'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CitiesObjectId AND name = 'Status') THEN 'Status'
    ELSE NULL
END;
DECLARE @CitiesCreatedOnColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CitiesObjectId AND name = 'CreatedOn') THEN 'CreatedOn'
    ELSE NULL
END;
DECLARE @CitiesModifiedOnColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CitiesObjectId AND name = 'ModifiedOn') THEN 'ModifiedOn'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @CitiesObjectId AND name = 'UpdatedOn') THEN 'UpdatedOn'
    ELSE NULL
END;

DECLARE @CitiesSql NVARCHAR(MAX) = N'CREATE VIEW Inv.Cities AS
SELECT
    ' + QUOTENAME(@CitiesIdColumn) + N' AS Id,
    ' + QUOTENAME(@CitiesNameColumn) + N' AS Name,
    ' + COALESCE(QUOTENAME(@CitiesProvinceIdColumn), N'CAST(NULL AS INT)') + N' AS StateOrProvinceId,
    ' + CASE
        WHEN @CitiesStatusColumn IS NULL THEN N'CAST(1 AS BIT)'
        WHEN @CitiesStatusColumn = 'Status' THEN N'CAST(CASE WHEN [Status] IS NULL OR [Status] = 1 THEN 1 ELSE 0 END AS BIT)'
        ELSE N'CAST(ISNULL(' + QUOTENAME(@CitiesStatusColumn) + N', 1) AS BIT)'
    END + N' AS IsActive,
    ' + COALESCE(QUOTENAME(@CitiesCreatedOnColumn), N'CAST(NULL AS DATETIME)') + N' AS CreatedOn,
    ' + COALESCE(QUOTENAME(@CitiesModifiedOnColumn), N'CAST(NULL AS DATETIME)') + N' AS ModifiedOn
FROM ' + @CitiesSource + N';';

EXEC sys.sp_executesql @CitiesSql;
GO

-- Branches view (HMS uses dbo.Branch)
IF OBJECT_ID('Inv.Branches', 'V') IS NOT NULL DROP VIEW Inv.Branches;
GO
DECLARE @BranchesSource NVARCHAR(200) = CASE
    WHEN (OBJECT_ID('Dropdown.dd_Branches', 'U') IS NOT NULL OR OBJECT_ID('Dropdown.dd_Branches', 'V') IS NOT NULL)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Branches') AND name IN ('Id', 'ID', 'BranchId'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Branches') AND name IN ('Name', 'BranchName'))
        THEN 'Dropdown.dd_Branches'
    WHEN (OBJECT_ID('Dropdown.dd_Branch', 'U') IS NOT NULL OR OBJECT_ID('Dropdown.dd_Branch', 'V') IS NOT NULL)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Branch') AND name IN ('Id', 'ID', 'BranchId'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Branch') AND name IN ('Name', 'BranchName'))
        THEN 'Dropdown.dd_Branch'
    ELSE 'dbo.Branch'
END;

DECLARE @BranchesObjectId INT = OBJECT_ID(@BranchesSource);
DECLARE @BranchesIdColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'BranchId') THEN 'BranchId'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'Id') THEN 'Id'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'ID') THEN 'ID'
    ELSE NULL
END;
DECLARE @BranchesNameColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'Name') THEN 'Name'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'BranchName') THEN 'BranchName'
    ELSE NULL
END;
DECLARE @BranchesCodeColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'Code') THEN 'Code'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'BranchCode') THEN 'BranchCode'
    ELSE NULL
END;
DECLARE @BranchesAddressColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'Address') THEN 'Address'
    ELSE NULL
END;
DECLARE @BranchesCityIdColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'CityId') THEN 'CityId'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'CityID') THEN 'CityID'
    ELSE NULL
END;
DECLARE @BranchesStatusColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'IsActive') THEN 'IsActive'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'Status') THEN 'Status'
    ELSE NULL
END;
DECLARE @BranchesCreatedOnColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'CreatedOn') THEN 'CreatedOn'
    ELSE NULL
END;
DECLARE @BranchesModifiedOnColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'ModifiedOn') THEN 'ModifiedOn'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @BranchesObjectId AND name = 'UpdatedOn') THEN 'UpdatedOn'
    ELSE NULL
END;

DECLARE @BranchesSql NVARCHAR(MAX) = N'CREATE VIEW Inv.Branches AS
SELECT
    ' + QUOTENAME(@BranchesIdColumn) + N' AS Id,
    ' + QUOTENAME(@BranchesNameColumn) + N' AS Name,
    ' + COALESCE(QUOTENAME(@BranchesCodeColumn), N'CAST(NULL AS NVARCHAR(50))') + N' AS Code,
    ' + COALESCE(QUOTENAME(@BranchesAddressColumn), N'CAST(NULL AS NVARCHAR(500))') + N' AS Address,
    ' + COALESCE(QUOTENAME(@BranchesCityIdColumn), N'CAST(NULL AS INT)') + N' AS CityId,
    ' + CASE
        WHEN @BranchesStatusColumn IS NULL THEN N'CAST(1 AS BIT)'
        WHEN @BranchesStatusColumn = 'Status' THEN N'CAST(CASE WHEN [Status] IS NULL OR [Status] = 1 THEN 1 ELSE 0 END AS BIT)'
        ELSE N'CAST(ISNULL(' + QUOTENAME(@BranchesStatusColumn) + N', 1) AS BIT)'
    END + N' AS IsActive,
    ' + COALESCE(QUOTENAME(@BranchesCreatedOnColumn), N'CAST(NULL AS DATETIME)') + N' AS CreatedOn,
    ' + COALESCE(QUOTENAME(@BranchesModifiedOnColumn), N'CAST(NULL AS DATETIME)') + N' AS ModifiedOn
FROM ' + @BranchesSource + N';';

EXEC sys.sp_executesql @BranchesSql;
GO

-- Departments view
IF OBJECT_ID('Inv.Departments', 'V') IS NOT NULL DROP VIEW Inv.Departments;
GO
DECLARE @DepartmentsSource NVARCHAR(200) = CASE
    WHEN (OBJECT_ID('Dropdown.dd_Departments', 'U') IS NOT NULL OR OBJECT_ID('Dropdown.dd_Departments', 'V') IS NOT NULL)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Departments') AND name IN ('Id', 'DID', 'DepartmentId'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Departments') AND name IN ('Name', 'DepartmentName'))
        THEN 'Dropdown.dd_Departments'
    WHEN (OBJECT_ID('Dropdown.dd_Department', 'U') IS NOT NULL OR OBJECT_ID('Dropdown.dd_Department', 'V') IS NOT NULL)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Department') AND name IN ('Id', 'DID', 'DepartmentId'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_Department') AND name IN ('Name', 'DepartmentName'))
        THEN 'Dropdown.dd_Department'
    ELSE 'dbo.Departments'
END;

DECLARE @DepartmentsObjectId INT = OBJECT_ID(@DepartmentsSource);
DECLARE @DepartmentsIdColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @DepartmentsObjectId AND name = 'DID') THEN 'DID'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @DepartmentsObjectId AND name = 'DepartmentId') THEN 'DepartmentId'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @DepartmentsObjectId AND name = 'Id') THEN 'Id'
    ELSE NULL
END;
DECLARE @DepartmentsNameColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @DepartmentsObjectId AND name = 'Name') THEN 'Name'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @DepartmentsObjectId AND name = 'DepartmentName') THEN 'DepartmentName'
    ELSE NULL
END;
DECLARE @DepartmentsDescriptionColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @DepartmentsObjectId AND name = 'Description') THEN 'Description'
    ELSE NULL
END;
DECLARE @DepartmentsHeadColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @DepartmentsObjectId AND name = 'Head') THEN 'Head'
    ELSE NULL
END;
DECLARE @DepartmentsStatusColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @DepartmentsObjectId AND name = 'IsActive') THEN 'IsActive'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @DepartmentsObjectId AND name = 'Status') THEN 'Status'
    ELSE NULL
END;

DECLARE @DepartmentsSql NVARCHAR(MAX) = N'CREATE VIEW Inv.Departments AS
SELECT
    ' + QUOTENAME(@DepartmentsIdColumn) + N' AS Id,
    ' + QUOTENAME(@DepartmentsNameColumn) + N' AS Name,
    ' + COALESCE(QUOTENAME(@DepartmentsDescriptionColumn), N'CAST(NULL AS NVARCHAR(MAX))') + N' AS Description,
    ' + COALESCE(QUOTENAME(@DepartmentsHeadColumn), N'CAST(NULL AS NVARCHAR(200))') + N' AS Head,
    ' + CASE
        WHEN @DepartmentsStatusColumn IS NULL THEN N'CAST(1 AS BIT)'
        WHEN @DepartmentsStatusColumn = 'Status' THEN N'CAST(CASE WHEN [Status] IS NULL OR [Status] = 1 THEN 1 ELSE 0 END AS BIT)'
        ELSE N'CAST(ISNULL(' + QUOTENAME(@DepartmentsStatusColumn) + N', 1) AS BIT)'
    END + N' AS IsActive
FROM ' + @DepartmentsSource + N';';

EXEC sys.sp_executesql @DepartmentsSql;
GO

-- SubDepartments view
IF OBJECT_ID('Inv.SubDepartments', 'V') IS NOT NULL DROP VIEW Inv.SubDepartments;
GO
DECLARE @SubDepartmentsSource NVARCHAR(200) = CASE
    WHEN (OBJECT_ID('Dropdown.dd_SubDepartments', 'U') IS NOT NULL OR OBJECT_ID('Dropdown.dd_SubDepartments', 'V') IS NOT NULL)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_SubDepartments') AND name IN ('Id', 'SubDID', 'SubDepartmentId'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_SubDepartments') AND name IN ('Name', 'SubDepartmentName'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_SubDepartments') AND name IN ('DepartmentId', 'DID'))
        THEN 'Dropdown.dd_SubDepartments'
    WHEN (OBJECT_ID('Dropdown.dd_SubDepartment', 'U') IS NOT NULL OR OBJECT_ID('Dropdown.dd_SubDepartment', 'V') IS NOT NULL)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_SubDepartment') AND name IN ('Id', 'SubDID', 'SubDepartmentId'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_SubDepartment') AND name IN ('Name', 'SubDepartmentName'))
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Dropdown.dd_SubDepartment') AND name IN ('DepartmentId', 'DID'))
        THEN 'Dropdown.dd_SubDepartment'
    ELSE 'dbo.SubDepartments'
END;

DECLARE @SubDepartmentsObjectId INT = OBJECT_ID(@SubDepartmentsSource);
DECLARE @SubDepartmentsIdColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @SubDepartmentsObjectId AND name = 'SubDID') THEN 'SubDID'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @SubDepartmentsObjectId AND name = 'SubDepartmentId') THEN 'SubDepartmentId'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @SubDepartmentsObjectId AND name = 'Id') THEN 'Id'
    ELSE NULL
END;
DECLARE @SubDepartmentsNameColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @SubDepartmentsObjectId AND name = 'Name') THEN 'Name'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @SubDepartmentsObjectId AND name = 'SubDepartmentName') THEN 'SubDepartmentName'
    ELSE NULL
END;
DECLARE @SubDepartmentsDescriptionColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @SubDepartmentsObjectId AND name = 'Description') THEN 'Description'
    ELSE NULL
END;
DECLARE @SubDepartmentsDepartmentIdColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @SubDepartmentsObjectId AND name = 'DID') THEN 'DID'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @SubDepartmentsObjectId AND name = 'DepartmentId') THEN 'DepartmentId'
    ELSE NULL
END;
DECLARE @SubDepartmentsStatusColumn SYSNAME = CASE
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @SubDepartmentsObjectId AND name = 'IsActive') THEN 'IsActive'
    WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @SubDepartmentsObjectId AND name = 'Status') THEN 'Status'
    ELSE NULL
END;

DECLARE @SubDepartmentsSql NVARCHAR(MAX) = N'CREATE VIEW Inv.SubDepartments AS
SELECT
    ' + QUOTENAME(@SubDepartmentsIdColumn) + N' AS Id,
    ' + QUOTENAME(@SubDepartmentsNameColumn) + N' AS Name,
    ' + COALESCE(QUOTENAME(@SubDepartmentsDescriptionColumn), N'CAST(NULL AS NVARCHAR(MAX))') + N' AS Description,
    ' + COALESCE(QUOTENAME(@SubDepartmentsDepartmentIdColumn), N'CAST(NULL AS INT)') + N' AS DepartmentId,
    ' + CASE
        WHEN @SubDepartmentsStatusColumn IS NULL THEN N'CAST(1 AS BIT)'
        WHEN @SubDepartmentsStatusColumn = 'Status' THEN N'CAST(CASE WHEN [Status] IS NULL OR [Status] = 1 THEN 1 ELSE 0 END AS BIT)'
        ELSE N'CAST(ISNULL(' + QUOTENAME(@SubDepartmentsStatusColumn) + N', 1) AS BIT)'
    END + N' AS IsActive
FROM ' + @SubDepartmentsSource + N';';

EXEC sys.sp_executesql @SubDepartmentsSql;
GO

-- Store-user assignments already live in Pharmacy.UserPharmacyStores.
-- Keep dbo.Users as the HMS user source and remove the old wrong compatibility view.
IF OBJECT_ID('Inv.StoreUsers', 'V') IS NOT NULL DROP VIEW Inv.StoreUsers;
GO

-- Rooms view
IF OBJECT_ID('Inv.Rooms', 'V') IS NOT NULL DROP VIEW Inv.Rooms;
GO
CREATE VIEW Inv.Rooms AS
SELECT 
    RID AS Id,
    Name,
    Description,
    CAST(NULL AS NVARCHAR(200)) AS Floor,
    CAST(NULL AS NVARCHAR(200)) AS Building,
    Capacity,
    ISNULL(IsActive, CAST(1 AS BIT)) AS IsActive
FROM dbo.Rooms;
GO

-- =============================================
-- PHASE 2: Create missing tables in Inv schema
-- Only creates tables that do NOT already exist
-- =============================================

-- Vendors table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Vendors' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Vendors (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        Email NVARCHAR(MAX) NULL,
        CNo NVARCHAR(MAX) NULL,
        Address NVARCHAR(MAX) NULL,
        NTN NVARCHAR(MAX) NULL,
        STN NVARCHAR(MAX) NULL,
        CPName1 NVARCHAR(MAX) NULL,
        CPEmail1 NVARCHAR(MAX) NULL,
        CPContactNumber1 NVARCHAR(MAX) NULL,
        CPName2 NVARCHAR(MAX) NULL,
        CPEmail2 NVARCHAR(MAX) NULL,
        CPContactNumber2 NVARCHAR(MAX) NULL,
        CountryId INT NULL,
        StateOrProvinceId INT NULL,
        CityId INT NULL,
        BranchId INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL,
        Code NVARCHAR(MAX) NULL,
        VendorOrCustomer INT NULL,
        IncomeTaxStatus INT NULL,
        VendorType INT NULL,
        TaxPayerCategoryId INT NULL,
        TaxPayerStatus INT NULL,
        SaleTaxType INT NULL,
        ExemptUnderSRO NVARCHAR(MAX) NULL,
        AccountPayableId INT NULL,
        AccountReceivableId INT NULL,
        CreditStatus INT NULL,
        NetDueDays INT NULL,
        CreditLimit INT NULL,
        FaxNo NVARCHAR(MAX) NULL,
        IsVerified BIT DEFAULT 0
    );
    PRINT 'Created Inv.Vendors';
END
GO

-- Manufacturers adapter (use existing Pharmacy.Manufacturers)
IF OBJECT_ID('Inv.PharmacyManufacturers', 'SN') IS NOT NULL DROP SYNONYM Inv.PharmacyManufacturers;
GO
IF OBJECT_ID('Inv.PharmacyManufacturers', 'SN') IS NOT NULL DROP SYNONYM Inv.PharmacyManufacturers;
GO
IF OBJECT_ID('Inv.PharmacyManufacturers', 'V') IS NOT NULL DROP VIEW Inv.PharmacyManufacturers;
GO
IF OBJECT_ID('Inv.Manufacturers', 'SN') IS NOT NULL DROP SYNONYM Inv.Manufacturers;
GO
IF OBJECT_ID('Inv.Manufacturers', 'V') IS NOT NULL DROP VIEW Inv.Manufacturers;
GO
IF OBJECT_ID('Pharmacy.Manufacturers', 'U') IS NOT NULL OR OBJECT_ID('Pharmacy.Manufacturers', 'V') IS NOT NULL
BEGIN
    DECLARE @ManufacturerIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'ManufacturerId') IS NOT NULL THEN 'ManufacturerId'
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'Id') IS NOT NULL THEN 'Id'
        ELSE NULL
    END;
    DECLARE @ManufacturerNameColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'Name') IS NOT NULL THEN 'Name'
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'ManufacturerName') IS NOT NULL THEN 'ManufacturerName'
        ELSE NULL
    END;
    DECLARE @ManufacturerDescriptionColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'Description') IS NOT NULL THEN 'Description'
        ELSE NULL
    END;
    DECLARE @ManufacturerEmailColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'Email') IS NOT NULL THEN 'Email'
        ELSE NULL
    END;
    DECLARE @ManufacturerAddressColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'Address') IS NOT NULL THEN 'Address'
        ELSE NULL
    END;
    DECLARE @ManufacturerContactColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'CNo') IS NOT NULL THEN 'CNo'
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'MobileNo') IS NOT NULL THEN 'MobileNo'
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'ContactNo') IS NOT NULL THEN 'ContactNo'
        ELSE NULL
    END;
    DECLARE @ManufacturerActiveColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'IsActive') IS NOT NULL THEN 'IsActive'
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'Status') IS NOT NULL THEN 'Status'
        ELSE NULL
    END;
    DECLARE @ManufacturerCreatedByColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'CreatedById') IS NOT NULL THEN 'CreatedById'
        ELSE NULL
    END;
    DECLARE @ManufacturerCreatedOnColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'CreatedOn') IS NOT NULL THEN 'CreatedOn'
        ELSE NULL
    END;
    DECLARE @ManufacturerModifiedByColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'ModifiedById') IS NOT NULL THEN 'ModifiedById'
        ELSE NULL
    END;
    DECLARE @ManufacturerModifiedOnColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.Manufacturers', 'ModifiedOn') IS NOT NULL THEN 'ModifiedOn'
        ELSE NULL
    END;

    IF @ManufacturerIdColumn IS NOT NULL AND @ManufacturerNameColumn IS NOT NULL
    BEGIN
        DECLARE @ManufacturerSql NVARCHAR(MAX) = N'CREATE VIEW Inv.PharmacyManufacturers AS
SELECT
    ' + QUOTENAME(@ManufacturerIdColumn) + N' AS Id,
    ' + QUOTENAME(@ManufacturerNameColumn) + N' AS Name,
    ' + COALESCE(QUOTENAME(@ManufacturerDescriptionColumn), N'CAST(NULL AS NVARCHAR(MAX))') + N' AS Description,
    ' + COALESCE(QUOTENAME(@ManufacturerEmailColumn), N'CAST(NULL AS NVARCHAR(MAX))') + N' AS Email,
    ' + COALESCE(QUOTENAME(@ManufacturerAddressColumn), N'CAST(NULL AS NVARCHAR(MAX))') + N' AS Address,
    ' + COALESCE(QUOTENAME(@ManufacturerContactColumn), N'CAST(NULL AS NVARCHAR(MAX))') + N' AS CNo,
    CAST(NULL AS NVARCHAR(MAX)) AS NTN,
    CAST(NULL AS NVARCHAR(MAX)) AS STN,
    CAST(NULL AS NVARCHAR(MAX)) AS CPName1,
    CAST(NULL AS NVARCHAR(MAX)) AS CPEmail1,
    CAST(NULL AS NVARCHAR(MAX)) AS CPContactNumber1,
    CAST(NULL AS NVARCHAR(MAX)) AS CPName2,
    CAST(NULL AS NVARCHAR(MAX)) AS CPEmail2,
    CAST(NULL AS NVARCHAR(MAX)) AS CPContactNumber2,
    CAST(NULL AS INT) AS CountryId,
    CAST(NULL AS INT) AS StateOrProvinceId,
    CAST(NULL AS INT) AS CityId,
    CAST(NULL AS INT) AS BranchId,
    ' + CASE
        WHEN @ManufacturerActiveColumn IS NULL THEN N'CAST(1 AS BIT)'
        WHEN @ManufacturerActiveColumn = 'Status' THEN N'CAST(CASE WHEN [Status] IS NULL OR [Status] = 1 THEN 1 ELSE 0 END AS BIT)'
        ELSE N'CAST(ISNULL(' + QUOTENAME(@ManufacturerActiveColumn) + N', 1) AS BIT)'
    END + N' AS IsActive,
    ' + COALESCE(QUOTENAME(@ManufacturerCreatedByColumn), N'CAST(NULL AS INT)') + N' AS CreatedById,
    ' + COALESCE(QUOTENAME(@ManufacturerCreatedOnColumn), N'CAST(NULL AS DATETIME2)') + N' AS CreatedOn,
    ' + COALESCE(QUOTENAME(@ManufacturerModifiedByColumn), N'CAST(NULL AS INT)') + N' AS ModifiedById,
    ' + COALESCE(QUOTENAME(@ManufacturerModifiedOnColumn), N'CAST(NULL AS DATETIME2)') + N' AS ModifiedOn,
    CAST(NULL AS NVARCHAR(MAX)) AS RegisteredOwner
FROM Pharmacy.Manufacturers;';

        EXEC sys.sp_executesql @ManufacturerSql;
        EXEC('CREATE VIEW Inv.Manufacturers AS SELECT * FROM Inv.PharmacyManufacturers');
        PRINT 'Created Inv.PharmacyManufacturers adapter view and Inv.Manufacturers compatibility view';
    END
    ELSE
    BEGIN
        PRINT 'Pharmacy.Manufacturers found but does not expose a compatible key/name shape; skipped manufacturer adapter views';
    END
END
ELSE
BEGIN
    PRINT 'Pharmacy.Manufacturers not found; skipped manufacturer adapter views';
END
GO

-- Brands adapter (prefer shared Data.Brands over a local Inv table)
IF OBJECT_ID('Inv.DataBrands', 'SN') IS NOT NULL DROP SYNONYM Inv.DataBrands;
GO
IF OBJECT_ID('Inv.DataBrands', 'V') IS NOT NULL DROP VIEW Inv.DataBrands;
GO
IF OBJECT_ID('Data.Brands', 'U') IS NOT NULL OR OBJECT_ID('Data.Brands', 'V') IS NOT NULL
BEGIN
    EXEC('CREATE SYNONYM Inv.DataBrands FOR Data.Brands');
    PRINT 'Created Inv.DataBrands adapter synonym';
END
ELSE IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DataBrands' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.DataBrands (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        BranchId INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.DataBrands fallback table';
END
GO

-- ItemTypes table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ItemTypes' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.ItemTypes (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        Value INT NULL,
        BranchId INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.ItemTypes';
END
GO

IF COL_LENGTH('Inv.ItemTypes', 'Value') IS NULL
BEGIN
    ALTER TABLE Inv.ItemTypes ADD Value INT NULL;
    PRINT 'Added Value column to Inv.ItemTypes';
END
GO

-- ItemUnits table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ItemUnits' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.ItemUnits (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Symbol NVARCHAR(50) NULL,
        Description NVARCHAR(MAX) NULL,
        BranchId INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.ItemUnits';
END
GO

-- Packings table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Packings' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Packings (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        BranchId INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.Packings';
END
GO

-- Categories table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Categories' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Categories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.Categories';
END
GO

-- SubCategories table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SubCategories' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.SubCategories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        CategoryId INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.SubCategories';
END
GO

-- Prices table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Prices' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Prices (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        RetailPrice DECIMAL(18,4) DEFAULT 0,
        SalePrice DECIMAL(18,4) DEFAULT 0,
        MarketPrice DECIMAL(18,4) DEFAULT 0,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.Prices';
END
GO

-- TaxRates table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TaxRates' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.TaxRates (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Rate DECIMAL(5,2) NOT NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.TaxRates';
END
GO

-- TaxDescriptions table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TaxDescriptions' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.TaxDescriptions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.TaxDescriptions';
END
GO

-- TaxTypes table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TaxTypes' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.TaxTypes (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.TaxTypes';
END
GO

-- TaxPayerCategories table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TaxPayerCategories' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.TaxPayerCategories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Code NVARCHAR(20) NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.TaxPayerCategories';
END
GO

-- AccountCOAs table (Chart of Accounts)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AccountCOAs' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.AccountCOAs (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Code NVARCHAR(20) NULL,
        AccountType NVARCHAR(50) NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.AccountCOAs';
END
GO

-- Stores adapter (use existing Pharmacy.PharmacyStores)
IF OBJECT_ID('Inv.PharmacyStores', 'V') IS NOT NULL DROP VIEW Inv.PharmacyStores;
GO
IF OBJECT_ID('Pharmacy.PharmacyStores', 'U') IS NOT NULL OR OBJECT_ID('Pharmacy.PharmacyStores', 'V') IS NOT NULL
BEGIN
    DECLARE @StoreIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'StoreId') IS NOT NULL THEN 'StoreId'
        ELSE 'Id'
    END;
    DECLARE @StoreNameColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'StoreName') IS NOT NULL THEN 'StoreName'
        ELSE 'Name'
    END;
    DECLARE @StoreCodeColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'StoreCode') IS NOT NULL THEN 'StoreCode'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'Code') IS NOT NULL THEN 'Code'
        ELSE NULL
    END;
    DECLARE @StoreDescriptionColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'Description') IS NOT NULL THEN 'Description'
        ELSE NULL
    END;
    DECLARE @StoreTypeColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'StoreType') IS NOT NULL THEN 'StoreType'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'StoreTypeId') IS NOT NULL THEN 'StoreTypeId'
        ELSE NULL
    END;
    DECLARE @ReceiptTypeColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'ReceiptType') IS NOT NULL THEN 'ReceiptType'
        ELSE NULL
    END;
    DECLARE @PostTypeColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'POSType') IS NOT NULL THEN 'POSType'
        ELSE NULL
    END;
    DECLARE @ParentStoreIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'ParentStoreId') IS NOT NULL THEN 'ParentStoreId'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'ParentId') IS NOT NULL THEN 'ParentId'
        ELSE NULL
    END;
    DECLARE @BranchIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'BranchId') IS NOT NULL THEN 'BranchId'
        ELSE NULL
    END;
    DECLARE @BuildingIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'BuildingId') IS NOT NULL THEN 'BuildingId'
        ELSE NULL
    END;
    DECLARE @FloorIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'FloorId') IS NOT NULL THEN 'FloorId'
        ELSE NULL
    END;
    DECLARE @RoomIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'RoomId') IS NOT NULL THEN 'RoomId'
        ELSE NULL
    END;
    DECLARE @EmailColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'Email') IS NOT NULL THEN 'Email'
        ELSE NULL
    END;
    DECLARE @CellNumberColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'CellNumber') IS NOT NULL THEN 'CellNumber'
        ELSE NULL
    END;
    DECLARE @QueueStatusColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'QueuePatientCallStatusValue') IS NOT NULL THEN 'QueuePatientCallStatusValue'
        ELSE NULL
    END;
    DECLARE @MarkTokenColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'MarkTokenAsAutoCollectedOnDispense') IS NOT NULL THEN 'MarkTokenAsAutoCollectedOnDispense'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'IsMarkTokenAsAutoCollectedOnDispense') IS NOT NULL THEN 'IsMarkTokenAsAutoCollectedOnDispense'
        ELSE NULL
    END;
    DECLARE @DisplayRequestsColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'DisplayRequestsWithoutTokenIssued') IS NOT NULL THEN 'DisplayRequestsWithoutTokenIssued'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'IsDisplayRequestsWithoutTokenIssuedInUserPharmacyQueue') IS NOT NULL THEN 'IsDisplayRequestsWithoutTokenIssuedInUserPharmacyQueue'
        ELSE NULL
    END;
    DECLARE @EnglishNoteColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'EnglishNote') IS NOT NULL THEN 'EnglishNote'
        ELSE NULL
    END;
    DECLARE @UrduNoteColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'UrduNote') IS NOT NULL THEN 'UrduNote'
        ELSE NULL
    END;
    DECLARE @ServiceChargesColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'IsPercentageServiceCharges') IS NOT NULL THEN 'IsPercentageServiceCharges'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'ServiceCharges') IS NOT NULL THEN 'ServiceCharges'
        ELSE NULL
    END;
    DECLARE @GstColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'IsPercentageGST') IS NOT NULL THEN 'IsPercentageGST'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'GST') IS NOT NULL THEN 'GST'
        ELSE NULL
    END;
    DECLARE @PricingTypeColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'PricingType') IS NOT NULL THEN 'PricingType'
        ELSE NULL
    END;
    DECLARE @DisableRetailSaleColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'DisableRetailSale') IS NOT NULL THEN 'DisableRetailSale'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'IsDisableRetailSale') IS NOT NULL THEN 'IsDisableRetailSale'
        ELSE NULL
    END;
    DECLARE @GstnColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'GSTN') IS NOT NULL THEN 'GSTN'
        ELSE NULL
    END;
    DECLARE @NtnColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'NTN') IS NOT NULL THEN 'NTN'
        ELSE NULL
    END;
    DECLARE @DayClosingColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'DayClosing') IS NOT NULL THEN 'DayClosing'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'DayClosingWise') IS NOT NULL THEN 'DayClosingWise'
        ELSE NULL
    END;
    DECLARE @ClosingCashAccountIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'ClosingCashAccountId') IS NOT NULL THEN 'ClosingCashAccountId'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'DayClosingCashAccountId') IS NOT NULL THEN 'DayClosingCashAccountId'
        ELSE NULL
    END;
    DECLARE @ClosingRevenueAccountIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'ClosingRevenueAccountId') IS NOT NULL THEN 'ClosingRevenueAccountId'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'DayClosingRevenueAccountId') IS NOT NULL THEN 'DayClosingRevenueAccountId'
        ELSE NULL
    END;
    DECLARE @ClosingInventoryAccountIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'ClosingInventoryAccountId') IS NOT NULL THEN 'ClosingInventoryAccountId'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'DayClosingInventoryAccountId') IS NOT NULL THEN 'DayClosingInventoryAccountId'
        ELSE NULL
    END;
    DECLARE @ClosingInventoryExpenseAccountIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'ClosingInventoryExpenseAccountId') IS NOT NULL THEN 'ClosingInventoryExpenseAccountId'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'DayClosingInventoryExpenseAccountId') IS NOT NULL THEN 'DayClosingInventoryExpenseAccountId'
        ELSE NULL
    END;
    DECLARE @ClosingTaxExpenseAccountIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'ClosingTaxExpenseAccountId') IS NOT NULL THEN 'ClosingTaxExpenseAccountId'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'DayClosingTaxExpenseAccountId') IS NOT NULL THEN 'DayClosingTaxExpenseAccountId'
        ELSE NULL
    END;
    DECLARE @PayableAccountIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'PayableAccountId') IS NOT NULL THEN 'PayableAccountId'
        ELSE NULL
    END;
    DECLARE @AdvanceTaxPercentageAccountIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'AdvanceTaxPercentageAccountId') IS NOT NULL THEN 'AdvanceTaxPercentageAccountId'
        ELSE NULL
    END;
    DECLARE @RevenueDiscountAccountIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'RevenueDiscountAccountId') IS NOT NULL THEN 'RevenueDiscountAccountId'
        ELSE NULL
    END;
    DECLARE @AddressColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'Address') IS NOT NULL THEN 'Address'
        ELSE NULL
    END;
    DECLARE @LatitudeColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'Latitude') IS NOT NULL THEN 'Latitude'
        ELSE NULL
    END;
    DECLARE @LongitudeColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'Longitude') IS NOT NULL THEN 'Longitude'
        ELSE NULL
    END;
    DECLARE @CountryColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'Country') IS NOT NULL THEN 'Country'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'CountryId') IS NOT NULL THEN 'CountryId'
        ELSE NULL
    END;
    DECLARE @StateOrProvinceColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'StateOrProvince') IS NOT NULL THEN 'StateOrProvince'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'StateOrProvinceId') IS NOT NULL THEN 'StateOrProvinceId'
        ELSE NULL
    END;
    DECLARE @CityColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'City') IS NOT NULL THEN 'City'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'CityId') IS NOT NULL THEN 'CityId'
        ELSE NULL
    END;
    DECLARE @StoreImageColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'StoreImage') IS NOT NULL THEN 'StoreImage'
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'ImagePath') IS NOT NULL THEN 'ImagePath'
        ELSE NULL
    END;
    DECLARE @IsActiveColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'IsActive') IS NOT NULL THEN 'IsActive'
        ELSE NULL
    END;
    DECLARE @CreatedByIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'CreatedById') IS NOT NULL THEN 'CreatedById'
        ELSE NULL
    END;
    DECLARE @CreatedOnColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'CreatedOn') IS NOT NULL THEN 'CreatedOn'
        ELSE NULL
    END;
    DECLARE @ModifiedByIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'ModifiedById') IS NOT NULL THEN 'ModifiedById'
        ELSE NULL
    END;
    DECLARE @ModifiedOnColumn SYSNAME = CASE
        WHEN COL_LENGTH('Pharmacy.PharmacyStores', 'ModifiedOn') IS NOT NULL THEN 'ModifiedOn'
        ELSE NULL
    END;

    DECLARE @StoreSql NVARCHAR(MAX) = N'CREATE VIEW Inv.PharmacyStores AS
SELECT
    ' + QUOTENAME(@StoreIdColumn) + N' AS StoreId,
    ' + QUOTENAME(@StoreNameColumn) + N' AS StoreName,
    ' + COALESCE(QUOTENAME(@StoreCodeColumn), N'CAST(NULL AS NVARCHAR(50))') + N' AS StoreCode,
    ' + COALESCE(QUOTENAME(@StoreDescriptionColumn), N'CAST(NULL AS NVARCHAR(MAX))') + N' AS Description,
    ' + CASE WHEN @StoreTypeColumn IS NULL THEN N'CAST(NULL AS NVARCHAR(50))' ELSE N'CAST(' + QUOTENAME(@StoreTypeColumn) + N' AS NVARCHAR(50))' END + N' AS StoreType,
    ' + CASE WHEN @ReceiptTypeColumn IS NULL THEN N'CAST(NULL AS NVARCHAR(50))' ELSE N'CAST(' + QUOTENAME(@ReceiptTypeColumn) + N' AS NVARCHAR(50))' END + N' AS ReceiptType,
    ' + CASE WHEN @PostTypeColumn IS NULL THEN N'CAST(NULL AS NVARCHAR(50))' ELSE N'CAST(' + QUOTENAME(@PostTypeColumn) + N' AS NVARCHAR(50))' END + N' AS POSType,
    ' + COALESCE(QUOTENAME(@ParentStoreIdColumn), N'CAST(NULL AS INT)') + N' AS ParentStoreId,
    ' + COALESCE(QUOTENAME(@BuildingIdColumn), N'CAST(NULL AS INT)') + N' AS BuildingId,
    ' + COALESCE(QUOTENAME(@FloorIdColumn), N'CAST(NULL AS INT)') + N' AS FloorId,
    ' + COALESCE(QUOTENAME(@RoomIdColumn), N'CAST(NULL AS INT)') + N' AS RoomId,
    ' + COALESCE(QUOTENAME(@EmailColumn), N'CAST(NULL AS NVARCHAR(256))') + N' AS Email,
    ' + COALESCE(QUOTENAME(@CellNumberColumn), N'CAST(NULL AS NVARCHAR(50))') + N' AS CellNumber,
    ' + CASE WHEN @QueueStatusColumn IS NULL THEN N'CAST(NULL AS NVARCHAR(50))' ELSE N'CAST(' + QUOTENAME(@QueueStatusColumn) + N' AS NVARCHAR(50))' END + N' AS QueuePatientCallStatusValue,
    ' + COALESCE(QUOTENAME(@MarkTokenColumn), N'CAST(NULL AS BIT)') + N' AS MarkTokenAsAutoCollectedOnDispense,
    ' + COALESCE(QUOTENAME(@DisplayRequestsColumn), N'CAST(NULL AS BIT)') + N' AS DisplayRequestsWithoutTokenIssued,
    ' + COALESCE(QUOTENAME(@EnglishNoteColumn), N'CAST(NULL AS NVARCHAR(MAX))') + N' AS EnglishNote,
    ' + COALESCE(QUOTENAME(@UrduNoteColumn), N'CAST(NULL AS NVARCHAR(MAX))') + N' AS UrduNote,
    ' + COALESCE(QUOTENAME(@ServiceChargesColumn), N'CAST(NULL AS BIT)') + N' AS ServiceCharges,
    ' + COALESCE(QUOTENAME(@GstColumn), N'CAST(NULL AS BIT)') + N' AS GST,
    ' + CASE WHEN @PricingTypeColumn IS NULL THEN N'CAST(NULL AS NVARCHAR(50))' ELSE N'CAST(' + QUOTENAME(@PricingTypeColumn) + N' AS NVARCHAR(50))' END + N' AS PricingType,
    ' + COALESCE(QUOTENAME(@DisableRetailSaleColumn), N'CAST(NULL AS BIT)') + N' AS DisableRetailSale,
    ' + COALESCE(QUOTENAME(@GstnColumn), N'CAST(NULL AS NVARCHAR(50))') + N' AS GSTN,
    ' + COALESCE(QUOTENAME(@NtnColumn), N'CAST(NULL AS NVARCHAR(50))') + N' AS NTN,
    ' + CASE WHEN @DayClosingColumn IS NULL THEN N'CAST(NULL AS NVARCHAR(50))' ELSE N'CAST(' + QUOTENAME(@DayClosingColumn) + N' AS NVARCHAR(50))' END + N' AS DayClosing,
    ' + COALESCE(QUOTENAME(@ClosingCashAccountIdColumn), N'CAST(NULL AS INT)') + N' AS ClosingCashAccountId,
    ' + COALESCE(QUOTENAME(@ClosingRevenueAccountIdColumn), N'CAST(NULL AS INT)') + N' AS ClosingRevenueAccountId,
    ' + COALESCE(QUOTENAME(@ClosingInventoryAccountIdColumn), N'CAST(NULL AS INT)') + N' AS ClosingInventoryAccountId,
    ' + COALESCE(QUOTENAME(@ClosingInventoryExpenseAccountIdColumn), N'CAST(NULL AS INT)') + N' AS ClosingInventoryExpenseAccountId,
    ' + COALESCE(QUOTENAME(@ClosingTaxExpenseAccountIdColumn), N'CAST(NULL AS INT)') + N' AS ClosingTaxExpenseAccountId,
    ' + COALESCE(QUOTENAME(@PayableAccountIdColumn), N'CAST(NULL AS INT)') + N' AS PayableAccountId,
    ' + COALESCE(QUOTENAME(@AdvanceTaxPercentageAccountIdColumn), N'CAST(NULL AS INT)') + N' AS AdvanceTaxPercentageAccountId,
    ' + COALESCE(QUOTENAME(@RevenueDiscountAccountIdColumn), N'CAST(NULL AS INT)') + N' AS RevenueDiscountAccountId,
    ' + COALESCE(QUOTENAME(@AddressColumn), N'CAST(NULL AS NVARCHAR(MAX))') + N' AS Address,
    ' + COALESCE(QUOTENAME(@LatitudeColumn), N'CAST(NULL AS NVARCHAR(100))') + N' AS Latitude,
    ' + COALESCE(QUOTENAME(@LongitudeColumn), N'CAST(NULL AS NVARCHAR(100))') + N' AS Longitude,
    ' + CASE WHEN @CountryColumn IS NULL THEN N'CAST(NULL AS NVARCHAR(100))' ELSE N'CAST(' + QUOTENAME(@CountryColumn) + N' AS NVARCHAR(100))' END + N' AS Country,
    ' + CASE WHEN @StateOrProvinceColumn IS NULL THEN N'CAST(NULL AS NVARCHAR(100))' ELSE N'CAST(' + QUOTENAME(@StateOrProvinceColumn) + N' AS NVARCHAR(100))' END + N' AS StateOrProvince,
    ' + CASE WHEN @CityColumn IS NULL THEN N'CAST(NULL AS NVARCHAR(100))' ELSE N'CAST(' + QUOTENAME(@CityColumn) + N' AS NVARCHAR(100))' END + N' AS City,
    ' + COALESCE(QUOTENAME(@StoreImageColumn), N'CAST(NULL AS NVARCHAR(MAX))') + N' AS StoreImage,
    ' + COALESCE(QUOTENAME(@BranchIdColumn), N'CAST(NULL AS INT)') + N' AS BranchId,
    ' + CASE WHEN @IsActiveColumn IS NULL THEN N'CAST(1 AS BIT)' ELSE QUOTENAME(@IsActiveColumn) END + N' AS IsActive,
    ' + COALESCE(QUOTENAME(@CreatedByIdColumn), N'CAST(NULL AS INT)') + N' AS CreatedById,
    ' + COALESCE(QUOTENAME(@CreatedOnColumn), N'CAST(NULL AS DATETIME)') + N' AS CreatedOn,
    ' + COALESCE(QUOTENAME(@ModifiedByIdColumn), N'CAST(NULL AS INT)') + N' AS ModifiedById,
    ' + COALESCE(QUOTENAME(@ModifiedOnColumn), N'CAST(NULL AS DATETIME)') + N' AS ModifiedOn
FROM Pharmacy.PharmacyStores;';

    EXEC sys.sp_executesql @StoreSql;
    PRINT 'Created Inv.PharmacyStores adapter view';
END
ELSE
BEGIN
    PRINT 'Pharmacy.PharmacyStores not found; skipped Inv.PharmacyStores adapter view';
END
GO

-- Inventories table (GRN header)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Inventories' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Inventories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseOrderNumber NVARCHAR(MAX) NULL,
        InvoiceNo NVARCHAR(MAX) NULL,
        PurchaseOrderId INT NULL,
        VendorId INT NULL,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,
        IsFinalized BIT NULL,
        StockTypeId INT NULL,
        VendorInvoiceNumber NVARCHAR(MAX) NULL,
        VendorInvoiceTimestamp DATETIME NULL,
        Amount REAL NULL,
        Discount REAL NULL,
        DiscountType INT NULL,
        Total REAL NULL,
        PaidAmount REAL NULL,
        PaymentStatusId INT NULL,
        TotalPaidAmount REAL NULL,
        PayableAccountId INT NULL,
        IsPaymentPending BIT NULL,
        VoucherId INT NULL,
        TotalVoucherPaidAmount REAL NULL,
        TotalBuyingPrice REAL NULL,
        ReceiptPath NVARCHAR(MAX) NULL,
        AdvanceTaxPercentage REAL NULL,
        AdvanceTaxCalculatedAmount REAL NULL,
        RetailCharges REAL NULL,
        RetailChargesType INT NULL,
        GSTCharges REAL NULL,
        RetailChargesCalculatedAmount REAL NULL,
        GSTChargesCalculatedAmount REAL NULL,
        ManualPurchaseOrderNumber NVARCHAR(MAX) NULL
    );
    PRINT 'Created Inv.Inventories';
END
GO

-- InventoryDetails table (GRN line items)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'InventoryDetails' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.InventoryDetails (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        InventoryId INT NOT NULL,
        ItemId INT NOT NULL,
        ManufacturerId INT NULL,
        MfgDate DATETIME NULL,
        ExpiryDate DATETIME NULL,
        NoOfBoxes INT NULL,
        NoOfPackets INT NULL,
        ItemsPerPacket INT NULL,
        TotalItems INT NULL,
        PackQuantity INT NULL,
        UnitBuyingPrice REAL NULL,
        TotalBuyingPrice REAL NULL,
        AdvanceTaxPercentage REAL NULL,
        AdvanceTaxAmount REAL NULL,
        Discount BIT NULL,
        DiscountAmount REAL NULL,
        RetailCharges BIT NULL,
        RetailChargesAmount REAL NULL,
        GSTCharges BIT NULL,
        GSTChargesAmount REAL NULL,
        UnitSellingPrice REAL NULL,
        TotalSellingPrice REAL NULL,
        ProfitMarginPerItem REAL NULL,
        ProfitPerItem REAL NULL
    );
    PRINT 'Created Inv.InventoryDetails';
END
GO

-- Stocks table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Stocks' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Stocks (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ItemId INT NULL,
        TotalItems INT NULL,
        MinimumPanicLevel INT NULL,
        BranchId INT NULL,
        StoreId INT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.Stocks';
END
GO

-- PurchaseOrders table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseOrders' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.PurchaseOrders (
        PurchaseOrderId INT IDENTITY(1,1) PRIMARY KEY,
        PONumber NVARCHAR(50) NOT NULL,
        ManualPONumber NVARCHAR(100) NULL,
        StoreId INT NOT NULL,
        VendorId INT NOT NULL,
        POValidityDate DATETIME2 NULL,
        Subject NVARCHAR(500) NULL,
        Instructions NVARCHAR(MAX) NULL,
        TermsAndConditions NVARCHAR(MAX) NULL,
        Status NVARCHAR(50) NOT NULL DEFAULT 'Pending',
        TotalQuantity DECIMAL(18,2) NOT NULL DEFAULT 0,
        TotalAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL,
        CONSTRAINT UQ_Inv_PurchaseOrders_PONumber UNIQUE (PONumber)
    );
    PRINT 'Created Inv.PurchaseOrders';
END
GO

-- PurchaseOrderItems table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseOrderItems' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.PurchaseOrderItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseOrderId INT NOT NULL,
        ItemId INT NOT NULL,
        ItemType NVARCHAR(50) NULL,
        PacketQuantity DECIMAL(18,2) NULL,
        UnitQuantity DECIMAL(18,2) NOT NULL,
        PacketPrice DECIMAL(18,2) NULL,
        UnitPrice DECIMAL(18,2) NOT NULL,
        TotalPrice DECIMAL(18,2) NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.PurchaseOrderItems';
END
GO

-- PurchaseOrderTypes table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseOrderTypes' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.PurchaseOrderTypes (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById NVARCHAR(450) NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById NVARCHAR(450) NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.PurchaseOrderTypes';
END
GO

-- PurchaseOrderStatus table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseOrderStatus' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.PurchaseOrderStatus (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseOrderId INT NOT NULL,
        Status NVARCHAR(50) NOT NULL,
        Notes NVARCHAR(MAX) NULL,
        CreatedById INT NULL,
        CreatedOn DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    PRINT 'Created Inv.PurchaseOrderStatus';
END
GO

-- PurchaseOrderStatusItems table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseOrderStatusItems' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.PurchaseOrderStatusItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseOrderStatusId INT NOT NULL,
        ItemId INT NOT NULL,
        ReceivedQuantity DECIMAL(18,2) NULL,
        RemainingQuantity DECIMAL(18,2) NULL,
        Notes NVARCHAR(MAX) NULL
    );
    PRINT 'Created Inv.PurchaseOrderStatusItems';
END
GO

-- FinancialYears table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FinancialYears' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.FinancialYears (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        StartDate DATETIME NOT NULL,
        EndDate DATETIME NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById NVARCHAR(450) NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById NVARCHAR(450) NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.FinancialYears';
END
GO

-- StockConsumptions table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockConsumptions' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StockConsumptions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ConsumptionNumber NVARCHAR(50) NULL,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        DepartmentId INT NULL,
        ConsumptionDate DATETIME NOT NULL DEFAULT GETDATE(),
        Notes NVARCHAR(MAX) NULL,
        Status NVARCHAR(50) DEFAULT 'Pending',
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.StockConsumptions';
END
GO

-- StockConsumptionDetails table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockConsumptionDetails' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StockConsumptionDetails (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StockConsumptionId INT NOT NULL,
        ItemId INT NOT NULL,
        Quantity INT NOT NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.StockConsumptionDetails';
END
GO

-- StockAdjustments table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockAdjustments' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StockAdjustments (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        AdjustmentNumber NVARCHAR(50) NULL,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        AdjustmentDate DATETIME NOT NULL DEFAULT GETDATE(),
        Reason NVARCHAR(MAX) NULL,
        Notes NVARCHAR(MAX) NULL,
        AdjustmentType NVARCHAR(50) NULL,
        Status NVARCHAR(50) DEFAULT 'Pending',
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.StockAdjustments';
END
GO

-- StockAdjustmentDetails table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockAdjustmentDetails' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StockAdjustmentDetails (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StockAdjustmentId INT NOT NULL,
        ItemId INT NOT NULL,
        CurrentQuantity INT NULL,
        AdjustedQuantity INT NOT NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.StockAdjustmentDetails';
END
GO

-- StockAudits table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockAudits' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StockAudits (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        AuditNumber NVARCHAR(50) NULL,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        AuditDate DATETIME NOT NULL DEFAULT GETDATE(),
        Notes NVARCHAR(MAX) NULL,
        Status NVARCHAR(50) DEFAULT 'Pending',
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.StockAudits';
END
GO

-- StockAuditItems table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockAuditItems' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StockAuditItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StockAuditId INT NOT NULL,
        ItemId INT NOT NULL,
        SystemQuantity INT NULL,
        PhysicalQuantity INT NOT NULL,
        VarianceQuantity INT NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.StockAuditItems';
END
GO

-- TransferInventory table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TransferInventory' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.TransferInventory (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        TransferNumber NVARCHAR(50) NULL,
        FromStoreId INT NOT NULL,
        ToStoreId INT NOT NULL,
        BranchId INT NOT NULL,
        TransferDate DATETIME NOT NULL DEFAULT GETDATE(),
        Notes NVARCHAR(MAX) NULL,
        Status NVARCHAR(50) DEFAULT 'Pending',
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.TransferInventory';
END
GO

-- TransferInventoryItems table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TransferInventoryItems' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.TransferInventoryItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        TransferInventoryId INT NOT NULL,
        ItemId INT NOT NULL,
        Quantity INT NOT NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.TransferInventoryItems';
END
GO

-- ReturnInventory table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ReturnInventory' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.ReturnInventory (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ReturnNumber NVARCHAR(50) NULL,
        VendorId INT NULL,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        ReturnDate DATETIME NOT NULL DEFAULT GETDATE(),
        Reason NVARCHAR(MAX) NULL,
        Notes NVARCHAR(MAX) NULL,
        Status NVARCHAR(50) DEFAULT 'Pending',
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.ReturnInventory';
END
GO

-- ReturnInventoryItems table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ReturnInventoryItems' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.ReturnInventoryItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ReturnInventoryId INT NOT NULL,
        ItemId INT NOT NULL,
        Quantity INT NOT NULL,
        Reason NVARCHAR(MAX) NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.ReturnInventoryItems';
END
GO

-- ContingentBills table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ContingentBills' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.ContingentBills (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        BillNumber NVARCHAR(50) NULL,
        VendorId INT NULL,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        BillDate DATETIME NOT NULL DEFAULT GETDATE(),
        Amount DECIMAL(18,2) NULL,
        Notes NVARCHAR(MAX) NULL,
        Status NVARCHAR(50) DEFAULT 'Pending',
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.ContingentBills';
END
GO

-- AssetAllocations table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AssetAllocations' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.AssetAllocations (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ItemId INT NOT NULL,
        BranchId INT NULL,
        DepartmentId INT NULL,
        SubDepartmentId INT NULL,
        UserId INT NULL,
        RoomId INT NULL,
        AllocatedDate DATETIME NULL DEFAULT GETDATE(),
        AllocationNumber NVARCHAR(50) NULL,
        SerialNumber NVARCHAR(100) NULL,
        Quantity INT NOT NULL DEFAULT 1,
        Condition NVARCHAR(50) NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.AssetAllocations';
END
GO

-- StoreAllocationToUser table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StoreAllocationToUser' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StoreAllocationToUser (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StoreId INT NOT NULL,
        UserId INT NOT NULL,
        BranchId INT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.StoreAllocationToUser';
END
GO

-- ItemTypeSaleLevels table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ItemTypeSaleLevels' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.ItemTypeSaleLevels (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ItemTypeId INT NULL,
        FastRunningLevel INT NOT NULL DEFAULT 0,
        SlowMovingLevel INT NOT NULL DEFAULT 0,
        DeadLevel INT NOT NULL DEFAULT 0,
        BranchId INT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.ItemTypeSaleLevels';
END
GO

-- StockTypeAssociations table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockTypeAssociations' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StockTypeAssociations (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StoreId INT NOT NULL,
        StockTypeId INT NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.StockTypeAssociations';
END
GO

-- ItemCategories table (linking items to categories for stores)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ItemCategories' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.ItemCategories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ItemId INT NOT NULL,
        CategoryId INT NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.ItemCategories';
END
GO

-- PurchaseSummaries table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseSummaries' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.PurchaseSummaries (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        VendorId INT NULL,
        SummaryDate DATETIME NOT NULL DEFAULT GETDATE(),
        TotalAmount DECIMAL(18,2) NULL,
        Status NVARCHAR(50) DEFAULT 'Pending',
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.PurchaseSummaries';
END
GO

-- PurchaseSummaryInvoices table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseSummaryInvoices' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.PurchaseSummaryInvoices (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseSummaryId INT NOT NULL,
        InvoiceNumber NVARCHAR(100) NULL,
        InvoiceDate DATETIME NULL,
        Amount DECIMAL(18,2) NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.PurchaseSummaryInvoices';
END
GO

-- =============================================
-- PHASE 3: Add missing columns to existing Inv tables
-- =============================================

-- Add missing columns to Inv.Items if they don't exist
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Items' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'IsConsumptionItem')
        ALTER TABLE Inv.Items ADD IsConsumptionItem BIT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'IsHidePanicFromBill')
        ALTER TABLE Inv.Items ADD IsHidePanicFromBill BIT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'SaleUnitId')
        ALTER TABLE Inv.Items ADD SaleUnitId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'TaxRateId')
        ALTER TABLE Inv.Items ADD TaxRateId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'TaxDescriptionId')
        ALTER TABLE Inv.Items ADD TaxDescriptionId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'SalesAccountId')
        ALTER TABLE Inv.Items ADD SalesAccountId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'InventoryAccountId')
        ALTER TABLE Inv.Items ADD InventoryAccountId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'ExpenseAccountId')
        ALTER TABLE Inv.Items ADD ExpenseAccountId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'Frequency')
        ALTER TABLE Inv.Items ADD Frequency INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'IsProduct')
        ALTER TABLE Inv.Items ADD IsProduct BIT NOT NULL DEFAULT 0;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'BatchExpiryRequired')
        ALTER TABLE Inv.Items ADD BatchExpiryRequired BIT NOT NULL DEFAULT 0;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'DescriptionForSale')
        ALTER TABLE Inv.Items ADD DescriptionForSale NVARCHAR(MAX) NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'Conversion')
        ALTER TABLE Inv.Items ADD Conversion DECIMAL(18,2) NOT NULL DEFAULT 0;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'CaseContains')
        ALTER TABLE Inv.Items ADD CaseContains INT NOT NULL DEFAULT 0;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'SalePrice')
        ALTER TABLE Inv.Items ADD SalePrice DECIMAL(18,2) NOT NULL DEFAULT 0;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'CostMethod')
        ALTER TABLE Inv.Items ADD CostMethod INT NOT NULL DEFAULT 0;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'PriceId')
        ALTER TABLE Inv.Items ADD PriceId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'ItemTypeId')
        ALTER TABLE Inv.Items ADD ItemTypeId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'MinimumOrderPrice')
        ALTER TABLE Inv.Items ADD MinimumOrderPrice DECIMAL(18,2) NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'MinimumOrderQuantity')
        ALTER TABLE Inv.Items ADD MinimumOrderQuantity DECIMAL(18,2) NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'StripPerPacket')
        ALTER TABLE Inv.Items ADD StripPerPacket REAL NULL;
    PRINT 'Added missing columns to Inv.Items';
END
GO

-- Add missing columns to Inv.Racks if needed
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Racks' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Racks') AND name = 'Location')
        ALTER TABLE Inv.Racks ADD Location NVARCHAR(MAX) NULL;
    PRINT 'Verified Inv.Racks columns';
END
GO

-- Add missing columns to Inv.StockTypes if needed (HMS has Id/Name/Description only)
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'StockTypes' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.StockTypes') AND name = 'IsActive')
        ALTER TABLE Inv.StockTypes ADD IsActive BIT NOT NULL DEFAULT 1;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.StockTypes') AND name = 'IsDeleted')
        ALTER TABLE Inv.StockTypes ADD IsDeleted BIT NULL DEFAULT 0;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.StockTypes') AND name = 'CreatedById')
        ALTER TABLE Inv.StockTypes ADD CreatedById INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.StockTypes') AND name = 'CreatedOn')
        ALTER TABLE Inv.StockTypes ADD CreatedOn DATETIME NULL DEFAULT GETDATE();
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.StockTypes') AND name = 'ModifiedById')
        ALTER TABLE Inv.StockTypes ADD ModifiedById INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.StockTypes') AND name = 'ModifiedOn')
        ALTER TABLE Inv.StockTypes ADD ModifiedOn DATETIME NULL;
    PRINT 'Verified Inv.StockTypes columns';
END
GO

-- Add missing columns to Inv.SpaceAllocations if needed 
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'SpaceAllocations' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.SpaceAllocations') AND name = 'BranchId')
        ALTER TABLE Inv.SpaceAllocations ADD BranchId INT NULL;
    PRINT 'Verified Inv.SpaceAllocations columns';
END
GO

-- Add missing columns to Inv.DemandRequests if needed
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'DemandRequests' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.DemandRequests') AND name = 'RequestNumber')
        ALTER TABLE Inv.DemandRequests ADD RequestNumber NVARCHAR(MAX) NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.DemandRequests') AND name = 'IndentNumber')
        ALTER TABLE Inv.DemandRequests ADD IndentNumber NVARCHAR(MAX) NULL;
    PRINT 'Verified Inv.DemandRequests columns';
END
GO

-- DemandRequestItems table (for demand request line items)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DemandRequestItems' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.DemandRequestItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        DemandRequestId INT NOT NULL,
        ItemId INT NOT NULL,
        RequestedQuantity INT NOT NULL DEFAULT 0,
        ApprovedQuantity INT NULL,
        IssuedQuantity INT NULL,
        ReceivedQuantity INT NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.DemandRequestItems';
END
GO

-- Surgical item groups adapter (use existing Data surgical groups object)
IF OBJECT_ID('Inv.SurgicalGroups', 'SN') IS NOT NULL DROP SYNONYM Inv.SurgicalGroups;
GO
DECLARE @SurgicalGroupsSource NVARCHAR(200) = CASE
    WHEN OBJECT_ID('Data.SurgicalGroups', 'U') IS NOT NULL OR OBJECT_ID('Data.SurgicalGroups', 'V') IS NOT NULL THEN 'Data.SurgicalGroups'
    WHEN OBJECT_ID('Data.SurgicalItemGroups', 'U') IS NOT NULL OR OBJECT_ID('Data.SurgicalItemGroups', 'V') IS NOT NULL THEN 'Data.SurgicalItemGroups'
    ELSE NULL
END;

IF @SurgicalGroupsSource IS NOT NULL
BEGIN
    EXEC(N'CREATE SYNONYM Inv.SurgicalGroups FOR ' + @SurgicalGroupsSource);
    PRINT 'Created Inv.SurgicalGroups adapter synonym';
END
ELSE
BEGIN
    PRINT 'Data surgical groups source not found; skipped Inv.SurgicalGroups adapter synonym';
END
GO

-- SampleCollectionConsumptionItems (reference view to Lab.SampleCollectionConsumptionItems)
-- Already exists in Lab schema, no need to create

-- EstimatedPurchaseOrders table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'EstimatedPurchaseOrders' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.EstimatedPurchaseOrders (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.EstimatedPurchaseOrders';
END
GO

-- DemandWiseValues table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DemandWiseValues' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.DemandWiseValues (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Value INT NOT NULL DEFAULT 0,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.DemandWiseValues';
END
GO

PRINT '====================================';
PRINT 'HMS Setup completed successfully!';
PRINT '====================================';
GO
