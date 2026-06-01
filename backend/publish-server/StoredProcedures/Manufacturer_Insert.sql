-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Insert new manufacturer
-- =============================================
CREATE PROCEDURE [dbo].[Manufacturer_Insert]
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
    
    INSERT INTO dbo.Manufacturers (
        Name, Description, Email, Address, CNo, NTN, STN,
        CPName1, CPEmail1, CPContactNumber1,
        CPName2, CPEmail2, CPContactNumber2,
        CountryId, StateOrProvinceId, CityId, BranchId,
        RegisteredOwner, IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @Name, @Description, @Email, @Address, @CNo, @NTN, @STN,
        @CPName1, @CPEmail1, @CPContactNumber1,
        @CPName2, @CPEmail2, @CPContactNumber2,
        @CountryId, @StateOrProvinceId, @CityId, @BranchId,
        @RegisteredOwner, @IsActive, @CreatedById, GETUTCDATE()
    );
    
    SET @NewId = SCOPE_IDENTITY();
    
    SELECT @NewId as Id;
END