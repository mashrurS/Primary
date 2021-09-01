from pyodbc import connect
from pandas.core.frame import DataFrame
from pandas.io.sql import read_sql_query
from time import sleep
import logging, logging.handlers
import traceback, send_mail

def read_from_database(sql_script_name, connection_string, interval, retries):  
    """Connect to source SQL Server database to read datab"""
    log_location= '//CORP-ETLDB01/MKTCloudFeeds/log/extract_to_csv.log'
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s:%(levelname)s : %(name)s : %(message)s')
    file_handler = logging.FileHandler(log_location)
    file_handler.setFormatter(formatter)

    if (logger.hasHandlers()):
        logger.handlers.clear()
    logger.addHandler(file_handler)
    success = False

    while not success:
        for t in range(retries) :
            try:
                db_connection = connect(connection_string)
                sql_query_text = sql_script_name
                sql_query = read_sql_query(sql_query_text, db_connection)
                df= DataFrame(sql_query)
                logger.info( f"connection success {t} time")

                return df

            except Exception as e:
                if t <= (retries -2):
                    logger.exception( f"retrying for {t} time with {e}")
                elif t == (retries-1):
                    send_mail.send_mail(to_address= 'mashrurs@bethss.com', 
                            subject='ALERT: Marketing Cloud Data Feed - Execution Error. DB connection error.' , 
                            email_message = f"All {t} retry has been faild to connect to source database. {traceback.format_exc()}")
                sleep(interval)
        return False


# data=  database_connection(sql_location='C:/Test/Python/sqlQuery/', 
#                                 sql_script_name='product.sql', 
#                                 connection_string='driver={SQL SERVER}; server=EUSVMSQL01;database=BSSData;trusted_connection = YES;',
#                                 interval=2,retries=3)
# print(data)
        

        