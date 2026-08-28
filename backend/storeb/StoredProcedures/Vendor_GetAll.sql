-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all vendors with related data
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Vendor_GetAll]
    @BranchId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Display-layer dedup only: a data-entry/import issue left many vendors with
    -- an exact-duplicate row sharing the same Name (same BranchId in every case
    -- observed) rather than a genuine cross-branch split. Both rows are still
    -- referenced by real transactional data, so we keep the underlying rows and
    -- just show the lowest-Id copy of each Name here rather than deleting anything.
    ;WITH VendorData AS (
        SELECT
            v.Id,
            v.Name,
            v.Description,
            v.Email,
            v.CNo,
            v.Address,
            v.NTN,
            v.STN,
            v.CPName1,
            v.CPEmail1,
            v.CPContactNumber1,
            v.CPName2,
            v.CPEmail2,
            v.CPContactNumber2,
            v.CountryId,
            c.Name as CountryName,
            v.StateOrProvinceId,
            sp.Name as StateOrProvinceName,
            v.CityId,
            ct.Name as CityName,
            v.BranchId,
            b.Name as BranchName,
            v.IsActive,
            v.CreatedById,
            v.CreatedOn,
            v.ModifiedById,
            v.ModifiedOn,
            v.Code,
            v.VendorOrCustomer,
            v.IncomeTaxStatus,
            v.VendorType,
            v.TaxPayerCategoryId,
            tpc.Name as TaxPayerCategoryName,
            v.TaxPayerStatus,
            v.SaleTaxType,
            v.ExemptUnderSRO,
            v.AccountPayableId,
            ap.Name as AccountPayableName,
            v.AccountReceivableId,
            ar.Name as AccountReceivableName,
            v.CreditStatus,
            v.NetDueDays,
            v.CreditLimit,
            v.FaxNo,
            v.IsVerified,
            ROW_NUMBER() OVER (PARTITION BY LTRIM(RTRIM(v.Name)) ORDER BY v.Id) AS RowNum
        FROM Inv.Vendors v
        LEFT JOIN Inv.Countries c ON v.CountryId = c.Id
        LEFT JOIN Inv.StateOrProvinces sp ON v.StateOrProvinceId = sp.Id
        LEFT JOIN Inv.Cities ct ON v.CityId = ct.Id
        LEFT JOIN Inv.Branches b ON v.BranchId = b.Id
        LEFT JOIN Inv.TaxPayerCategories tpc ON v.TaxPayerCategoryId = tpc.Id
        LEFT JOIN Inv.AccountCOAs ap ON v.AccountPayableId = ap.Id
        LEFT JOIN Inv.AccountCOAs ar ON v.AccountReceivableId = ar.Id
        WHERE v.BranchId = @BranchId
    )
    SELECT
        Id, Name, Description, Email, CNo, Address, NTN, STN,
        CPName1, CPEmail1, CPContactNumber1, CPName2, CPEmail2, CPContactNumber2,
        CountryId, CountryName, StateOrProvinceId, StateOrProvinceName, CityId, CityName,
        BranchId, BranchName, IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn,
        Code, VendorOrCustomer, IncomeTaxStatus, VendorType, TaxPayerCategoryId, TaxPayerCategoryName,
        TaxPayerStatus, SaleTaxType, ExemptUnderSRO, AccountPayableId, AccountPayableName,
        AccountReceivableId, AccountReceivableName, CreditStatus, NetDueDays, CreditLimit, FaxNo, IsVerified
    FROM VendorData
    WHERE RowNum = 1
    ORDER BY Name;
END