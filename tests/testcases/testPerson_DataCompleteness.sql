CREATE PROCEDURE testPerson_DataCompleteness.[test No column in Person schema should be completely NULL]
AS
BEGIN
    DECLARE @SchemaName SYSNAME = N'Person';
    DECLARE @TableName SYSNAME, @ColumnName SYSNAME;
    DECLARE @SQL NVARCHAR(MAX), @msg NVARCHAR(MAX) = '';
    DECLARE @NullOnly BIT;

    DECLARE TableCursor CURSOR FOR
    SELECT t.name, c.name
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.columns c ON c.object_id = t.object_id
    WHERE s.name = @SchemaName;

    OPEN TableCursor;
    FETCH NEXT FROM TableCursor INTO @TableName, @ColumnName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SQL = '
        SELECT @NullOnly_OUT = CASE WHEN COUNT(1) = 0 THEN 0
                                     WHEN COUNT([' + @ColumnName + ']) = 0 THEN 1
                                     ELSE 0 END
        FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ';';

        EXEC sp_executesql
            @SQL,
            N'@NullOnly_OUT BIT OUTPUT',
            @NullOnly_OUT = @NullOnly OUTPUT;

        IF @NullOnly = 1
        BEGIN
            SET @msg += QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '.' + QUOTENAME(@ColumnName) + ', ';
        END

        FETCH NEXT FROM TableCursor INTO @TableName, @ColumnName;
    END

    CLOSE TableCursor;
    DEALLOCATE TableCursor;

    IF @msg <> ''
    BEGIN
        SET @msg = N'Columns that are completely NULL: ' + LEFT(@msg, LEN(@msg) - 2) + N'.';
        EXEC tSQLt.Fail @msg;
    END
END;
GO
