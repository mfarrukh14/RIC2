USE InventoryManagementDB_SP;
GO

-- Drop existing procedures if they exist
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'AssetAllocation_GetAll')
    DROP PROCEDURE [dbo].[AssetAllocation_GetAll]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'AssetAllocation_GetById')
    DROP PROCEDURE [dbo].[AssetAllocation_GetById]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'AssetAllocation_Insert')
    DROP PROCEDURE [dbo].[AssetAllocation_Insert]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'AssetAllocation_Update')
    DROP PROCEDURE [dbo].[AssetAllocation_Update]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'AssetAllocation_Delete')
    DROP PROCEDURE [dbo].[AssetAllocation_Delete]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'User_GetAll')
    DROP PROCEDURE [dbo].[User_GetAll]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Room_GetAll')
    DROP PROCEDURE [dbo].[Room_GetAll]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Department_GetAll')
    DROP PROCEDURE [dbo].[Department_GetAll]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SubDepartment_GetAll')
    DROP PROCEDURE [dbo].[SubDepartment_GetAll]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'InventoryItem_GetAvailable')
    DROP PROCEDURE [dbo].[InventoryItem_GetAvailable]
GO

-- Create AssetAllocation_GetAll
CREATE PROCEDURE [dbo].[AssetAllocation_GetAll]
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #UserLookup
    (
        Id INT NOT NULL PRIMARY KEY,
        Name NVARCHAR(4000) NULL,
        Email NVARCHAR(256) NULL,
        UserName NVARCHAR(256) NULL,
        Department NVARCHAR(256) NULL,
        Designation NVARCHAR(256) NULL,
        IsActive BIT NOT NULL
    );

    -- Note: DropDown.DD_Users is intentionally not used here. It requires mandatory
    -- @UserTypeId/@BranchId/@OrganizationId parameters we have no generic value for,
    -- and Microsoft.Data.SqlClient surfaces its parameter error as a SqlException even
    -- when caught by TRY/CATCH in T-SQL. dbo.Users below is sufficient on its own.
    IF COL_LENGTH('dbo.Users', 'UserID') IS NOT NULL
    BEGIN
        INSERT INTO #UserLookup (Id, Name, Email, UserName, Department, Designation, IsActive)
        EXEC sp_executesql N'
            SELECT
                raw.UserID,
                COALESCE(NULLIF(LTRIM(RTRIM(raw.UserName)), ''''), CONCAT(''User '', CAST(raw.UserID AS NVARCHAR(20)))),
                NULL,
                raw.UserName,
                NULL,
                NULL,
                CAST(CASE WHEN ISNULL(raw.Status, 1) = 1 THEN 1 ELSE 0 END AS BIT)
            FROM dbo.Users raw
            WHERE ISNULL(raw.Status, 1) = 1
              AND NULLIF(LTRIM(RTRIM(raw.UserName)), '''') IS NOT NULL
              AND NOT EXISTS (
                  SELECT 1
                  FROM #UserLookup existing
                  WHERE existing.Id = raw.UserID
              );';
    END
    ELSE IF COL_LENGTH('dbo.Users', 'Id') IS NOT NULL
    BEGIN
        INSERT INTO #UserLookup (Id, Name, Email, UserName, Department, Designation, IsActive)
        EXEC sp_executesql N'
            SELECT
                raw.Id,
                raw.Name,
                raw.Email,
                raw.UserName,
                raw.Department,
                raw.Designation,
                CAST(ISNULL(raw.IsActive, 1) AS BIT)
            FROM dbo.Users raw
            WHERE ISNULL(raw.IsActive, 1) = 1
              AND NULLIF(LTRIM(RTRIM(raw.Name)), '''') IS NOT NULL
              AND NOT EXISTS (
                  SELECT 1
                  FROM #UserLookup existing
                  WHERE existing.Id = raw.Id
              );';
    END

    SELECT
        aa.Id,
        aa.Notes AS Remarks,
        aa.AllocatedDate,
        NULL AS ReturnDate,
        aa.UserId,
        COALESCE(u.Name, CONCAT('User ', CAST(aa.UserId AS NVARCHAR(20)))) as UserName,
        u.Email as UserEmail,
        u.Department as UserDepartment,
        aa.DepartmentId,
        d.Name as DepartmentName,
        aa.SubDepartmentId,
        sd.Name as SubDepartmentName,
        aa.RoomId,
        r.Name as RoomName,
        r.Building,
        r.Floor,
        aa.ItemId,
        aa.BranchId,
        b.Name as BranchName,
        CAST(0 AS BIT) AS IsReturn,
        NULL AS ReturnRemarks,
        aa.Quantity,
        NULL AS InventoryItemId,
        i.Name as InventoryItemName,
        aa.SerialNumber,
        NULL AS Model,
        aa.Condition as ItemStatus,
        NULL AS PurchasePrice,
        NULL AS CurrentValue,
        NULL AS SysBatchNo,
        NULL AS BatchNo,
        aa.IsActive,
        aa.CreatedById,
        aa.CreatedOn,
        aa.ModifiedById,
        aa.ModifiedOn
    FROM Inv.AssetAllocations aa
    LEFT JOIN #UserLookup u ON aa.UserId = u.Id
    LEFT JOIN Inv.Departments d ON aa.DepartmentId = d.Id
    LEFT JOIN Inv.SubDepartments sd ON aa.SubDepartmentId = sd.Id
    LEFT JOIN Inv.Rooms r ON aa.RoomId = r.Id
    LEFT JOIN Inv.Branches b ON aa.BranchId = b.Id
    LEFT JOIN Inv.Items i ON aa.ItemId = i.Id
    WHERE aa.IsActive = 1
    ORDER BY aa.AllocatedDate DESC, aa.Id DESC;
END
GO

-- Create AssetAllocation_GetById
CREATE PROCEDURE [dbo].[AssetAllocation_GetById]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #UserLookup
    (
        Id INT NOT NULL PRIMARY KEY,
        Name NVARCHAR(4000) NULL,
        Email NVARCHAR(256) NULL,
        UserName NVARCHAR(256) NULL,
        Department NVARCHAR(256) NULL,
        Designation NVARCHAR(256) NULL,
        IsActive BIT NOT NULL
    );

    -- Note: DropDown.DD_Users is intentionally not used here. It requires mandatory
    -- @UserTypeId/@BranchId/@OrganizationId parameters we have no generic value for,
    -- and Microsoft.Data.SqlClient surfaces its parameter error as a SqlException even
    -- when caught by TRY/CATCH in T-SQL. dbo.Users below is sufficient on its own.
    IF COL_LENGTH('dbo.Users', 'UserID') IS NOT NULL
    BEGIN
        INSERT INTO #UserLookup (Id, Name, Email, UserName, Department, Designation, IsActive)
        EXEC sp_executesql N'
            SELECT
                raw.UserID,
                COALESCE(NULLIF(LTRIM(RTRIM(raw.UserName)), ''''), CONCAT(''User '', CAST(raw.UserID AS NVARCHAR(20)))),
                NULL,
                raw.UserName,
                NULL,
                NULL,
                CAST(CASE WHEN ISNULL(raw.Status, 1) = 1 THEN 1 ELSE 0 END AS BIT)
            FROM dbo.Users raw
            WHERE ISNULL(raw.Status, 1) = 1
              AND NULLIF(LTRIM(RTRIM(raw.UserName)), '''') IS NOT NULL
              AND NOT EXISTS (
                  SELECT 1
                  FROM #UserLookup existing
                  WHERE existing.Id = raw.UserID
              );';
    END
    ELSE IF COL_LENGTH('dbo.Users', 'Id') IS NOT NULL
    BEGIN
        INSERT INTO #UserLookup (Id, Name, Email, UserName, Department, Designation, IsActive)
        EXEC sp_executesql N'
            SELECT
                raw.Id,
                raw.Name,
                raw.Email,
                raw.UserName,
                raw.Department,
                raw.Designation,
                CAST(ISNULL(raw.IsActive, 1) AS BIT)
            FROM dbo.Users raw
            WHERE ISNULL(raw.IsActive, 1) = 1
              AND NULLIF(LTRIM(RTRIM(raw.Name)), '''') IS NOT NULL
              AND NOT EXISTS (
                  SELECT 1
                  FROM #UserLookup existing
                  WHERE existing.Id = raw.Id
              );';
    END

    SELECT
        aa.Id,
        aa.Notes AS Remarks,
        aa.AllocatedDate,
        NULL AS ReturnDate,
        aa.UserId,
        COALESCE(u.Name, CONCAT('User ', CAST(aa.UserId AS NVARCHAR(20)))) as UserName,
        u.Email as UserEmail,
        u.Department as UserDepartment,
        aa.DepartmentId,
        d.Name as DepartmentName,
        aa.SubDepartmentId,
        sd.Name as SubDepartmentName,
        aa.RoomId,
        r.Name as RoomName,
        r.Building,
        r.Floor,
        aa.ItemId,
        aa.BranchId,
        b.Name as BranchName,
        CAST(0 AS BIT) AS IsReturn,
        NULL AS ReturnRemarks,
        aa.Quantity,
        NULL AS InventoryItemId,
        i.Name as InventoryItemName,
        aa.SerialNumber,
        NULL AS Model,
        aa.Condition as ItemStatus,
        NULL AS PurchasePrice,
        NULL AS CurrentValue,
        NULL AS SysBatchNo,
        NULL AS BatchNo,
        aa.IsActive,
        aa.CreatedById,
        aa.CreatedOn,
        aa.ModifiedById,
        aa.ModifiedOn
    FROM Inv.AssetAllocations aa
    LEFT JOIN #UserLookup u ON aa.UserId = u.Id
    LEFT JOIN Inv.Departments d ON aa.DepartmentId = d.Id
    LEFT JOIN Inv.SubDepartments sd ON aa.SubDepartmentId = sd.Id
    LEFT JOIN Inv.Rooms r ON aa.RoomId = r.Id
    LEFT JOIN Inv.Branches b ON aa.BranchId = b.Id
    LEFT JOIN Inv.Items i ON aa.ItemId = i.Id
    WHERE aa.Id = @Id AND aa.IsActive = 1;
END
GO

-- Create AssetAllocation_Insert
CREATE PROCEDURE [dbo].[AssetAllocation_Insert]
    @Remarks NVARCHAR(MAX) = NULL,
    @AllocatedDate DATETIME2,
    @UserId INT = NULL,
    @DepartmentId INT = NULL,
    @SubDepartmentId INT = NULL,
    @RoomId INT = NULL,
    @ItemId INT = NULL,
    @BranchId INT = NULL,
    @Quantity INT = 1,
    @InventoryItemId INT = NULL,
    @SysBatchNo NVARCHAR(MAX) = NULL,
    @BatchNo NVARCHAR(MAX) = NULL,
    @CreatedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @NewId INT;
    
    INSERT INTO Inv.AssetAllocations (
        Remarks, AllocatedDate, UserId, DepartmentId, SubDepartmentId,
        RoomId, ItemId, BranchId, Quantity, InventoryItemId,
        SysBatchNo, BatchNo, IsActive, CreatedById, CreatedOn,
        IsReturn, IsDeleted
    )
    VALUES (
        @Remarks, @AllocatedDate, @UserId, @DepartmentId, @SubDepartmentId,
        @RoomId, @ItemId, @BranchId, @Quantity, @InventoryItemId,
        @SysBatchNo, @BatchNo, @IsActive, @CreatedById, GETUTCDATE(),
        0, 0
    );
    
    SET @NewId = SCOPE_IDENTITY();
    
    -- Update inventory item status to 'Allocated' if InventoryItemId is provided
    IF @InventoryItemId IS NOT NULL
    BEGIN
        UPDATE Inv.InventoryItems 
        SET Status = 'Allocated', ModifiedOn = GETUTCDATE()
        WHERE Id = @InventoryItemId;
    END
    
    SELECT @NewId as Id;
END
GO

-- Create AssetAllocation_Update
CREATE PROCEDURE [dbo].[AssetAllocation_Update]
    @Id INT,
    @Remarks NVARCHAR(MAX) = NULL,
    @AllocatedDate DATETIME2,
    @ReturnDate DATETIME2 = NULL,
    @UserId INT = NULL,
    @DepartmentId INT = NULL,
    @SubDepartmentId INT = NULL,
    @RoomId INT = NULL,
    @ItemId INT = NULL,
    @BranchId INT = NULL,
    @IsReturn BIT = 0,
    @ReturnRemarks NVARCHAR(MAX) = NULL,
    @Quantity INT = 1,
    @InventoryItemId INT = NULL,
    @SysBatchNo NVARCHAR(MAX) = NULL,
    @BatchNo NVARCHAR(MAX) = NULL,
    @ModifiedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get the current InventoryItemId before update
    DECLARE @CurrentInventoryItemId INT;
    SELECT @CurrentInventoryItemId = InventoryItemId 
    FROM Inv.AssetAllocations 
    WHERE Id = @Id;
    
    UPDATE Inv.AssetAllocations
    SET
        Remarks = @Remarks,
        AllocatedDate = @AllocatedDate,
        ReturnDate = @ReturnDate,
        UserId = @UserId,
        DepartmentId = @DepartmentId,
        SubDepartmentId = @SubDepartmentId,
        RoomId = @RoomId,
        ItemId = @ItemId,
        BranchId = @BranchId,
        IsReturn = @IsReturn,
        ReturnRemarks = @ReturnRemarks,
        Quantity = @Quantity,
        InventoryItemId = @InventoryItemId,
        SysBatchNo = @SysBatchNo,
        BatchNo = @BatchNo,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
    
    -- Update inventory item status based on return status
    IF @InventoryItemId IS NOT NULL
    BEGIN
        IF @IsReturn = 1
        BEGIN
            -- Item is being returned
            UPDATE Inv.InventoryItems 
            SET Status = 'Available', ModifiedOn = GETUTCDATE()
            WHERE Id = @InventoryItemId;
        END
        ELSE
        BEGIN
            -- Item is still allocated
            UPDATE Inv.InventoryItems 
            SET Status = 'Allocated', ModifiedOn = GETUTCDATE()
            WHERE Id = @InventoryItemId;
        END
    END
    
    -- If the inventory item changed, update the previous item status
    IF @CurrentInventoryItemId IS NOT NULL AND @CurrentInventoryItemId != @InventoryItemId
    BEGIN
        UPDATE Inv.InventoryItems 
        SET Status = 'Available', ModifiedOn = GETUTCDATE()
        WHERE Id = @CurrentInventoryItemId;
    END
    
    SELECT @@ROWCOUNT as AffectedRows;
END
GO

-- Create AssetAllocation_Delete
CREATE PROCEDURE [dbo].[AssetAllocation_Delete]
    @Id INT,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get the InventoryItemId before soft delete
    DECLARE @InventoryItemId INT;
    SELECT @InventoryItemId = InventoryItemId 
    FROM Inv.AssetAllocations 
    WHERE Id = @Id;
    
    UPDATE Inv.AssetAllocations
    SET
        IsActive = 0,
        IsDeleted = 1,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
    
    -- Update inventory item status back to available
    IF @InventoryItemId IS NOT NULL
    BEGIN
        UPDATE Inv.InventoryItems 
        SET Status = 'Available', ModifiedOn = GETUTCDATE()
        WHERE Id = @InventoryItemId;
    END
    
    SELECT @@ROWCOUNT as AffectedRows;
END
GO

-- Create User_GetAll
CREATE PROCEDURE [dbo].[User_GetAll]
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #UserLookup
    (
        Id INT NOT NULL PRIMARY KEY,
        Name NVARCHAR(4000) NULL,
        Email NVARCHAR(256) NULL,
        UserName NVARCHAR(256) NULL,
        Department NVARCHAR(256) NULL,
        Designation NVARCHAR(256) NULL,
        IsActive BIT NOT NULL
    );

    -- Note: DropDown.DD_Users is intentionally not used here. It requires mandatory
    -- @UserTypeId/@BranchId/@OrganizationId parameters we have no generic value for,
    -- and Microsoft.Data.SqlClient surfaces its parameter error as a SqlException even
    -- when caught by TRY/CATCH in T-SQL. dbo.Users below is sufficient on its own.
    IF COL_LENGTH('dbo.Users', 'UserID') IS NOT NULL
    BEGIN
        INSERT INTO #UserLookup (Id, Name, Email, UserName, Department, Designation, IsActive)
        EXEC sp_executesql N'
            SELECT
                raw.UserID AS Id,
                COALESCE(NULLIF(LTRIM(RTRIM(raw.UserName)), ''''), CONCAT(''User '', CAST(raw.UserID AS NVARCHAR(20)))) AS Name,
                CAST(NULL AS NVARCHAR(256)) AS Email,
                raw.UserName,
                CAST(NULL AS NVARCHAR(256)) AS Department,
                CAST(NULL AS NVARCHAR(256)) AS Designation,
                CAST(CASE WHEN ISNULL(raw.Status, 1) = 1 THEN 1 ELSE 0 END AS BIT) AS IsActive
            FROM dbo.Users raw
            WHERE ISNULL(raw.Status, 1) = 1
              AND NULLIF(LTRIM(RTRIM(raw.UserName)), '''') IS NOT NULL
              AND NOT EXISTS (
                  SELECT 1
                  FROM #UserLookup existing
                  WHERE existing.Id = raw.UserID
              );';
    END

    ELSE IF COL_LENGTH('dbo.Users', 'Id') IS NOT NULL
    BEGIN
        INSERT INTO #UserLookup (Id, Name, Email, UserName, Department, Designation, IsActive)
        EXEC sp_executesql N'
            SELECT
                raw.Id,
                raw.Name,
                raw.Email,
                raw.UserName,
                raw.Department,
                raw.Designation,
                CAST(ISNULL(raw.IsActive, 1) AS BIT) AS IsActive
            FROM dbo.Users raw
            WHERE ISNULL(raw.IsActive, 1) = 1
              AND NULLIF(LTRIM(RTRIM(raw.Name)), '''') IS NOT NULL
              AND NOT EXISTS (
                  SELECT 1
                  FROM #UserLookup existing
                  WHERE existing.Id = raw.Id
              );';
    END

    SELECT
        Id,
        Name,
        Email,
        UserName,
        Department,
        Designation,
        IsActive
    FROM #UserLookup
    ORDER BY Name;
END
GO

-- Create Room_GetAll
CREATE PROCEDURE [dbo].[Room_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Id,
        Name,
        Description,
        Floor,
        Building,
        Capacity,
        IsActive
    FROM Inv.Rooms
    WHERE IsActive = 1
    ORDER BY Building, Floor, Name;
END
GO

-- Create Department_GetAll
CREATE PROCEDURE [dbo].[Department_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Id,
        Name,
        Description,
        Head,
        IsActive
    FROM Inv.Departments
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

-- Create SubDepartment_GetAll
CREATE PROCEDURE [dbo].[SubDepartment_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        sd.Id,
        sd.Name,
        sd.Description,
        sd.DepartmentId,
        d.Name as DepartmentName,
        sd.IsActive
    FROM Inv.SubDepartments sd
    LEFT JOIN Inv.Departments d ON sd.DepartmentId = d.Id
    WHERE sd.IsActive = 1
    ORDER BY d.Name, sd.Name;
END
GO

-- Create InventoryItem_GetAvailable
CREATE PROCEDURE [dbo].[InventoryItem_GetAvailable]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ii.Id,
        ii.Name,
        ii.Description,
        ii.SerialNumber,
        ii.Model,
        ii.BrandId,
        b.Name as BrandName,
        ii.ItemTypeId,
        it.Name as ItemTypeName,
        ii.ItemUnitId,
        iu.Name as ItemUnitName,
        ii.ManufacturerId,
        m.Name as ManufacturerName,
        ii.PurchaseDate,
        ii.PurchasePrice,
        ii.CurrentValue,
        ii.Condition,
        ii.Status,
        ii.BranchId,
        br.Name as BranchName,
        ii.IsActive
    FROM Inv.InventoryItems ii
    LEFT JOIN Inv.Brands b ON ii.BrandId = b.Id
    LEFT JOIN Inv.ItemTypes it ON ii.ItemTypeId = it.Id
    LEFT JOIN Inv.ItemUnits iu ON ii.ItemUnitId = iu.Id
    LEFT JOIN Inv.Manufacturers m ON ii.ManufacturerId = m.Id
    LEFT JOIN Inv.Branches br ON ii.BranchId = br.Id
    WHERE ii.IsActive = 1 AND ii.Status IN ('Available', 'Good')
    ORDER BY ii.Name;
END
GO

PRINT 'All Asset Allocation stored procedures created successfully!';