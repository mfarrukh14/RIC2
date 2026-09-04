-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Insert new manufacturer
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Manufacturer_Insert]
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @Email NVARCHAR(MAX) = NULL,
    @Address NVARCHAR(MAX) = NULL,
    @CNo NVARCHAR(MAX) = NULL,
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
    @RegisteredOwner NVARCHAR(MAX) = NULL,
    @CreatedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewId INT;

    INSERT INTO Pharmacy.Manufacturers (
        Name, Description, Email, Address, MobileNo, NTN, STN,
        CPName1, CPEmail1, CPContactNumber1,
        CPName2, CPEmail2, CPContactNumber2,
        CountryId, StateOrProvinceId, CityId, BranchId,
        RegisteredOwner, IsActive, IsDeleted, CreatedById, CreatedOn
    )
    VALUES (
        @Name, @Description, @Email, @Address, @CNo, @NTN, @STN,
        @CPName1, @CPEmail1, @CPContactNumber1,
        @CPName2, @CPEmail2, @CPContactNumber2,
        @CountryId, @StateOrProvinceId, @CityId, @BranchId,
        @RegisteredOwner, @IsActive, 0, @CreatedById, GETUTCDATE()
    );

    SET @NewId = SCOPE_IDENTITY();

    SELECT @NewId as Id;
END
