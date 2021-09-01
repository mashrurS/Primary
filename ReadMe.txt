App name: mkt-cloud-feeds
App version: 1.0.0
App responsible for: Generate csv file from SQL queries and upload them to sftp location.
App language compatibility: Python 3 and up.
App scheduler: Windows task scheduler/ Build and create exe and run as windows service on production - Test in local environment, production test - pending.
Remote branch: feature/mkt-cloud-feeds

Python library dependency: pyodbc, pandas, paramiko

Folder structure: 1. mkt-cloud-feeds-python: Version controlled. All python scripts and readme files. This folder lives on Deployed server (\\CORP-ETLDB01\MKTCloudFeeds).
				  2. sql-scripts: Version controlled. All SQL scripts to read data from database. This folder lives on Deployed server (\\CORP-ETLDB01\MKTCloudFeeds).
				  3. Inbound: All downloaded CSV/TXT file location. This folder lives on file share location. (\\CORP-fs01\Shared\MKTCloudFeeds)
				  4. Outbound: All generated CSV/TXT file location. This folder lives on file share location. (\\CORP-fs01\Shared\MKTCloudFeeds)
				  5. Archive: All zipped CSV/TXT file location after import and export. (\\CORP-fs01\Shared\MKTCloudFeeds)
				  6. log: All application log file location. This folder lives on Deployed server (\\CORP-ETLDB01\MKTCloudFeeds)
				  7. configFile: All configuration file location to run this app. This folder lives on Deployed server (\\CORP-ETLDB01\MKTCloudFeeds)
				  
Parameters: All necessary parameters for this app is configured in configFile folder at source_config.json file and environment variable on Deployed server(CORP-ETLDB01). 
			
			source_config.json parameters: 1. All necessary folder location under "folder_location_config" object.
										   2. All full load  values are under "full_load_source_config".
												a. "script" : Name of the SQL script that will generate the output CSV/TXT file.
												b. "connectionString": connection type, server name, database name and authentication mode of the for the sql script.
							
													How to add new full load feed:	Please add following at the end of the full load object between []
															,{
																"script": "newScriptName.sql",
																"connectionString": "driver={SQL SERVER}; server=ServerName;database=DatabaseName;trusted_connection = YES;"
															}
										   3. All incremental load  values are under "incremental_source_config".
												a. "script" : Name of the SQL script that will generate the output CSV/TXT file.
												b. "connectionString": connection type, server name, database name and authentication mode of the for the sql script.
												c. "incrementOn":	Specific value for incremental load. This value will read by the app before any incremental load to update SQL queries and
																	will be updated and stored in \\CORP-ETLDB01\MKTCloudFeeds\configFile\incremental_load_config.csv file for next incremental load for the same
																	SQL script.
												d. "incrementDataType": Data type of incrementOn value. For now it only supported DATETIME and INT.
							
													How to add new incremental load feed:	Please add following at the end of the full load object between []
															,{
																"script": "newScriptName.sql",
																"connectionString": "driver={SQL SERVER}; server=ServerName;database=DatabaseName;trusted_connection = YES;",
																"incrementOn": "Column name",
																"incrementDataType": "Data type"
															 }
			environment variable parameters: All the following sensitive information is stored under environment variables in CORP-ETLDB01.
											1. User Variable for BSSBIETLUSER: AUTO_EMAIL
											   variable description: This value is for sending error email to SQLADMINS@CIGARSINTERNATIONAL.COM
											2. User Variable for BSSBIETLUSE: AUTO_EMAIL_PASSWORD"
											   variable description: This value is for authenticate smpt server "smtp.office365.com"
											3. System Variables for CORP-ETLDB01: SFTP_HOST_NAME
											   variable description: Outbound file upload location
											4. System Variables for CORP-ETLDB01: SFTP_PASSWORD
											   variable description: Outbound file upload location password.
											5. System Variables for CORP-ETLDB01: SFTP_USER_NAME
											   variable description: Outbound file upload location user name.
											   
												
	
		

				  
				  
				  

