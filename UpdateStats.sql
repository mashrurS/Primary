

UPDATE STATISTICS dbo.xxxxx I_359STATUSITEMIDX

DBCC SHOW_STATISTICS (xxxx, p)


UPDATE STATISTICS dbo.xxxx WITH FULLSCAN
GO


UPDATE STATISTICS dbo.xxxx WITH FULLSCAN-- _WA_Sys_00000020_343F9543 WITH FULLSCAN
GO

UPDATE STATISTICS dbo.xxxx WITH FULLSCAN
GO

ALTER INDEX ALL ON dbo.xxx REBUILD
GO


SELECT name AS index_name, object_id,
index_id AS indexID,
STATS_DATE(OBJECT_ID, index_id) AS StatsUpdated
FROM sys.indexes
WHERE OBJECT_ID = OBJECT_ID('dbo.xxxx')
GO

SELECT name FROM sys.indexes
WHERE OBJECT_ID = OBJECT_ID('Search.xxxx')

--Findout when all the stats were updated.
SELECT 
	OBJECT_NAME(object_id) AS [ObjectName]
   ,[name] AS [StatisticName]
   ,COALESCE(cast((STATS_DATE([object_id],[stats_id])) AS VARCHAR(20)), 'NEVER') AS [StatisticUpdateDate]
FROM sys.stats
WHERE OBJECT_ID  = OBJECT_ID('xxx')
OR  object_id = OBJECT_ID('xxxx')


OR object_id = OBJECT_ID('xxxxx')
GO


--SELECT s.name AS statistics_name  
--      ,c.name AS column_name  
--      ,sc.stats_column_id  
--FROM sys.stats AS s  
--INNER JOIN sys.stats_columns AS sc   
--    ON s.object_id = sc.object_id AND s.stats_id = sc.stats_id  
--INNER JOIN sys.columns AS c   
--    ON sc.object_id = c.object_id AND c.column_id = sc.column_id  
--WHERE s.object_id = OBJECT_ID('xxxx.xxxx'); 


--SELECT * FROM sys.stats
--WHERE OBJECT_ID = OBJECT_ID('dbo.xxxx')


SELECT 
    si.name
  , us.index_id
  , us.last_user_seek
  , us.last_user_scan
  , us.last_user_lookup
  , us.last_user_update
  , us.last_system_seek
  , us.last_system_scan
  , us.last_system_lookup
  , us.last_system_update
FROM sys.dm_db_index_usage_stats us
JOIN sys.indexes si
ON us.index_id = si.index_id
AND us.object_id = si.object_id
WHERE si.object_id = OBJECT_ID('dbo.xxxxx')
ORDER BY si.name




SELECT * FROM dbo.MCRCOUPON

DBCC SHOW_STATISTICS('dbo.xxxx'
                     ,'_WA_Sys_00000001_304B73AF')

					 SELECT o.name, i.name AS [Index Name],  
       STATS_DATE(i.[object_id], i.index_id) AS [Statistics Date], 
       s.auto_created, s.no_recompute, s.user_created
FROM sys.objects AS o WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON o.[object_id] = i.[object_id]
INNER JOIN sys.stats AS s WITH (NOLOCK)
ON i.[object_id] = s.[object_id] 
AND i.index_id = s.stats_id
WHERE o.[type] = 'U'
ORDER BY STATS_DATE(i.[object_id], i.index_id) ASC; 


SELECT o.name, i.name AS [Index Name],  
       STATS_DATE(i.[object_id], i.index_id) AS [Statistics Date], 
       s.auto_created, s.no_recompute, s.user_created
FROM sys.objects AS o WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON o.[object_id] = i.[object_id]
INNER JOIN sys.stats AS s WITH (NOLOCK)
ON i.[object_id] = s.[object_id] 
AND i.index_id = s.stats_id
WHERE o.[type] = 'U'
ORDER BY STATS_DATE(i.[object_id], i.index_id) ASC; 

SELECT DISTINCT
	tablename=object_name(i.object_id)
	, o.type_desc
	,index_name=i.[name]
    , statistics_update_date = STATS_DATE(i.object_id, i.index_id)
	, si.rowmodctr
FROM sys.indexes i (nolock)
JOIN sys.objects o (nolock) on
	i.object_id=o.object_id
JOIN sys.sysindexes si (nolock) on
	i.object_id=si.id
	and i.index_id=si.indid
where
	o.type  ='S'  --ignore system objects
	and STATS_DATE(i.object_id, i.index_id) is not null
order by si.rowmodctr DESC

SELECT * FROM sys.dm_db_stats_properties()

SELECT 
    stat.auto_created,
    stat.name as stats_name,
    STUFF((SELECT ', ' + cols.name
        FROM sys.stats_columns AS statcols
        JOIN sys.columns AS cols ON
            statcols.column_id=cols.column_id
            AND statcols.object_id=cols.object_id
        WHERE statcols.stats_id = stat.stats_id and
            statcols.object_id=stat.object_id
        ORDER BY statcols.stats_column_id
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '')  as stat_cols,
    stat.filter_definition,
    stat.is_temporary,
    stat.no_recompute,
    sp.last_updated,
    sp.modification_counter,
    sp.rows,
    sp.rows_sampled
FROM sys.stats as stat
CROSS APPLY sys.dm_db_stats_properties (stat.object_id, stat.stats_id) AS sp
JOIN sys.objects as so on 
    stat.object_id=so.object_id
JOIN sys.schemas as sc on
    so.schema_id=sc.schema_id
--WHERE 
--    sc.name= 'xxxx'
--    and so.name='xxxx'
ORDER BY 1, 2;
GO
