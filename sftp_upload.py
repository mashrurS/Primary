import paramiko,logging,traceback
from send_mail import send_mail
from os import listdir, environ
from time import sleep

log_location= 'D:/MKTCloudFeeds/log/sftp.log'
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s:%(levelname)s : %(name)s : %(message)s')
file_handler = logging.FileHandler(log_location)
file_handler.setFormatter(formatter)

logger.addHandler(file_handler)

def sftp_upload(remote_path, local_path, initial_wait, interval, retries):

       
    #log_to_file(filename="C:\\Test\\Python\\log\\sftp_download.log", level=logging.DEBUG)
    sftp_host_name = environ.get('SFTP_HOST_NAME')
    sftp_user_name = environ.get('SFTP_USER_NAME')
    sftp_password = environ.get('SFTP_PASSWORD')
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    sleep(initial_wait)
    
    for t in range(retries): 
        try:
            local_files = listdir(local_path)
            if len(local_files) > 0:
                client.connect(hostname = sftp_host_name, username = sftp_user_name, password = sftp_password, allow_agent=False, look_for_keys=False)
                with client.open_sftp() as sftp:
                    [sftp.put(local_path+file,remote_path+file) for file in local_files]
                    logger.info(f"{local_files} uploaded to {sftp_host_name}{remote_path}")
                return True
            else:
                logger.info(f"No file to upload")
                return True

        except Exception as e:
            logger.exception(e)
            sleep(interval)
            send_mail(	to_address= 'mashrurs@bethss.com', 
                    subject='ALERT: Marketing Cloud Data Feed - Execution Error' , 
                    email_message = traceback.format_exc())
    return False