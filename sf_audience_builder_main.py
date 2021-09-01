from extract_to_csv_incremental import extract_to_csv_incremental
from extract_to_csv_full import extract_to_csv_full
from zip_archive_remove import zip_output_files, zip_add_to_archive
from send_mail import send_mail
from sftp_upload import sftp_upload
from modify_log import modify_log
import json, traceback

config_file = "//CORP-ETLDB01/MKTCloudFeeds/configFile/source_config_adhoc_load.json"

try:

    with open (config_file, 'r') as file:
        list_values = json.load(file)

    #Get different folder locations
    dict_values  = [list_values[i].get('folder_location_config') for i in range(len(list_values))]
    values = [ i for i in dict_values if i]

    for i in values:
        output_folder = i.get('output_folder')
        sql_query_location = i.get('sql_query_location')
        archive_folder= i.get('archive_folder')
        max_log_date=i.get('max_date_log')


    #full load
    dict_values  = [list_values[i].get('full_load_source_config') for i in range(len(list_values))]

    for i in dict_values[1]:
        extract_to_csv_full(output_folder,sql_query_location,
                            sql_script_name = i.get('script'),
                            connection_string= i.get('connectionString'))


    #incremental load
    dict_values  = [list_values[i].get('incremental_source_config') for i in range(len(list_values))]
    for i in dict_values[2]:
        extract_to_csv_incremental(max_date_log= max_log_date,
                                    out_location = output_folder, 
                                    sql_location=sql_query_location,
                                    sql_script_name = i.get('script'),
                                    connection_string= i.get('connectionString'),
                                    increment_value = i.get('incrementOn'),
                                    increment_datatype= i.get('incrementDataType'))


    #zip archive all generated files from output folder to archive folder and remove all files from output folder.
    zip_output_files(output_folder)

    #upload generated csv files
    sftp_upload("/Import/Test/",output_folder,initial_wait= 3,interval=5,retries=3)

    #Move uploaded files to archive folder
    zip_add_to_archive(output_folder, archive_folder)


except Exception as e:
    modify_log().exception(e)
    send_mail(	to_address= 'mashrurs@bethss.com', 
				subject='ALERT: Marketing Cloud Data Feed - Execution Error' , 
    			email_message = traceback.format_exc())

