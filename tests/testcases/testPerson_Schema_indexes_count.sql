CREATE PROCEDURE testPerson_Schema.[test Tables should not have more than 5 indexes]
AS
BEGIN
    DECLARE @MaxIndexCount INT = 5;

    -- Récupère les tables du schéma Person avec un nombre d'index supérieur au seuil
    SELECT s.name AS SchemaName, t.name AS TableName, COUNT(i.index_id) AS IndexCount
    INTO #OverIndexedTables
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.indexes i ON t.object_id = i.object_id
    WHERE s.name = 'Person'
    AND i.type_desc <> 'HEAP'
    GROUP BY s.name, t.name
    HAVING COUNT(i.index_id) > @MaxIndexCount;

    -- Échec du test si des tables dépassent le seuil
    IF EXISTS (SELECT 1 FROM #OverIndexedTables)
    BEGIN
        DECLARE @msg NVARCHAR(MAX) = N'Tables with too many indexes: ';
        SELECT @msg += QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName) + ' (' + CAST(IndexCount AS NVARCHAR) + '), '
        FROM #OverIndexedTables;

        SET @msg = LEFT(@msg, LEN(@msg) - 1); -- Supprimer la dernière virgule
        EXEC tSQLt.Fail @msg;
    END
END;
GO
