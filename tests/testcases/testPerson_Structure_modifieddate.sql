CREATE PROCEDURE testPerson_Structure.[test All Person tables should have a non-nullable datetime column ModifiedDate]
AS
BEGIN
    -- Tables du schéma Person ne respectant pas la règle
    SELECT s.name AS SchemaName, t.name AS TableName
    INTO #MissingOrInvalidModifiedDate
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'Person'
    AND NOT EXISTS (
        SELECT 1
        FROM sys.columns c
        WHERE c.object_id = t.object_id
          AND c.name = 'ModifiedDate'
          AND c.is_nullable = 0
          AND c.system_type_id = TYPE_ID('datetime')
    );

    IF EXISTS (SELECT 1 FROM #MissingOrInvalidModifiedDate)
    BEGIN
        DECLARE @msg NVARCHAR(MAX) = N'Tables missing valid ModifiedDate column: ';
        SELECT @msg += QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName) + ', '
        FROM #MissingOrInvalidModifiedDate;

        SET @msg = LEFT(@msg, LEN(@msg) - 2); -- Supprime la virgule finale
        EXEC tSQLt.Fail @msg;
    END
END;
GO
