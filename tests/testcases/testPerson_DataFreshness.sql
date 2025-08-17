CREATE PROCEDURE testPerson_DataFreshness.[test All tables in schema Person have recent ModifiedDate]
AS
BEGIN
    DECLARE @ThresholdDate DATETIME = DATEADD(MONTH, -6, GETDATE()); -- ajustable selon le besoin
    DECLARE @TableName SYSNAME;
    DECLARE @SchemaName SYSNAME = N'Person';
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @msg NVARCHAR(MAX) = '';
    DECLARE @Result INT;

    DECLARE cur CURSOR FOR
    SELECT t.name
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    JOIN sys.columns c ON c.object_id = t.object_id
    WHERE s.name = @SchemaName AND c.name = 'ModifiedDate';

    OPEN cur;
    FETCH NEXT FROM cur INTO @TableName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SQL = '
        IF EXISTS (
            SELECT 1 FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '
            WHERE ModifiedDate >= @ThresholdDate
        )
            SELECT 0;
        ELSE
            SELECT 1;
        ';

        EXEC sp_executesql @SQL, N'@ThresholdDate DATETIME', @ThresholdDate = @ThresholdDate;

        IF @@ROWCOUNT > 0
            SET @msg += QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ', ';

        FETCH NEXT FROM cur INTO @TableName;
    END

    CLOSE cur;
    DEALLOCATE cur;

    IF @msg <> ''
    BEGIN
        SET @msg = N'Tables without fresh data (ModifiedDate < ' + CONVERT(NVARCHAR, @ThresholdDate, 120) + '): ' +
                   LEFT(@msg, LEN(@msg) - 2) + N'.';
        EXEC tSQLt.Fail @msg;
    END
END;
GO
