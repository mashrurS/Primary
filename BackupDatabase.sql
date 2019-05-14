
DECLARE @date DATETIME = GETDATE()
DECLARE @forDate  VARCHAR(100) = (SELECT REPLACE(CONVERT(VARCHAR(8), @date, 112)+CONVERT(VARCHAR(8), @date, 114), ':','')) 
DECLARE @DbName VARCHAR(50)= 'WebSyncCSS'
DECLARE @Pathbak VARCHAR(200) = '\\sqlmgr\TOMBSTONE\FIGURADO\'+ @DbName+@forDate +'.bak'
DECLARE @Sqlcommand VARCHAR(200)
--DECLARE @Pathtrn VARCHAR(200) = 'F:\'+ @DbName+@forDate +'.trn'
SELECT @Pathbak

BACKUP DATABASE @DbName TO DISK = @Pathbak WITH COPY_ONLY, COMPRESSION, MIRROR  STATS = 5;



BACKUP LOG ReclaimSpace TO DISK = @Pathtrn WITH COMPRESSION, STATS =1;
--GO

RESTORE HEADERONLY FROM DISK = @Pathbak;
RESTORE FILELISTONLY FROM DISK = @Pathbak;


SET @Sqlcommand = 'ALTER DATABASE ['+ @DbName + '] SET OFFLINE WITH ROLLBACK IMMEDIATE;'

EXEC (@Sqlcommand)



EXECUTE SQLAdmin.[dbo].[DatabaseBackup] @Databases = 'ILS',
                                        @Directory = N'B:\MSSQL\Backup',
                                        @BackupType = 'FULL',
                                        @Compress = 'Y',
                                        @Verify = 'Y',
                                        @CleanupTime = 24,
                                        @MirrorDirectory = N'\\sqlmgr\SQLBackups\',
                                        @MirrorCleanupTime = 72,
                                        @CheckSum = 'Y',
                                        @LogToTable = 'Y',
										@copyONly= 'Y'