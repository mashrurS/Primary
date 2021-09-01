from json import load
from datetime import datetime
import logging, logging.handlers, traceback
from pandas.core.frame import DataFrame
from send_mail import send_mail
import database_connection as db_conn

def extract_to_csv_full(out_location, sql_location, sql_script_name, connection_string):  
    
    config_file = "xxxxx/configFile/source_config.json"
    
    with open (config_file, 'r') as file:
	    list_values = load(file)
    
    dict_values  = [list_values[i].get('folder_location_config') for i in range(len(list_values))]
    values = [ i for i in dict_values if i]

    log_location = [i.get('log_location') for i in values]

    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s:%(levelname)s : %(name)s : %(message)s')
    file_handler = logging.FileHandler(log_location[0])
    file_handler.setFormatter(formatter)

    if (logger.hasHandlers()):
        logger.handlers.clear()
    logger.addHandler(file_handler)
 
    date_stamp = datetime.now().strftime("-%Y%m%d%H%M%S")+".csv"
    csv_file_name = sql_script_name.replace(".sql",date_stamp)

    try:
        with open(sql_location+sql_script_name ,"r" ) as file:
             sql_query_text = file.read()

        data_frame = DataFrame(db_conn.read_from_database(sql_script_name= sql_query_text, 
                                        connection_string = connection_string, 
                                        interval= 1, retries= 1))
        
        data_frame.to_csv( out_location + csv_file_name,index=False, encoding='utf8', sep='|',quoting=1)

        now = datetime.utcnow()    
        logger.info(f"{out_location}{csv_file_name} created at {now.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]}")

        
    except Exception as e:
        logger.exception(e)
        send_mail(	to_address= 'xxxx@xxxx.com', 
				subject='ALERT: Marketing Cloud Data Feed - Execution Error' , 
    			email_message = traceback.format_exc())

        
