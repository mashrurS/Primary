from os import listdir, remove, path
from datetime import datetime
import logging, logging.handlers
from send_mail import send_mail
import zipfile,traceback

log_location= "xxxxx/log/extract_to_csv.log"
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s:%(levelname)s : %(name)s : %(message)s')
file_handler = logging.FileHandler(log_location)
file_handler.setFormatter(formatter)

logger.addHandler(file_handler)

def zip_add_to_archive(source_path, destination_path):
	destination_path = destination_path+datetime.now().strftime("%Y%m%d%H%M%S")+".zip"
	file_list = [files for files in listdir(source_path)]

	try:
		if len(file_list) > 0:
			for file in file_list:
				with zipfile.ZipFile(destination_path, mode='a',compression=zipfile.ZIP_DEFLATED) as zfile:
					zfile.write(source_path+file, arcname = file)
					#print(source_path+file)

			#logger.info(f"{source_path}\\{file} added to {destination_path} ")
			[remove(path.join(source_path, obj)) for obj in listdir(source_path)]
			logger.info(f"All file deleted from {source_path}")

	except Exception as e:
		logger.exception(e)
		send_mail(	to_address= 'mashrurs@bethss.com', 
				subject='ALERT: Marketing Cloud Data Feed - Execution Error' , 
    			email_message = traceback.format_exc())



def zip_output_files(source_path):
	
	file_list = [files for files in listdir(source_path)]

	try:
		if len(file_list) > 0:
			for file in file_list:
				with zipfile.ZipFile(source_path+file+".zip", mode='w',compression=zipfile.ZIP_DEFLATED) as zfile:
					zfile.write(source_path+file, arcname = file)
					#print(source_path+file)

			[remove(path.join(source_path, obj)) for obj in listdir(source_path) if obj.endswith(".txt")]

	except Exception as e:
		logger.exception(e)
		send_mail(	to_address= 'xxxxxx.com', 
				subject='ALERT: Marketing Cloud Data Feed - Execution Error' , 
    			email_message = traceback.format_exc())
