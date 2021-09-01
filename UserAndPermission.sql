--Get Login and their assigned user name
SELECT @@SERVERNAME AS [Server Name],
       sp.name AS [login Name],
       dp.name AS [Mapped User Name]
FROM sys.server_principals sp
    JOIN sys.database_principals dp
        ON (sp.sid = dp.sid)
WHERE dp.name  NOT IN ( 'alterian','ANDREWA','AndrewAl','Public', 'ChrisK','ci_user','ErinW', 'HZdan','InventoryUser', 'JohnH', 'KristinaH','LamH','LINDAJ', 'LJohnson','mannb', 'mattl','michellem','ShannonM')

SELECT @@SERVERNAME AS [Server Name],
       DB_NAME() AS [Database Name],
       p.name AS [Role Name],
       m.name AS [Member Name]
FROM sys.database_role_members rm
    JOIN sys.database_principals p
        ON rm.role_principal_id = p.principal_id
    JOIN sys.database_principals m
        ON rm.member_principal_id = m.principal_id
WHERE m.name NOT IN ( 'alterian','ANDREWA','AndrewAl','Public', 'ChrisK','ci_user','ErinW', 'HZdan','InventoryUser', 'JohnH', 'KristinaH','LamH','LINDAJ', 'LJohnson','mannb', 'mattl','michellem','ShannonM')
ORDER BY [Role Name]

SELECT @@SERVERNAME AS [Server Name],
	  DB_NAME() AS [Database Name],
       USER_NAME(grantee_principal_id) AS 'User/Role',
       state_desc AS 'Permission',
       permission_name AS 'Action',
       CASE class
           WHEN 0 THEN
               'Database::' + DB_NAME()
           WHEN 1 THEN
               OBJECT_NAME(major_id)
           WHEN 3 THEN
               'Schema::' + SCHEMA_NAME(major_id)
       END AS 'Securable'
FROM sys.database_permissions dp
WHERE class IN ( 0, 1, 3 )
      AND minor_id = 0
AND USER_NAME(grantee_principal_id) NOT IN ( 'alterian','ANDREWA','AndrewAl','Public', 'ChrisK','ci_user','ErinW', 'HZdan','InventoryUser', 'JohnH', 'KristinaH','LamH','LINDAJ', 'LJohnson','mannb', 'mattl','michellem','ShannonM')
ORDER BY 'User/Role';

GO

SELECT * FROM sys.database_permissions dp
SELECT * FROM sys.database_principals m

SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN ('Vendor', 'Brand')

:CONNECT COLO-SVCDB01Q.PRIME.LOCAL
USE LoyaltyService
SELECT @@SERVERNAME AS [Server Name],
sp.name AS [login Name], 
dp.name AS [Mapped User Name]
FROM sys.server_principals sp
JOIN sys.database_principals dp ON (sp.sid = dp.sid)
WHERE dp.name IN ('LoyaltySvc')

SELECT @@SERVERNAME AS [Server Name],p.name AS [Role Name],
       m.name AS [Member Name]
FROM sys.database_role_members rm
    JOIN sys.database_principals p
        ON rm.role_principal_id = p.principal_id
    JOIN sys.database_principals m
        ON rm.member_principal_id = m.principal_id
		WHERE m.name = 'LoyaltySvc'

		SELECT @@SERVERNAME AS [Server Name],
    USER_NAME(grantee_principal_id) AS 'User'
  , state_desc AS 'Permission'
  , permission_name AS 'Action'
  , CASE class
      WHEN 0 THEN 'Database::' + DB_NAME()
      WHEN 1 THEN OBJECT_NAME(major_id)
      WHEN 3 THEN 'Schema::' + SCHEMA_NAME(major_id) END AS 'Securable'
FROM sys.database_permissions dp
WHERE class IN (0, 1, 3)
AND minor_id = 0
AND USER_NAME(grantee_principal_id) = 'ApplicationRole'
GO


EXEC sp_change_users_login @Action = 'Report';
GO

EXEC sp_change_users_login 'update_one', 'searchApp', 'searchApp';
GO



SELECT name, type_desc,default_schema_name
FROM sys.database_principals
WHERE type_desc = 'user'

EXEC xp_logininfo 'db_datareader'

SELECT   name,type_desc,is_disabled
FROM     master.sys.server_principals 
WHERE    IS_SRVROLEMEMBER ('sysadmin',name) = 1
ORDER BY name

EXEC sp_helpsrvrolemember 'sysadmin'

exec sp_helprolemember
EXEC sp_helprotect
EXEC sp_helpdbfixedrole


GRANT EXECUTE ON SCHEMA::Utility to [HeliosWebApplication];
go

select * from INFORMATION_SCHEMA.SCHEMATA
order by SCHEMA_NAME DESC


EXEC AS user = 'CI826\rajyalakshmic_ex'


SELECT SUSER_NAME()

IF OBJECT_ID('Staging.TestTable') IS NOT NULL
DROP TABLE Staging.TestTable

CREATE TABLE Staging.TestTable ([id] INT IDENTITY(1,1),
                                [Name] VARCHAR(100) NULL ,
								[DateCreated] DATETIME DEFAULT SYSDATETIMEOFFSET() NOT NULL)

SELECT SUSER_NAME()

REVERT

SELECT SUSER_NAME()


GRANT CREATE TABLE TO Contractor

REVOKE UPDATE ON SCHEMA::Staging TO contractor

ALTER AUTHORIZATION ON SCHEMA:: Staging TO  dbo