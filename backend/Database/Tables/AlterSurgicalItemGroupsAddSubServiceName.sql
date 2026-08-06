IF COL_LENGTH('Data.SurgicalItemGroups', 'SubServiceName') IS NULL
BEGIN
    ALTER TABLE Data.SurgicalItemGroups
    ADD SubServiceName NVARCHAR(255) NULL;
END
GO
