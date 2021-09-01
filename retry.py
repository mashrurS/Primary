from send_mail import send_mail
import logging, logging.handlers
import traceback

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s:%(levelname)s : %(name)s : %(message)s')
file_handler = logging.FileHandler('//CORP-ETLDB01/MKTCloudFeeds/log/extract_to_csv.log')
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)

try:
	10/0
except Exception as e:
	logger.exception(e)
	
	send_mail(	to_address= 'sqladmins@cigarsinternational.com', 
				subject='ALERT: Marketing Cloud Data Feed - Execution Error' , 
    			email_message = traceback.format_exc())
