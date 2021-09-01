import logging, logging.handlers

def modify_log():
	logger = logging.getLogger(__name__)
	logger.setLevel(logging.INFO)
	formatter = logging.Formatter('%(asctime)s:%(levelname)s : %(name)s : %(message)s')
	file_handler = logging.FileHandler('D:/MKTCloudFeeds/log/extract_to_csv.log')
	file_handler.setFormatter(formatter)

	if (logger.hasHandlers()):
	    logger.handlers.clear()
	logger.addHandler(file_handler)
	
	return logger