IF COL_LENGTH('dbo.ContingentBills', 'BudgetHeadId') IS NULL
BEGIN
    ALTER TABLE dbo.ContingentBills
    ADD BudgetHeadId INT NULL;
END
GO
