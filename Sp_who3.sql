

--Fetch api cursor
SELECT result.text, *
FROM sys.dm_exec_connections dec
CROSS APPLY sys.dm_exec_sql_text (dec.most_recent_sql_handle) result
    WHERE session_id = 375
    
	SELECT dec.session_id, dec.properties, dec.creation_time, dec.is_open, result.text
    FROM sys.dm_exec_cursors (375) dec
    CROSS APPLY sys.dm_exec_sql_text (dec.sql_handle) result


SELECT loginame,
	   CAST(a.context_info AS VARCHAR(128)) AS  INFO,
	   --DATEDIFF(SECOND,a.stmt_start,GETDATE()) AS RequestDurationSec,
	   a.stmt_start,
       cpu,
	   a.spid AS LeadBlocker,
       memusage,
       physical_io,
	   a.hostname,
	   t.text
FROM master..sysprocesses a
CROSS APPLY sys.dm_exec_sql_text(a.sql_handle) t
WHERE EXISTS
(
    SELECT b.*
    FROM master..sysprocesses b
    WHERE b.blocked > 0
          AND b.blocked = a.spid
)
      AND NOT EXISTS
(
    SELECT b.*
    FROM master..sysprocesses b
    WHERE b.blocked > 0
          AND b.spid = a.spid
)
ORDER BY spid

EXEC master.dbo.sp_BlitzWho @Help = 0 -- tinyint
GO


SET TRANSACTION isolation level READ uncommitted

SELECT @@SERVERNAME AS [ServerName]
     --,CAST(ses.context_info AS VARBINARY(128)) AS  INFO
	 ,CAST(ses.context_info AS VARCHAR(128)) AS  INFO
     , SPID = er.session_id
    ,BlkBy = CASE WHEN lead_blocker = 1 THEN -1 ELSE er.blocking_session_id END
    ,ElapsedMS = er.total_elapsed_time
    ,CPU = er.cpu_time
    ,IOReads = er.logical_reads + er.reads
    ,IOWrites = er.writes
    ,Executions = ec.execution_count
    ,CommandType = er.command
    ,LastWaitType = er.last_wait_type
    ,ObjectName = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
    ,SQLStatement =
        SUBSTRING
        (
        qt.text,
        er.statement_start_offset/2,
        CASE WHEN
        (
        CASE WHEN er.statement_end_offset = -1
        THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2
        ELSE er.statement_end_offset
        END - er.statement_start_offset / 2
        ) < 0 THEN 0
        ELSE
        CASE WHEN er.statement_end_offset = -1
        THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2
        ELSE er.statement_end_offset
        END - er.statement_start_offset / 2
        END
        )
    ,STATUS = ses.STATUS
    ,[Login] = ses.login_name
    ,Host = ses.host_name
    ,DBName = DB_Name(er.database_id)
    ,StartTime = er.start_time
    ,Protocol = con.net_transport
    ,transaction_isolation =
        CASE ses.transaction_isolation_level
        WHEN 0 THEN 'Unspecified'
        WHEN 1 THEN 'Read Uncommitted'
        WHEN 2 THEN 'Read Committed'
        WHEN 3 THEN 'Repeatable'
        WHEN 4 THEN 'Serializable'
        WHEN 5 THEN 'Snapshot'
        END
    ,ConnectionWrites = con.num_writes
    ,ConnectionReads = con.num_reads
    ,ClientAddress = con.client_net_address
    ,Authentication = con.auth_scheme
    ,DatetimeSnapshot = GETDATE()
    ,plan_handle = er.plan_handle
FROM sys.dm_exec_requests er
LEFT JOIN sys.dm_exec_sessions ses
    ON ses.session_id = er.session_id
LEFT JOIN sys.dm_exec_connections con
    ON con.session_id = ses.session_id
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
OUTER APPLY
(
    SELECT execution_count = MAX(cp.usecounts)
    FROM sys.dm_exec_cached_plans cp
    WHERE cp.plan_handle = er.plan_handle
) ec
OUTER APPLY
(
    SELECT
    lead_blocker = 1
    FROM master.dbo.sysprocesses sp
    WHERE sp.spid IN (SELECT blocked FROM master.dbo.sysprocesses WITH (NOLOCK) WHERE blocked != 0)
    AND sp.blocked = 0
    AND sp.spid = er.session_id
) lb
WHERE er.sql_handle IS NOT NULL
    AND er.session_id != @@SPID
ORDER BY
    CASE WHEN lb.lead_blocker = 1 THEN -1 * 1000 ELSE -er.blocking_session_id END,
    er.blocking_session_id DESC,
    er.logical_reads + er.reads DESC,
    er.session_id;
GO

--To find open transection
SELECT @@SERVERNAME,
CAST(s.context_info AS VARCHAR(128)) AS  INFO,
DATEDIFF(SECOND,s.last_request_start_time,GETDATE()) AS RequestDurationSec,
t.text AS sqlText, 
s.session_id AS SPID,
e.blocking_session_id AS BlkdBy,
s.login_time AS LoginTime,
s.host_name AS HostName,
s.program_name AS ProgramName,
s.login_name AS [User],
s.status AS [Status],
s.cpu_time AS CpuTime,
s.memory_usage MemoryUsage,
DB_NAME(s.database_id) AS DbName,
s.open_transaction_count AS OpenTranCount,
s.row_count AS [RowCount],
s.reads AS Reads,
s.writes AS Writes,
s.logical_reads AS LogicalRead,
s.last_request_start_time AS LastReqsStartTime,
s.last_request_end_time AS LastReqEndTime,
GETDATE() AS SnaphotTime
FROM sys.dm_exec_sessions s
INNER JOIN sys.dm_exec_connections c
       ON c.session_id = s.session_id
JOIN sys.dm_exec_requests e
	   ON e.session_id = c.session_id
CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) t
WHERE 
1 = 1 AND
s.open_transaction_count > 0 AND
s.is_user_process = 1
ORDER BY RequestDurationSec DESC
GO


SELECT @@SERVERNAME AS ServerName,
CAST(context_info AS VARCHAR(128)) AS  AxUserInfo,
DATEDIFF(SECOND,s.last_request_start_time,GETDATE()) AS RequestDurationSec,
t.text AS sqlText, 
c.session_id,
s.login_time,
s.host_name,
s.program_name,
s.client_interface_name,
s.login_name,
s.status,
s.cpu_time,
s.memory_usage,
s.reads,
s.writes,
s.logical_reads,
s.row_count,
c.net_transport,
c.protocol_type,
c.auth_scheme,
s.last_request_start_time AS LastReqsStartTime,
DB_NAME(s.database_id) AS DataBaseName
FROM sys.dm_exec_sessions s
JOIN sys.dm_exec_connections c
ON c.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) t
--WHERE 
--CAST(context_info AS VARCHAR(128)) LIKE ' asdfasdfas%' 
--s.host_name = 'sdfasdf' 
--s.status = 'running' AND 
--s.program_name = 'asdfasdfasd'  
----AND '
ORDER BY RequestDurationSec DESC



SET TRANSACTION isolation level READ uncommitted

SELECT @@SERVERNAME AS [ServerName]
     , SPID = er.session_id
    ,BlkBy = CASE WHEN lead_blocker = 1 THEN -1 ELSE er.blocking_session_id END
    ,ElapsedMS = er.total_elapsed_time
    ,CPU = er.cpu_time
    ,IOReads = er.logical_reads + er.reads
    ,IOWrites = er.writes
    ,Executions = ec.execution_count
    ,CommandType = er.command
    ,LastWaitType = er.last_wait_type
    ,ObjectName = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
    ,SQLStatement =
        SUBSTRING
        (
        qt.text,
        er.statement_start_offset/2,
        CASE WHEN
        (
        CASE WHEN er.statement_end_offset = -1
        THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2
        ELSE er.statement_end_offset
        END - er.statement_start_offset / 2
        ) < 0 THEN 0
        ELSE
        CASE WHEN er.statement_end_offset = -1
        THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2
        ELSE er.statement_end_offset
        END - er.statement_start_offset / 2
        END
        )
    ,STATUS = ses.STATUS
    ,[Login] = ses.login_name
    ,Host = ses.host_name
    ,DBName = DB_Name(er.database_id)
    ,StartTime = er.start_time
    ,Protocol = con.net_transport
    ,transaction_isolation =
        CASE ses.transaction_isolation_level
        WHEN 0 THEN 'Unspecified'
        WHEN 1 THEN 'Read Uncommitted'
        WHEN 2 THEN 'Read Committed'
        WHEN 3 THEN 'Repeatable'
        WHEN 4 THEN 'Serializable'
        WHEN 5 THEN 'Snapshot'
        END
    ,ConnectionWrites = con.num_writes
    ,ConnectionReads = con.num_reads
    ,ClientAddress = con.client_net_address
    ,Authentication = con.auth_scheme
    ,DatetimeSnapshot = GETDATE()
    ,plan_handle = er.plan_handle
FROM sys.dm_exec_requests er
LEFT JOIN sys.dm_exec_sessions ses
    ON ses.session_id = er.session_id
LEFT JOIN sys.dm_exec_connections con
    ON con.session_id = ses.session_id
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
OUTER APPLY
(
    SELECT execution_count = MAX(cp.usecounts)
    FROM sys.dm_exec_cached_plans cp
    WHERE cp.plan_handle = er.plan_handle
) ec
OUTER APPLY
(
    SELECT
    lead_blocker = 1
    FROM master.dbo.sysprocesses sp
    WHERE sp.spid IN (SELECT blocked FROM master.dbo.sysprocesses WITH (NOLOCK) WHERE blocked != 0)
    AND sp.blocked = 0
    AND sp.spid = er.session_id
) lb
WHERE er.sql_handle IS NOT NULL
    AND er.session_id != @@SPID
ORDER BY
    CASE WHEN lb.lead_blocker = 1 THEN -1 * 1000 ELSE -er.blocking_session_id END,
    er.blocking_session_id DESC,
    er.logical_reads + er.reads DESC,
    er.session_id;
GO


--To find open transection
SELECT @@SERVERNAME,
CAST(context_info AS VARCHAR(128)) AS  INFO,
DATEDIFF(SECOND,s.last_request_start_time,GETDATE()) AS RequestDurationSec,
t.text AS sqlText, 
s.session_id AS SPID,
s.login_time AS LoginTime,
s.host_name AS HostName,
s.program_name AS ProgramName,
s.login_name AS [User],
s.status AS [Status],
s.cpu_time AS CpuTime,
s.memory_usage MemoryUsage,
db_Name(s.database_id) AS DbName,
s.open_transaction_count AS OpenTranCount,
s.row_count AS [RowCount],
s.reads AS Reads,
s.writes AS Writes,
s.logical_reads AS LogicalRead,
s.last_request_start_time AS LastReqsStartTime,
s.last_request_end_time AS LastReqEndTime,
GETDATE() AS SnaphotTime
FROM sys.dm_exec_sessions s
INNER JOIN sys.dm_exec_connections c
       ON c.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) t
WHERE 
1 = 1 AND
s.open_transaction_count > 0 AND
s.is_user_process = 1
ORDER BY RequestDurationSec DESC
GO

;WITH CTE AS(
SELECT @@SERVERNAME AS ServerName,
       SUBSTRING(
                    REPLACE(LTRIM(CAST(s.context_info AS VARCHAR(256))), ' ', ','),
                    CHARINDEX(',', REPLACE(LTRIM(CAST(s.context_info AS VARCHAR(256))), ' ', ',')) + 1,
                    CHARINDEX(
                                 ',',
                                 REPLACE(LTRIM(CAST(s.context_info AS VARCHAR(256))), ' ', ','),
                                 CHARINDEX(',', REPLACE(LTRIM(CAST(s.context_info AS VARCHAR(256))), ' ', ',')) + 1
                             ) - (CHARINDEX(',', REPLACE(LTRIM(CAST(s.context_info AS VARCHAR(256))), ' ', ',')))
                    - CASE
                          WHEN CAST(s.context_info AS VARCHAR(256)) = '' THEN
                              0
                          ELSE
                              1
                      END
                ) AS AXSessionID,
       SUBSTRING(
                    REPLACE(LTRIM(CAST(s.context_info AS VARCHAR(256))), ' ', ','),
                    1,
                    CHARINDEX(',', REPLACE(LTRIM(CAST(s.context_info AS VARCHAR(256))), ' ', ','))
                    - CASE
                          WHEN CAST(s.context_info AS VARCHAR(256)) = '' THEN
                              0
                          ELSE
                              1
                      END
                ) AS AXUser,
       CAST(context_info AS VARCHAR(128)) AS INFO,
       DATEDIFF(SECOND, s.last_request_start_time, GETDATE()) AS RequestDurationSec,
       t.text AS SQLText,
       c.session_id AS SQLSessionId,
       s.login_time AS LoginTime,
       s.host_name AS HostName,
       s.program_name AS ProgramName,
       s.client_interface_name AS ClientInterfaceName,
       s.login_name AS LoginName,
       s.cpu_time AS CPUTime,
       s.memory_usage MemoryUsage,
       s.reads AS Reads,
       s.writes AS Writes,
       s.logical_reads AS LogicalRead,
       s.row_count RowNumber,
       c.net_transport NetworkProtocol,
       c.protocol_type NetworkProtocolType,
       c.auth_scheme AS AuthenticationType,
       DB_NAME(s.database_id) AS DatabaseName
FROM sys.dm_exec_sessions s
    JOIN sys.dm_exec_connections c
        ON c.session_id = s.session_id
    CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) t
WHERE s.program_name = 'dffasdfasd'
--and status = 'running'
--ORDER BY RequestDurationSec DESC
)
SELECT * FROM CTE




SET TRANSACTION isolation level READ uncommitted

SELECT @@SERVERNAME AS [ServerName]
     ,ses.open_transaction_count AS TransCount
     , SPID = er.session_id
    ,BlkBy = CASE WHEN lead_blocker = 1 THEN -1 ELSE er.blocking_session_id END
    ,ElapsedMS = er.total_elapsed_time
    ,CPU = er.cpu_time
    ,IOReads = er.logical_reads + er.reads
    ,IOWrites = er.writes
    ,Executions = ec.execution_count
    ,CommandType = er.command
    ,LastWaitType = er.last_wait_type
    ,ObjectName = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
    ,SQLStatement =
        SUBSTRING
        (
        qt.text,
        er.statement_start_offset/2,
        CASE WHEN
        (
        CASE WHEN er.statement_end_offset = -1
        THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2
        ELSE er.statement_end_offset
        END - er.statement_start_offset / 2
        ) < 0 THEN 0
        ELSE
        CASE WHEN er.statement_end_offset = -1
        THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2
        ELSE er.statement_end_offset
        END - er.statement_start_offset / 2
        END
        )
    ,STATUS = ses.STATUS
    ,[Login] = ses.login_name
    ,Host = ses.host_name
    ,DBName = DB_Name(er.database_id)
    ,StartTime = er.start_time
    ,Protocol = con.net_transport
    ,transaction_isolation =
        CASE ses.transaction_isolation_level
        WHEN 0 THEN 'Unspecified'
        WHEN 1 THEN 'Read Uncommitted'
        WHEN 2 THEN 'Read Committed'
        WHEN 3 THEN 'Repeatable'
        WHEN 4 THEN 'Serializable'
        WHEN 5 THEN 'Snapshot'
        END
    ,ConnectionWrites = con.num_writes
    ,ConnectionReads = con.num_reads
    ,ClientAddress = con.client_net_address
    ,Authentication = con.auth_scheme
    ,DatetimeSnapshot = GETDATE()
    ,plan_handle = er.plan_handle
FROM sys.dm_exec_requests er
LEFT JOIN sys.dm_exec_sessions ses
    ON ses.session_id = er.session_id
LEFT JOIN sys.dm_exec_connections con
    ON con.session_id = ses.session_id
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
OUTER APPLY
(
    SELECT execution_count = MAX(cp.usecounts)
    FROM sys.dm_exec_cached_plans cp
    WHERE cp.plan_handle = er.plan_handle
) ec
OUTER APPLY
(
    SELECT
    lead_blocker = 1
    FROM master.dbo.sysprocesses sp
    WHERE sp.spid IN (SELECT blocked FROM master.dbo.sysprocesses WITH (NOLOCK) WHERE blocked != 0)
    AND sp.blocked = 0
    AND sp.spid = er.session_id
) lb
WHERE er.sql_handle IS NOT NULL
    AND er.session_id != @@SPID
	AND 1=1
	AND ses.open_transaction_count >0
ORDER BY
    CASE WHEN lb.lead_blocker = 1 THEN -1 * 1000 ELSE -er.blocking_session_id END,
    er.blocking_session_id DESC,
    er.logical_reads + er.reads DESC,
    er.session_id;
GO

--EXEC master.dbo.sp_BlitzWho @Help = 0 -- tinyint
--GO
--To find open transection
SELECT @@SERVERNAME,
CAST(context_info AS VARCHAR(128)) AS  INFO,
DATEDIFF(SECOND,s.last_request_start_time,GETDATE()) AS RequestDurationSec,
t.text AS sqlText, 
s.session_id AS SPID,
s.login_time AS LoginTime,
s.host_name AS HostName,
s.program_name AS ProgramName,
s.login_name AS [User],
s.status AS [Status],
s.cpu_time AS CpuTime,
s.memory_usage MemoryUsage,
db_Name(s.database_id) AS DbName,
s.open_transaction_count AS OpenTranCount,
s.row_count AS [RowCount],
s.reads AS Reads,
s.writes AS Writes,
s.logical_reads AS LogicalRead,
s.last_request_start_time AS LastReqsStartTime,
s.last_request_end_time AS LastReqEndTime,
GETDATE() AS SnaphotTime
FROM sys.dm_exec_sessions s
INNER JOIN sys.dm_exec_connections c
       ON c.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) t
WHERE 
1 = 1 AND
s.open_transaction_count > 0 AND
s.is_user_process = 1
ORDER BY RequestDurationSec DESC
GO

SELECT @@SERVERNAME AS ServerName,
CAST(context_info AS VARCHAR(128)) AS  INFO,
DATEDIFF(SECOND,s.last_request_start_time,GETDATE()) AS RequestDurationSec,
t.text AS sqlText, 
c.session_id,
s.login_time,
s.status,
s.host_name,
s.program_name,
s.client_interface_name,
s.login_name,
s.cpu_time,
s.memory_usage,
s.reads,
s.writes,
s.logical_reads,
s.row_count,
c.net_transport,
c.protocol_type,
c.auth_scheme,
s.last_request_start_time,
s.last_request_end_time,
DB_NAME(s.database_id)
FROM sys.dm_exec_sessions s
JOIN sys.dm_exec_connections c
ON c.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) t
--WHERE s.program_name = 'sadfasdfasd'
where status = 'running'
AND s.session_id <> (SELECT @@SPID)
ORDER BY s.session_id DESC
GO

SELECT @@SERVERNAME AS ServerName,
CAST(context_info AS VARCHAR(128)) AS  INFO,
DATEDIFF(SECOND,s.last_request_start_time,GETDATE()) AS RequestDurationSec,
t.text AS sqlText, 
c.session_id,
s.login_time,
s.status,
s.host_name,
s.program_name,
s.client_interface_name,
s.login_name,
s.cpu_time,
s.memory_usage,
s.reads,
s.writes,
s.logical_reads,
s.row_count,
c.net_transport,
c.protocol_type,
c.auth_scheme,
s.last_request_start_time,
s.last_request_end_time,
DB_NAME(s.database_id)
FROM sys.dm_exec_sessions s
JOIN sys.dm_exec_connections c
ON c.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) t
Where s.session_id <> (SELECT @@SPID)
--AND status = 'running' 
--AND s.program_name = 'asdfasdf'
ORDER BY s.session_id DESC
GO






SELECT * FROM sys.dm_exec_sessions
SELECT * FROM sys.dm_tran_active_transactions
EXEC xp_fixeddrives 

EXEC sp_MSforeachdb 'Use [?]

SELECT              @@SERvername as ServerName, 
                    GETDATE() as QueryTime,
                    Name, 
                    (size/128) as CurrentSizeMB,
                    Cast(FILEPROPERTY(name, ''SpaceUsed'')as int)/128 as UtilizationMB,
                    ((size/128)- Cast(FILEPROPERTY(name, ''SpaceUsed'')as int)/128) as FreeSpaceMB
                    from sys.database_files;'

SELECT sqlserver_start_time FROM sys.dm_os_sys_info

SELECT result.text, *
FROM sys.dm_exec_connections dec
CROSS APPLY sys.dm_exec_sql_text (dec.most_recent_sql_handle) result
WHERE session_id = 654

SELECT dec.session_id, dec.properties, dec.creation_time, dec.is_open, result.text
FROM sys.dm_exec_cursors (112) dec
CROSS APPLY sys.dm_exec_sql_text (dec.sql_handle) result

USE master;  
GO  
SELECT * FROM sys.dm_exec_cached_plans cp 
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle)
WHERE cp.bucketid = 16013
GO  

SELECT * FROM sys.dm_exec_query_stats qs 
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle)
WHERE qs.plan_handle = (0x060009006858B619607EC4AC3700000001000000000000000000000000000000000000000000000000000000)
GO  




DBCC FREEPROCCACHE(0x05000700BCFF1A51F04D63D41800000001000000000000000000000000000000000000000000000000000000)


SELECT TOP 15 total_worker_time/execution_count AS [Avg CPU Time],  
Plan_handle, query_plan   
FROM sys.dm_exec_query_stats AS qs  
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) 
WHERE qs.plan_handle = (0x06000800B0E13D142037A29C0200000001000000000000000000000000000000000000000000000000000000) 
ORDER BY total_worker_time/execution_count DESC;  
GO  

dbcc inputbuffer (51)
GO

EXEC sp_who2 
GO

SELECT              @@SERvername as ServerName, 
                    GETDATE() as QueryTime,
                    Name, 
                    (size/128) as CurrentSizeMB,
                    Cast(FILEPROPERTY(name, 'SpaceUsed')as int)/128 as UtilizationMB,
                    ((size/128)- Cast(FILEPROPERTY(name, 'SpaceUsed')as int)/128) as FreeSpaceMB
                    from sys.database_files;


select @@VERSION

--Open transactions, last batch an hour or more ago
select 
	convert(varchar(20), db_name(dbid)) as DatabaseName, 
	datediff(mi, last_batch, getdate()) as TransactionDuration, 
	convert(varchar(30), hostname) as HostName, 
	spid
from master..sysprocesses
where open_tran <> 0 and last_batch < dateadd(MM, -1, getdate())
order by 1 asc, 2 desc

SELECT	@@ServerName
,		es.host_name
,		es.login_name
,		es.program_name
,		st.dbid AS QueryExecContextDBID
,		DB_NAME(st.dbid) AS QueryExecContextDBNAME
,		st.objectid AS ModuleObjectId
,		SUBSTRING(st.text, er.statement_start_offset / 2 + 1,
				  (CASE	WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), st.text)) * 2
						ELSE er.statement_end_offset
				   END - er.statement_start_offset) / 2) AS Query_Text
,		tsu.session_id
,		tsu.request_id
,		tsu.exec_context_id
,		(tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count) AS OutStanding_user_objects_page_counts
,		(tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) AS OutStanding_internal_objects_page_counts
,		er.start_time
,		er.command
,		er.open_transaction_count
,		er.percent_complete
,		er.estimated_completion_time
,		er.cpu_time
,		er.total_elapsed_time
,		er.reads
,		er.writes
,		er.logical_reads
,		er.granted_query_memory
FROM	sys.dm_db_task_space_usage tsu
INNER JOIN sys.dm_exec_requests er
		ON (
			tsu.session_id = er.session_id
			AND tsu.request_id = er.request_id
		   )
INNER JOIN sys.dm_exec_sessions es
		ON (tsu.session_id = es.session_id)
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) st
WHERE	(tsu.internal_objects_alloc_page_count + tsu.user_objects_alloc_page_count) > 0
ORDER BY (tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count)
		+ (tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) DESC


sp_who2 157

DECLARE @SPID VARCHAR(20) = 108
DECLARE @PlandHandleID VARBINARY(64) 

SET @PlandHandleID = (SELECT plan_handle
				      FROM sys.dm_exec_requests
					  WHERE session_id = 108)

SELECT * FROM sys.dm_exec_query_plan (@PlandHandleID);
SELECT * FROM sys.dm_server_services
select 
  a.spid
, nt_username
, hostname
, blocked
, [status]
, cmd
, db_name(a.dbid) databasename
, cpu
, physical_io
, substring(text, stmt_start/2, case stmt_end when -1 then datalength(text)+1 else stmt_end/2 end) Query
, last_batch
from master.dbo.sysprocesses a
cross apply sys.dm_exec_sql_text(sql_handle)
--where [status]= 'Sleeping'
order by nt_username desc
--WHERE a.cmd <> 'AWAITING COMMAND' AND a.nt_username <>'sdasfasdf' 

SELECT * 
FROM sys.dm_tran_active_transactions tat 
INNER JOIN sys.dm_exec_requests er 
ON tat.transaction_id = er.transaction_id
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle)

SELECT ec.session_id, tst.is_user_transaction, st.text 
FROM sys.dm_tran_session_transactions tst 
INNER JOIN sys.dm_exec_connections ec 
ON tst.session_id = ec.session_id
CROSS APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) st
SELECT * 
FROM sys.dm_tran_session_transactions tst 
INNER JOIN sys.dm_exec_connections ec ON tst.session_id = ec.session_id
 CROSS APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle)


 select
der.session_id,
der.command,
der.status,
der.percent_complete
from sys.dm_exec_requests as der
where command IN ('killed/rollback','rollback')

SELECT
    s_tst.[session_id],
    [s_es].[login_name] AS [Login Name],
    DB_NAME (s_tdt.database_id) AS [Database],
    [s_tdt].[database_transaction_begin_time] AS [Begin Time],
    [s_tdt].[database_transaction_log_bytes_used] AS [Log Bytes],
    [s_tdt].[database_transaction_log_bytes_reserved] AS [Log Rsvd],
    [s_est].text AS [Last T-SQL Text],
    [s_eqp].[query_plan] AS [Last Plan]
FROM    sys.dm_tran_database_transactions as s_tdt
JOIN    sys.dm_tran_session_transactions as s_tst
ON	    [s_tst].[transaction_id] = [s_tdt].[transaction_id]
JOIN	sys.[dm_exec_sessions] as s_es
ON	    [s_es].[session_id] = [s_tst].[session_id]
JOIN    sys.dm_exec_connections s_ec
ON	    [s_ec].[session_id] = [s_tst].[session_id]
LEFT OUTER JOIN     sys.dm_exec_requests [s_er]
ON     [s_er].[session_id] = [s_tst].[session_id]
CROSS APPLY     sys.dm_exec_sql_text ([s_ec].[most_recent_sql_handle]) AS [s_est]
OUTER APPLY     sys.dm_exec_query_plan ([s_er].[plan_handle]) AS [s_eqp]
ORDER BY    [Begin Time] ASC;
GO


SELECT * FROM sys.dm_tran_session_transactions 
WHERE transaction_id = 6694864519

SELECT * FROM sys.dm_exec_sessions 
WHERE session_id = 104

SELECT * FROM sys.dm_tran_session_transactions 
WHERE transaction_id = 8524158971 

SELECT * FROM sys.dm_exec_sessions 
WHERE session_id in ( 122, 104)

SELECT * FROM sys.dm_exec_sessions 
WHERE session_id = 104




SELECT * FROM SYSSERVERSESSIONS



Exec sp_who
Exec sp_who2 198

  DBCC OPENTRAN

SELECT
db.name DBName,
tl.request_session_id,
wt.blocking_session_id,
OBJECT_NAME(p.OBJECT_ID) BlockedObjectName,
tl.resource_type,
h1.TEXT AS RequestingText,
h2.TEXT AS BlockingTest,
tl.request_mode
FROM sys.dm_tran_locks AS tl
INNER JOIN sys.databases db ON db.database_id = tl.resource_database_id
INNER JOIN sys.dm_os_waiting_tasks AS wt ON tl.lock_owner_address = wt.resource_address
INNER JOIN sys.partitions AS p ON p.hobt_id = tl.resource_associated_entity_id
INNER JOIN sys.dm_exec_connections ec1 ON ec1.session_id = tl.request_session_id
INNER JOIN sys.dm_exec_connections ec2 ON ec2.session_id = wt.blocking_session_id
CROSS APPLY sys.dm_exec_sql_text(ec1.most_recent_sql_handle) AS h1
CROSS APPLY sys.dm_exec_sql_text(ec2.most_recent_sql_handle) AS h2
GO

dbcc inputbuffer(654)

SELECT cp.plan_handle, st.[text]
FROM sys.dm_exec_cached_plans AS cp 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE [text] LIKE N'%SELECT TOP 1 T1.RECID,T1.CREATEDBY,T1.EXECUTEDBY,T1.STARTDATETIME,T1.STARTDATETIMETZID,T1.STATUS,T1.SESSIONIDX, %'
and  ;


SELECT name
     , is_parameterization_forced
  FROM sys.databases;

SELECT  scheduler_id
        ,cpu_id
        ,status
        ,runnable_tasks_count
        ,active_workers_count
        ,load_factor
        ,yield_count 
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255

SELECT TOP 10 st.text
               ,st.dbid
               ,st.objectid
               ,qs.total_worker_time
               ,qs.last_worker_time
               ,qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp 
ORDER BY qs.total_worker_time DESC

SELECT @@VERSION


SELECT 
      [sJOB].[name] AS [JobName]
    , [sJOB].[enabled]
	, [sJOB].[date_created] AS [JobCreatedOn]
    , [sJOB].[date_modified] AS [JobLastModifiedOn]
    
FROM
    [msdb].[dbo].[sysjobs] AS [sJOB]
    LEFT JOIN [msdb].[sys].[servers] AS [sSVR]
    ON [sJOB].[originating_server_id] = [sSVR].[server_id]
    LEFT JOIN [msdb].[dbo].[syscategories] AS [sCAT]
    ON [sJOB].[category_id] = [sCAT].[category_id]
    LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sJSTP]
    ON [sJOB].[job_id] = [sJSTP].[job_id]
    AND [sJOB].[start_step_id] = [sJSTP].[step_id]
    LEFT JOIN [msdb].[sys].[database_principals] AS [sDBP]
    ON [sJOB].[owner_sid] = [sDBP].[sid]
    LEFT JOIN [msdb].[dbo].[sysjobschedules] AS [sJOBSCH]
    ON [sJOB].[job_id] = [sJOBSCH].[job_id]
    LEFT JOIN [msdb].[dbo].[sysschedules] AS [sSCH]
    ON [sJOBSCH].[schedule_id] = [sSCH].[schedule_id]
ORDER BY sJOB.date_modified DESC

BEGIN
    -- Do not lock anything, and do not get held up by any locks.
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    -- What SQL Statements Are Currently Running?
    SELECT [Spid] = session_Id
       , ecid
       , [Database] = DB_NAME(sp.dbid)
       , [User] = nt_username
       , [Status] = er.status
       , [Wait] = wait_type
       , [Individual Query] = SUBSTRING (qt.text, 
             er.statement_start_offset/2,
       (CASE WHEN er.statement_end_offset = -1
              THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
              ELSE er.statement_end_offset END - 
                                er.statement_start_offset)/2)
       ,[Parent Query] = qt.text
       , Program = program_name
       , Hostname
       , nt_domain
       , start_time
       , plan_handle
    FROM sys.dm_exec_requests er
    INNER JOIN sys.sysprocesses sp ON er.session_id = sp.spid
    CROSS APPLY sys.dm_exec_sql_text(er.sql_handle)as qt
    WHERE session_Id > 50              -- Ignore system spids.
    AND session_Id NOT IN (@@SPID)     -- Ignore this current statement.
    ORDER BY 1, 2
END

SELECT * FROM sys.dm_exec_plan_attributes(0x060009001F5C1D31109B97D7DB00000001000000000000000000000000000000000000000000000000000000)

select * from sys.sysprocesses where  spid >= 50 and blocked <> 0

DBCC FREEPROCCACHE
DBCC FREESESSIONCACHE
DBCC FREESYSTEMCACHE


:CONNECT CGS-CIAXMIG01
SELECT creation_time ,cursor_id , CAST(context_info AS VARCHAR(128)) AS  AxUserInfo
    ,name ,c.session_id ,login_name, s.status
FROM sys.dm_exec_cursors(0) AS c   
JOIN sys.dm_exec_sessions AS s   
   ON c.session_id = s.session_id   
WHERE DATEDIFF(mi, c.creation_time, GETDATE()) > 5; 



SELECT dec.session_id, dec.properties, dec.creation_time, dec.is_open, result.text
FROM sys.dm_exec_cursors (112) dec
CROSS APPLY sys.dm_exec_sql_text (dec.sql_handle) result


SELECT CAST(context_info AS VARCHAR(128)) AS AxUserInfo,
      
       s.*
FROM sys.dm_exec_sessions AS s
--CROSS APPLY sys.dm_exec_sql_text(s.most_recent_sql_handle) t
WHERE EXISTS
(
    SELECT *
    FROM sys.dm_tran_session_transactions AS t
    WHERE t.session_id = s.session_id
)
      AND NOT EXISTS
(
    SELECT * FROM sys.dm_exec_requests AS r WHERE r.session_id = s.session_id
);




SELECT   
    c.session_id, c.net_transport, c.encrypt_option,   
    c.auth_scheme, s.host_name, s.program_name,   
    s.client_interface_name, s.login_name, s.nt_domain,   
    s.nt_user_name, s.original_login_name, c.connect_time,   
    s.login_time   
FROM sys.dm_exec_connections AS c  
JOIN sys.dm_exec_sessions AS s  
    ON c.session_id = s.session_id  
WHERE c.session_id = @@SPID;   


SELECT
 @@SERVERNAME
, CAST(context_info AS VARCHAR(128)) AS  INFO
, TransactionDurationSeconds = DATEDIFF(second,dtat.transaction_begin_time,GETDATE())
, [des].[session_id]
, [des].[login_time]
, [des].[host_name]
, [des].[program_name]
, [des].[host_process_id]
, [des].[client_version]
, [des].[client_interface_name]
, [des].[login_name]
, [des].[status]
, [des].[cpu_time]
, [des].[memory_usage]
, [des].[total_scheduled_time]
, [des].[total_elapsed_time]
, [des].[last_request_start_time]
, [des].[last_request_end_time]
, [des].[reads]
, [des].[writes]
, [des].[logical_reads]
, [des].[is_user_process]
, [des].[transaction_isolation_level]
, [des].[lock_timeout]
, [des].[deadlock_priority]
, [des].[row_count]
, [des].[prev_error]
, DB_NAME([des].[database_id]) AS dbName
, des.[database_id]
, [des].[open_transaction_count],
t.[text] AS sqlText
FROM sys.dm_tran_session_transactions dtst
INNER JOIN sys.dm_tran_active_transactions dtat
    ON [dtat].[transaction_id] = [dtst].[transaction_id]
INNER JOIN sys.[dm_exec_connections] dec
    ON [dec].[session_id] = [dtst].[session_id]
LEFT OUTER JOIN sys.[dm_exec_sessions] des
    ON [des].[session_id] = [dec].[session_id]
OUTER APPLY sys.[dm_exec_sql_text](dec.[most_recent_sql_handle]) t
ORDER BY TransactionDurationSeconds DESC
