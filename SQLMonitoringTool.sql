IF OBJECT_ID('[dbo].[TableMetaDataHistory]', 'U')
	IS NOT NULL
DROP TABLE [TableMetaDataHistory]

CREATE TABLE [dbo].[TableMetaDataHistory](
	
	[ServerName] [nvarchar](30) NULL,
	[DatabaseName] [nvarchar](100) NULL,
	[SchemaName] [nvarchar](100) NULL,
	[TableName] [nvarchar](500) NULL,
	[RowCounts] [bigint] NULL,
	[TotalSpaceKB] [bigint] NULL,
	[UnusedSpaceKB] BIGINT NULL,
	[TotalSpaceMB] BIGINT NULL,
	[CollectionDate] [Datetime]  DEFAULT GETDATE() NULL  
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_Datetime ON dbo.TableMetaDataHistory(CollectionDate) INCLUDE (TotalSpaceMB,DatabaseName, SchemaName,ServerName)

--Query to get all table size
SELECT 
	@@SERVERNAME AS ServerName,
	DB_NAME() AS DatabaseName,
    a3.name AS SchemaName,
    a2.name AS [TableName],
    a1.rows as RowCounts,
	GETDATE() AS collectionDate,
    --(a1.reserved + ISNULL(a4.reserved,0))* 8 AS reserved, 
    (a1.data * 8) +
    ((CASE 
			WHEN (a1.used + ISNULL(a4.used,0)) > a1.data 
				THEN (a1.used + ISNULL(a4.used,0)) - a1.data 
			ELSE 0 END) * 8) AS TotalSizeKB,
	 (a1.data /1024* 8) +
    ((CASE 
			WHEN (a1.used + ISNULL(a4.used,0)) > a1.data 
				THEN (a1.used + ISNULL(a4.used,0)) - a1.data 
			ELSE 0 END)/1024 * 8) AS TotalSizMB,
    ((CASE 
			WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used 
				THEN (a1.reserved + ISNULL(a4.reserved,0)) - a1.used 
			ELSE 0 END) * 8)/1024 AS TotalUnusedMB
FROM
    (	SELECT 
			ps.object_id,
			SUM (
				CASE
					WHEN (ps.index_id < 2) 
						THEN row_count
					ELSE 0
				END
				) AS [rows],
			SUM (ps.reserved_page_count) AS reserved,
			SUM (
				CASE
					WHEN (ps.index_id < 2) 
						THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
					ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count)
				END
				) AS data,
			SUM (ps.used_page_count) AS used
		FROM sys.dm_db_partition_stats ps
        GROUP BY ps.object_id) AS a1
LEFT OUTER JOIN 
		(SELECT 
			it.parent_id,
			SUM(ps.reserved_page_count) AS reserved,
			SUM(ps.used_page_count) AS used
		 FROM sys.dm_db_partition_stats ps
		 INNER JOIN sys.internal_tables it 
			ON (it.object_id = ps.object_id)
		 WHERE it.internal_type IN (202,204)
		 GROUP BY it.parent_id) 
	AS a4 
	ON (a4.parent_id = a1.object_id)
	INNER JOIN sys.all_objects a2  
	ON ( a1.object_id = a2.object_id ) 
	INNER JOIN sys.schemas a3 
	ON (a2.schema_id = a3.schema_id)
	WHERE a2.type <> N'S' 
		AND a2.type <> N'IT'
		AND a2.is_ms_shipped =0
GO

SELECT * FROM sys.internal_tables

SELECT SUM(used_page_count) AS TotalNumOfUsedPage, 
SUM(row_count) AS TotalNumOfRow
FROM sys.dm_db_partition_stats
WHERE object_id = OBJECT_ID('Customer.Customer');   


SELECT TABLE_SCHEMA, TABLE_NAME,TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = N'BASE TABLE'
ORDER BY TABLE_NAME DESC

SELECT * 
FROM dbo.TableMetaDataHistory 
ORDER BY CollectionDate DESC

DECLARE @StartDate DATE = DATEADD(DAY, -1,GETDATE())
DECLARE @EndDate DATE = GETDATE()

DECLARE @DatabaseName NVARCHAR(256) = N'xxxxxx'
DECLARE @ServerName NVARCHAR(256)  = N'xxxx-xxxx'

IF OBJECT_ID('tempdb..#TableGrowthDelta', 'U')
	IS NOT NULL
DROP TABLE #TableGrowthDelta

CREATE TABLE #TableGrowthDelta
( id INT IDENTITY(1,1),
  objectName VARCHAR(256),
  totalSpaceKB INT,
  tableGrowthDeltaKB INT,
  CollectionDate DATETIME
  
)

INSERT INTO	#TableGrowthDelta
SELECT	ObjectName, 
		TotalSpaceKB, 
		TableGrowthDeltaKB,
		CollectionDate 
FROM (
		    SELECT	[ServerName],
					[DatabaseName], 
					[schemaName]+'.'+[TableName] AS ObjectName, 
					TotalSpaceKB, 
					CollectionDate,
				    TotalSpaceKB-lead(TotalSpaceKB) OVER(PARTITION BY [schemaName]+'.'+[TableName] ORDER BY CollectionDate DESC) AS TableGrowthDeltaKB
     		FROM    TableMetaDataHistory
			where   [DatabaseName] = @DatabaseName
					AND ServerName = @ServerName
					--AND TableName = @TableName
					--AND SchemaName = @SchemaName
					
					) t
	WHERE 
	TableGrowthDeltaKB IS NOT NULL
	AND TableGrowthDeltaKB > 0
	--AND CollectionDate = @CollectionDate
	ORDER BY t.CollectionDate DESC, t.TableGrowthDeltaKB DESC

SELECT 
DENSE_RANK()OVER (ORDER BY CollectionDate DESC) AS [Rank],
objectName, 
totalSpaceKB, 
tableGrowthDeltaKB, 
CollectionDate
FROM #TableGrowthDelta
ORDER BY [Rank]
GO


   --TOp table by table growth
DECLARE @DatabaseName NVARCHAR(256) = N'xxxxx'
DECLARE @ServerName NVARCHAR(256)  = N'xxxxxx'

IF OBJECT_ID('tempdb..#TableGrowthDelta', 'U')
	IS NOT NULL
DROP TABLE #TableGrowthDelta

CREATE TABLE #TableGrowthDelta
( id INT IDENTITY(1,1),
  objectName VARCHAR(256),
  totalSpaceKB INT,
  tableGrowthDeltaKB INT,
  CollectionDate DATETIME
  
)

INSERT INTO	#TableGrowthDelta
SELECT	ObjectName, 
		TotalSpaceKB, 
		TableGrowthDeltaKB,
		CollectionDate 
FROM (
		    SELECT	[ServerName],
					[DatabaseName], 
					[schemaName]+'.'+[TableName] AS ObjectName, 
					TotalSpaceKB, 
					CollectionDate,
				    TotalSpaceKB-lead(TotalSpaceKB) OVER(PARTITION BY [schemaName]+'.'+[TableName] ORDER BY CONVERT(VARCHAR(10), CAST(CollectionDate AS DATE), 101) DESC) AS TableGrowthDeltaKB
     		FROM    TableMetaDataHistory
			where   [DatabaseName] = @DatabaseName
					AND ServerName = @ServerName
					) AS  t
WHERE TableGrowthDeltaKB IS NOT NULL
  AND TableGrowthDeltaKB > 0
ORDER BY t.CollectionDate DESC, t.TableGrowthDeltaKB DESC


SELECT 
DENSE_RANK()OVER (ORDER BY CollectionDate DESC) AS [Rank],
objectName, 
totalSpaceKB, 
tableGrowthDeltaKB, 
CollectionDate
FROM #TableGrowthDelta

ORDER BY [Rank]
GO

--TOP N Table by table size
DECLARE @DatabaseName NVARCHAR(256) = N'AtlasCi';
DECLARE @ServerName NVARCHAR(256)  = N'COLO-ECOMDB02P';
DECLARE @TopNTable INT = 10;
DECLARE @CollectionDate DATE = (SELECT max( CONVERT(VARCHAR(10), CAST(CollectionDate AS DATE), 101))
								FROM dbo.TableMetaDataHistory);

			WITH CTE AS(
		    SELECT	[schemaName]+'.'+[TableName] AS ObjectName, 
					ROW_NUMBER() OVER (PARTITION BY CollectionDate ORDER BY TotalSpaceKB DESC) AS [TableSizeRank],
					TotalSpaceKB, 
					RowCounts,
					CollectionDate
			FROM    TableMetaDataHistory
			where   [DatabaseName] = @DatabaseName
					AND ServerName = @ServerName
			        )

SELECT CTE.ObjectName,
       CTE.TotalSpaceKB / 1000 AS TableSizeMB,
	   cte.RowCounts AS NumberOfRows,
       CONVERT(VARCHAR(10), CAST(CTE.CollectionDate AS DATE), 101) AS CollectionDate
FROM CTE
WHERE 
      CTE.TableSizeRank <= @TopNTable
  AND CTE.CollectionDate >= @CollectionDate
ORDER BY CollectionDate DESC

SELECT max( CONVERT(VARCHAR(10), CAST(CollectionDate AS DATE), 101))
FROM dbo.TableMetaDataHistory
