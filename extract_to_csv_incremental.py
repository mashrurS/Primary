from datetime import datetime
import traceback
from pandas.core.frame import DataFrame
from modify_configfile import modify_before_load, modify_after_load
from modify_log import modify_log
from send_mail import send_mail
import database_connection as db_conn

def extract_to_csv_incremental(max_date_log,out_location, sql_location, sql_script_name, connection_string, increment_value, increment_datatype):  

    date_stamp = datetime.now().strftime("-%Y%m%d%H%M%S")+".csv"
    csv_file_name = sql_script_name.replace(".sql",date_stamp)

    #max_date_log = "xxxx\incremental_load_config.csv"
    default_date = '1900-01-01 00:00:00 -04:00'
    
    try:
        #Read max incremental value from incremetal_load_config file for currentl load 
        max_value = modify_before_load(max_date_log,sql_script_name, increment_datatype,default_date)
        modify_log().info(max_value)

        with open(sql_location+sql_script_name ,"r" ) as file:
            original_sql_query = file.read()
            updated_sql_query = original_sql_query.replace("PLACE_HOLDER", max_value)

        data_frame = DataFrame(db_conn.read_from_database(sql_script_name= updated_sql_query, 
                                                          connection_string = connection_string, 
                                                          interval= 5, retries= 10))
        
        if (data_frame.shape[0] > 0):
            increment_max_value = (data_frame[increment_value].max())
            if sql_script_name == 'productattribute.sql':
                data_frame.drop('dateLastSynchronized', axis =1, inplace = True)
                data_frame.to_csv( out_location + csv_file_name,index=False, encoding='utf8', sep='|',quoting=1)
            else:
                data_frame.to_csv( out_location + csv_file_name,index=False, encoding='utf8', sep='|',quoting=1)
            #log new file name     
            modify_log().info(f"{out_location}{csv_file_name} created")

            #Read max value from generated data frame for next incremental load and update incremental_load_config file
            modify_after_load(max_date_log, csv_file_name = data_frame, 
                                sql_script_name= sql_script_name,
                                increment_datatype= increment_datatype, 
                                increment_max_value= increment_max_value)
            
        else:
            modify_log().info(f"{updated_sql_query} did not return any rows. No file will be created.")
        
    except Exception as e:
            modify_log().exception(e)
            send_mail(	to_address= 'xxx@xxx.com', 
				subject='ALERT: Marketing Cloud Data Feed - Execution Error' , 
    			email_message = traceback.format_exc())
