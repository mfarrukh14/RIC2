-- =============================================
-- Get all categories
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Category_GetAll')
    DROP PROCEDURE [dbo].[Category_GetAll]
GO

CREATE PROCEDURE [dbo].[Category_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Name, Description, IsActive
    FROM Inv.Categories
    ORDER BY Name;
END
GO

-- =============================================
-- Get all sub-categories
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SubCategory_GetAll')
    DROP PROCEDURE [dbo].[SubCategory_GetAll]
GO

CREATE PROCEDURE [dbo].[SubCategory_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT sc.Id, sc.Name, sc.Description, sc.CategoryId, c.Name as CategoryName, sc.IsActive
    FROM Inv.SubCategories sc
    LEFT JOIN Inv.Categories c ON sc.CategoryId = c.Id
    WHERE sc.IsActive = 1
    ORDER BY c.Name, sc.Name;
END
GO

-- =============================================
-- Get all prices
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Price_GetAll')
    DROP PROCEDURE [dbo].[Price_GetAll]
GO

CREATE PROCEDURE [dbo].[Price_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, RetailPrice, SalePrice, MarketPrice, IsActive
    FROM Inv.Prices
    WHERE IsActive = 1
    ORDER BY Id;
END
GO

-- =============================================
-- Get all tax rates
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'TaxRate_GetAll')
    DROP PROCEDURE [dbo].[TaxRate_GetAll]
GO

CREATE PROCEDURE [dbo].[TaxRate_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Name, Rate, IsActive
    FROM Inv.TaxRates
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

-- =============================================
-- Get all tax descriptions
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'TaxDescription_GetAll')
    DROP PROCEDURE [dbo].[TaxDescription_GetAll]
GO

CREATE PROCEDURE [dbo].[TaxDescription_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Name, Description, IsActive
    FROM Inv.TaxDescriptions
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

-- =============================================
-- Get all tax types
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'TaxType_GetAll')
    DROP PROCEDURE [dbo].[TaxType_GetAll]
GO

CREATE PROCEDURE [dbo].[TaxType_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Name, Description, IsActive
    FROM Inv.TaxTypes
    WHERE IsActive = 1
    ORDER BY Name;
END
GO