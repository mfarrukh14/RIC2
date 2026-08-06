-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Update existing vendor
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Vendor_Update]
    @Id INT,
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @Email NVARCHAR(MAX) = NULL,
    @CNo NVARCHAR(MAX) = NULL,
    @Address NVARCHAR(MAX) = NULL,
    @NTN NVARCHAR(MAX) = NULL,
    @STN NVARCHAR(MAX) = NULL,
    @CPName1 NVARCHAR(MAX) = NULL,
    @CPEmail1 NVARCHAR(MAX) = NULL,
    @CPContactNumber1 NVARCHAR(MAX) = NULL,
    @CPName2 NVARCHAR(MAX) = NULL,
    @CPEmail2 NVARCHAR(MAX) = NULL,
    @CPContactNumber2 NVARCHAR(MAX) = NULL,
    @CountryId INT = NULL,
    @StateOrProvinceId INT = NULL,
    @CityId INT = NULL,
    @BranchId INT = NULL,
    @Code NVARCHAR(MAX) = NULL,
    @VendorOrCustomer INT = NULL,
    @IncomeTaxStatus INT = NULL,
    @VendorType INT = NULL,
    @TaxPayerCategoryId INT = NULL,
    @TaxPayerStatus INT = NULL,
    @SaleTaxType INT = NULL,
    @ExemptUnderSRO NVARCHAR(MAX) = NULL,
    @AccountPayableId INT = NULL,
    @AccountReceivableId INT = NULL,
    @CreditStatus INT = NULL,
    @NetDueDays INT = NULL,
    @CreditLimit INT = NULL,
    @FaxNo NVARCHAR(MAX) = NULL,
    @IsVerified BIT = 0,
    @ModifiedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.Vendors 
    SET 
        Name = @Name,
        Description = @Description,
        Email = @Email,
        CNo = @CNo,
        Address = @Address,
        NTN = @NTN,
        STN = @STN,
        CPName1 = @CPName1,
        CPEmail1 = @CPEmail1,
        CPContactNumber1 = @CPContactNumber1,
        CPName2 = @CPName2,
        CPEmail2 = @CPEmail2,
        CPContactNumber2 = @CPContactNumber2,
        CountryId = @CountryId,
        StateOrProvinceId = @StateOrProvinceId,
        CityId = @CityId,
        BranchId = @BranchId,
        Code = @Code,
        VendorOrCustomer = @VendorOrCustomer,
        IncomeTaxStatus = @IncomeTaxStatus,
        VendorType = @VendorType,
        TaxPayerCategoryId = @TaxPayerCategoryId,
        TaxPayerStatus = @TaxPayerStatus,
        SaleTaxType = @SaleTaxType,
        ExemptUnderSRO = @ExemptUnderSRO,
        AccountPayableId = @AccountPayableId,
        AccountReceivableId = @AccountReceivableId,
        CreditStatus = @CreditStatus,
        NetDueDays = @NetDueDays,
        CreditLimit = @CreditLimit,
        FaxNo = @FaxNo,
        IsVerified = @IsVerified,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as RowsAffected;
END