CREATE PROCEDURE testPerson_Schema.[test All tables in Person schema should have a primary key]
AS
BEGIN
    -- R�cup�ration des tables du sch�ma "Person" sans cl� primaire
    SELECT s.name AS SchemaName, t.name AS TableName
    INTO #TablesWithoutPK
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'Person'
    AND NOT EXISTS (
        SELECT 1
        FROM sys.indexes i
        WHERE i.object_id = t.object_id
        AND i.is_primary_key = 1
    );

    -- Si des tables sans cl� primaire sont trouv�es, le test �choue
    IF EXISTS (SELECT 1 FROM #TablesWithoutPK)
    BEGIN
        DECLARE @msg NVARCHAR(MAX) = N'Tables without primary key: ';
        SELECT @msg += QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName) + ', '
        FROM #TablesWithoutPK;

        SET @msg = LEFT(@msg, LEN(@msg) - 1); -- Supprimer la derni�re virgule
        EXEC tSQLt.Fail @msg;
    END
END;
GO
