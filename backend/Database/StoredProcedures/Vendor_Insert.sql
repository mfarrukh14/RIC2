-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Insert new vendor
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Vendor_Insert]
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
    @CreatedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @NewId INT;
    
    INSERT INTO Inv.Vendors (
        Name, Description, Email, CNo, Address, NTN, STN,
        CPName1, CPEmail1, CPContactNumber1,
        CPName2, CPEmail2, CPContactNumber2,
        CountryId, StateOrProvinceId, CityId, BranchId,
        Code, VendorOrCustomer, IncomeTaxStatus, VendorType,
        TaxPayerCategoryId, TaxPayerStatus, SaleTaxType,
        ExemptUnderSRO, AccountPayableId, AccountReceivableId,
        CreditStatus, NetDueDays, CreditLimit, FaxNo,
        IsVerified, IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @Name, @Description, @Email, @CNo, @Address, @NTN, @STN,
        @CPName1, @CPEmail1, @CPContactNumber1,
        @CPName2, @CPEmail2, @CPContactNumber2,
        @CountryId, @StateOrProvinceId, @CityId, @BranchId,
        @Code, @VendorOrCustomer, @IncomeTaxStatus, @VendorType,
        @TaxPayerCategoryId, @TaxPayerStatus, @SaleTaxType,
        @ExemptUnderSRO, @AccountPayableId, @AccountReceivableId,
        @CreditStatus, @NetDueDays, @CreditLimit, @FaxNo,
        @IsVerified, @IsActive, @CreatedById, GETUTCDATE()
    );
    
    SET @NewId = SCOPE_IDENTITY();
    
    SELECT @NewId as Id;
END