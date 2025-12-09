-- This stored procedure creates active views for the suplied 
-- team number so you don't to add a number of team number related
-- where clauses in your queries. It also adds in is_deleted = 0
-- so you don't have to add those where clauses as well. 
-- 
-- To add it to your DB, use:
-- 
-- USE SyncDB
-- GO
-- 
-- and then the full CREATE statement
-- 
-- and to execute it, running the following:
-- 
-- EXEC CreateActiveViews @teamNumber = 1

CREATE OR ALTER PROCEDURE CreateActiveViews
    @teamNumber INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @tableName SYSNAME,
        @viewName SYSNAME,
        @sql NVARCHAR(MAX);

    ------------------------------------------------------------
    -- Cursor: iterate over tables containing both team_number
    -- and is_deleted columns
    ------------------------------------------------------------
    DECLARE tableCursor CURSOR FAST_FORWARD FOR
    SELECT t.name
    FROM sys.tables t
    WHERE EXISTS (
        SELECT 1 
        FROM sys.columns c 
        WHERE c.object_id = t.object_id AND c.name = 'team_number'
    )
    AND EXISTS (
        SELECT 1 
        FROM sys.columns c
        WHERE c.object_id = t.object_id AND c.name = 'is_deleted'
    );

    OPEN tableCursor;
    FETCH NEXT FROM tableCursor INTO @tableName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @viewName = @tableName + '_active';

        --------------------------------------------------------
        -- Drop view if it already exists
        --------------------------------------------------------
        IF OBJECT_ID(@viewName, 'V') IS NOT NULL
        BEGIN
            PRINT 'Dropping existing view: ' + @viewName;
            EXEC('DROP VIEW [' + @viewName + ']');
        END

        --------------------------------------------------------
        -- Create or replace the active view
        --------------------------------------------------------
        SET @sql = '
        CREATE VIEW [' + @viewName + '] AS
        SELECT *
        FROM [' + @tableName + ']
        WHERE team_number = ' + CAST(@teamNumber AS VARCHAR(10)) + '
          AND is_deleted = 0;
        ';

        PRINT 'Creating view: ' + @viewName;
        EXEC(@sql);

        FETCH NEXT FROM tableCursor INTO @tableName;
    END;

    CLOSE tableCursor;
    DEALLOCATE tableCursor;

    PRINT 'All active views dropped (if existed) and recreated successfully.';
END