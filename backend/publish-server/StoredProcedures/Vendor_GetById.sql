-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get vendor by ID with related data
-- =============================================
CREATE PROCEDURE [dbo].[Vendor_GetById]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
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
        v.IsVerified
    FROM dbo.Vendors v
    LEFT JOIN dbo.Countries c ON v.CountryId = c.Id
    LEFT JOIN dbo.StateOrProvinces sp ON v.StateOrProvinceId = sp.Id
    LEFT JOIN dbo.Cities ct ON v.CityId = ct.Id
    LEFT JOIN dbo.Branches b ON v.BranchId = b.Id
    LEFT JOIN dbo.TaxPayerCategories tpc ON v.TaxPayerCategoryId = tpc.Id
    LEFT JOIN dbo.AccountCOAs ap ON v.AccountPayableId = ap.Id
    LEFT JOIN dbo.AccountCOAs ar ON v.AccountReceivableId = ar.Id
    WHERE v.Id = @Id;
END