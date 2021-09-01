import smtplib
from datetime import datetime
from os import environ, getenv,getcwd
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import logging, logging.handlers

def send_mail(to_address, subject, email_message):

    #create logging objects
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s:%(levelname)s : %(name)s : %(message)s')
    file_handler = logging.FileHandler('D:/MKTCloudFeeds/log/extract_to_csv.log')
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    #declare local variables
    line_break_double = '\n\n'
    line_break_single = '\n'
    run_date = (datetime.now()).strftime("%Y-%m-%d %H:%M:%S")

    #declare email user name, password, email template, email body
    msg = MIMEMultipart()
    email_user_name = environ.get('AUTO_EMAIL')
    email_password = environ.get('AUTO_EMAIL_PASSWORD')
    msg['From'] = email_user_name
    msg['To'] = to_address
    msg['Subject'] = subject
    email_template = f" {run_date}\
                {line_break_double}There was an error during the execution of the Marketing Cloud Data Feeds. Please check the error log.\
                {line_break_double}Server: {getenv('COMPUTERNAME', 'defaultValue')}\
                {line_break_double}App Execution Path: {getcwd()}\
                {line_break_double}Log Path(s): \\CORP-ETLDB01\MKTCloudFeeds\log\extract_to_csv.log\
                {line_break_double}Raised Errors: "


    msg.attach(MIMEText(email_template+line_break_single+email_message, 'Plain'))

    #send email via smtp
    try:
        with smtplib.SMTP('smtp.office365.com', 587) as server:
            server.ehlo()
            server.starttls()
            server.login(email_user_name, email_password)
            server.sendmail(email_user_name, to_address, msg.as_string())
        
        logger.info(f"email sent to {to_address}")
        

    except Exception as e:
        logger.exception(e)
