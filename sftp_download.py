import paramiko
import logging, traceback
from send_mail import send_mail


log_location= '\\CORP-ETLDB01\MKTCloudFeeds\log\sftp.log'
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s:%(levelname)s : %(name)s : %(message)s')
file_handler = logging.FileHandler(log_location)
file_handler.setFormatter(formatter)

logger.addHandler(file_handler)

def sftp_download(remote_path, local_path):

       
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    
    try:
        client.connect(hostname='ftp.bethss.com', username='sqltest', password='test12345', allow_agent=False, look_for_keys=False)
        sftp = client.open_sftp()
        remote_files = sftp.listdir(remote_path)
        [sftp.get(remote_path+file,local_path+file) for file in remote_files]
        
        logger.info(f"{remote_files} downloaded")

    except Exception as e:
        logger.exception(e)
        send_mail(	to_address= 'mashrurs@bethss.com', 
				subject='ALERT: Marketing Cloud Data Feed - Execution Error' , 
    			email_message = traceback.format_exc())
    
    finally:
        sftp.close()
        client.close()