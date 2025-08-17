CREATE PROCEDURE testPerson_Structure.[test All Person tables should have a non-nullable uniqueidentifier column rowguid]
AS
BEGIN
    -- Tables du schéma Person ne respectant pas la contrainte sur rowguid
    SELECT s.name AS SchemaName, t.name AS TableName
    INTO #MissingOrInvalidRowguid
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'Person'
    AND NOT EXISTS (
        SELECT 1
        FROM sys.columns c
        WHERE c.object_id = t.object_id
          AND c.name = 'rowguid'
          AND c.is_nullable = 0
          AND c.system_type_id = TYPE_ID('uniqueidentifier')
    );

    IF EXISTS (SELECT 1 FROM #MissingOrInvalidRowguid)
    BEGIN
        DECLARE @msg NVARCHAR(MAX) = N'Tables missing valid rowguid column: ';
        SELECT @msg += QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName) + ', '
        FROM #MissingOrInvalidRowguid;

        SET @msg = LEFT(@msg, LEN(@msg) - 2); -- Supprimer la virgule finale
        EXEC tSQLt.Fail @msg;
    END
END;
GO
