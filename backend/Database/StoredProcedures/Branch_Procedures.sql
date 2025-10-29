-- =============================================
-- Branch Stored Procedures
-- =============================================

-- =============================================
-- Procedure: Branch_GetAll
-- =============================================
IF OBJECT_ID('dbo.Branch_GetAll', 'P') IS NOT NULL
    DROP PROCEDURE dbo.Branch_GetAll;
GO

CREATE PROCEDURE dbo.Branch_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        Id,
        Name,
        Code,
        Address,
        CityId,
        IsActive,
        CreatedOn,
        ModifiedOn
    FROM dbo.Branches
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

PRINT 'Branch stored procedures created successfully';
GO
