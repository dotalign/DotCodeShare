CREATE OR ALTER PROCEDURE dbo.CleanupEfTempTables
(
    @dryRun BIT = 1,                 -- 1 = preview only, 0 = actually drop
    @schemaName SYSNAME = 'dbo',     -- NULL = all schemas
    @maxAgeDays INT = NULL           -- NULL = no age filter
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @startTime DATETIME2 = SYSUTCDATETIME(),
        @candidateCount INT = 0,
        @executedCount INT = 0,
        @sql NVARCHAR(MAX) = N'',
        @dryRunInt INT = CAST(@dryRun AS INT);

    ------------------------------------------------------------------
    -- Header
    ------------------------------------------------------------------
    RAISERROR('=== CleanupEfTempTables started ===', 0, 1) WITH NOWAIT;
    RAISERROR('Dry run mode: %d', 0, 1, @dryRunInt) WITH NOWAIT;

    IF @schemaName IS NOT NULL
        RAISERROR('Schema filter: %s', 0, 1, @schemaName) WITH NOWAIT;
    ELSE
        RAISERROR('Schema filter: ALL', 0, 1) WITH NOWAIT;

    IF @maxAgeDays IS NOT NULL
        RAISERROR('Max age (days): %d', 0, 1, @maxAgeDays) WITH NOWAIT;
    ELSE
        RAISERROR('Max age: NONE', 0, 1) WITH NOWAIT;

    ------------------------------------------------------------------
    -- Materialize candidate tables
    ------------------------------------------------------------------
    DECLARE @CandidateTables TABLE
    (
        schemaName SYSNAME,
        tableName  SYSNAME,
        create_date DATETIME2
    );

    INSERT INTO @CandidateTables (schemaName, tableName, create_date)
    SELECT
        s.name,
        t.name,
        t.create_date
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN (VALUES
        ('contact'),
        ('company'),
        ('colleague'),
        ('sync_tracker')
    ) AS p(prefix)
      ON t.name COLLATE Latin1_General_BIN
         LIKE p.prefix + '%Temp[0-9A-Fa-f][0-9A-Fa-f]%'
    WHERE
        (@schemaName IS NULL OR s.name = @schemaName)
        AND (
            @maxAgeDays IS NULL
            OR t.create_date < DATEADD(day, -@maxAgeDays, SYSUTCDATETIME())
        );

    ------------------------------------------------------------------
    -- Preview candidates
    ------------------------------------------------------------------
    SELECT *
    FROM @CandidateTables
    ORDER BY create_date DESC;

    SELECT @candidateCount = COUNT(*) FROM @CandidateTables;

    RAISERROR('Candidate tables found: %d', 0, 1, @candidateCount) WITH NOWAIT;

    IF @candidateCount = 0
    BEGIN
        RAISERROR('No matching EF temp tables found. Exiting.', 0, 1) WITH NOWAIT;
        GOTO Summary;
    END

    ------------------------------------------------------------------
    -- Build DROP statements
    ------------------------------------------------------------------
    SELECT @sql +=
        N'DROP TABLE '
        + QUOTENAME(schemaName) + N'.' + QUOTENAME(tableName) + N';'
        + CHAR(13)
    FROM @CandidateTables;

    RAISERROR('Generated DROP statements:', 0, 1) WITH NOWAIT;
    PRINT @sql;

    ------------------------------------------------------------------
    -- Execute or skip
    ------------------------------------------------------------------
    IF @dryRun = 1
    BEGIN
        RAISERROR('Dry run enabled — no tables were dropped.', 0, 1) WITH NOWAIT;
    END
    ELSE
    BEGIN
        RAISERROR('Executing DROP statements...', 0, 1) WITH NOWAIT;
        EXEC sp_executesql @sql;
        SET @executedCount = @candidateCount;
        RAISERROR('DROP execution completed.', 0, 1) WITH NOWAIT;
    END

    ------------------------------------------------------------------
    -- Summary footer
    ------------------------------------------------------------------
    Summary:

    DECLARE @durationMs INT =
        DATEDIFF(MILLISECOND, @startTime, SYSUTCDATETIME());

    RAISERROR('=== CleanupEfTempTables summary ===', 0, 1) WITH NOWAIT;
    RAISERROR('Dry run mode        : %d', 0, 1, @dryRunInt) WITH NOWAIT;
    RAISERROR('Tables matched      : %d', 0, 1, @candidateCount) WITH NOWAIT;
    RAISERROR('Tables dropped      : %d', 0, 1, @executedCount) WITH NOWAIT;
    RAISERROR('Execution time (ms) : %d', 0, 1, @durationMs) WITH NOWAIT;
    RAISERROR('=== CleanupEfTempTables finished ===', 0, 1) WITH NOWAIT;
END;
GO