-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Update existing manufacturer
-- =============================================
CREATE PROCEDURE [dbo].[Manufacturer_Update]
    @Id INT,
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
    @ModifiedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.Manufacturers
    SET
        Name = @Name,
        Description = @Description,
        Email = @Email,
        Address = @Address,
        CNo = @CNo,
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
        RegisteredOwner = @RegisteredOwner,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END