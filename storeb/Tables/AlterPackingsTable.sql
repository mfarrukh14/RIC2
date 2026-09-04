IF COL_LENGTH('dbo.Packings', 'Pack') IS NULL
BEGIN
    ALTER TABLE dbo.Packings
    ADD Pack INT NULL;
END
GO

IF COL_LENGTH('dbo.Packings', 'Leaf') IS NULL
BEGIN
    ALTER TABLE dbo.Packings
    ADD Leaf INT NULL;
END
GO

IF COL_LENGTH('dbo.Packings', 'NumberOfItems') IS NULL
BEGIN
    ALTER TABLE dbo.Packings
    ADD NumberOfItems INT NULL;
END
GO
