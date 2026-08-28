-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all manufacturers with related data
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Manufacturer_GetAll]
    @BranchId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Display-layer dedup only: a data-entry/import issue left many manufacturers
    -- with an exact-duplicate row sharing the same Name (all currently BranchId
    -- NULL) rather than a genuine cross-branch split. Both rows are still
    -- referenced by real transactional data, so we keep the underlying rows and
    -- just show the lowest-Id copy of each Name here rather than deleting anything.
    ;WITH ManufacturerData AS (
        SELECT
            m.Id,
            m.Name,
            m.Description,
            m.Email,
            m.Address,
            m.CNo,
            m.NTN,
            m.STN,
            m.CPName1,
            m.CPEmail1,
            m.CPContactNumber1,
            m.CPName2,
            m.CPEmail2,
            m.CPContactNumber2,
            m.CountryId,
            c.Name as CountryName,
            m.StateOrProvinceId,
            sp.Name as StateOrProvinceName,
            m.CityId,
            ct.Name as CityName,
            m.BranchId,
            b.Name as BranchName,
            m.RegisteredOwner,
            m.IsActive,
            m.CreatedById,
            m.CreatedOn,
            m.ModifiedById,
            m.ModifiedOn,
            ROW_NUMBER() OVER (PARTITION BY LTRIM(RTRIM(m.Name)) ORDER BY m.Id) AS RowNum
        FROM Inv.Manufacturers m
        LEFT JOIN Inv.Countries c ON m.CountryId = c.Id
        LEFT JOIN Inv.StateOrProvinces sp ON m.StateOrProvinceId = sp.Id
        LEFT JOIN Inv.Cities ct ON m.CityId = ct.Id
        LEFT JOIN Inv.Branches b ON m.BranchId = b.Id
        WHERE m.BranchId = @BranchId
    )
    SELECT
        Id, Name, Description, Email, Address, CNo, NTN, STN,
        CPName1, CPEmail1, CPContactNumber1, CPName2, CPEmail2, CPContactNumber2,
        CountryId, CountryName, StateOrProvinceId, StateOrProvinceName, CityId, CityName,
        BranchId, BranchName, RegisteredOwner, IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn
    FROM ManufacturerData
    WHERE RowNum = 1
    ORDER BY Name;
END