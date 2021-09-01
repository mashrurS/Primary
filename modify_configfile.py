from pandas import DataFrame, read_csv, isnull
from os import path
from modify_log import modify_log
import traceback, send_mail


def modify_before_load(max_date_log,sql_script_name, increment_datatype,default_date):

	
	try:
		if path.exists(max_date_log) == True :
			data_frame = read_csv(max_date_log, delimiter='|', quoting=1)
			max_value = data_frame.query('fileName == @sql_script_name')['maxValueInLastLoad'].max()

			if (isnull(max_value) == True):
				if (increment_datatype == 'DATETIME'):
					new_max_value = default_date
					modify_log().info(f"New max value {new_max_value} for incremental load for {sql_script_name} ")
				else:
					new_max_value = '0'
					modify_log().info(f"New max value {new_max_value} for incremental load for {sql_script_name} ")
			else:
				new_max_value = max_value
				modify_log().info(f"New max value {new_max_value} for incremental load for {sql_script_name} ")
		else:
			new_max_value = {True:'0', False:default_date}[increment_datatype=='INT']
			data_frame = DataFrame({'fileName':[sql_script_name],'maxValueInLastLoad':new_max_value, 'dataType':[increment_datatype]})
			data_frame.to_csv(max_date_log, sep = '|', index=False, quoting=1, mode= 'w', header=True)
			modify_log().info(f"new file creted with new entry for {sql_script_name}")

		return new_max_value
	
	except Exception as e:
		modify_log().exception(e)
		send_mail(	to_address= 'mashrurs@bethss.com', 
				subject='ALERT: Marketing Cloud Data Feed - Execution Error' , 
    			email_message = traceback.format_exc())


def modify_after_load(max_date_log,csv_file_name,sql_script_name, increment_datatype, increment_max_value):
	try:
		data_frame = csv_file_name
		df_configure_file= read_csv(max_date_log, delimiter = '|') #Read incremental_load_config file
		line_count = len(data_frame)

		if line_count > 0:
			max_value = increment_max_value

			if ((df_configure_file['fileName'] == sql_script_name).max()) == True: #if sql_script_name is present in config file then swap old max value with new max value
				index = df_configure_file.index
				df_configure_file.at[(index[df_configure_file["fileName"] == sql_script_name].tolist()),'maxValueInLastLoad'] = max_value
				df_configure_file.to_csv(max_date_log, sep = '|', index=False, quoting=1, mode= 'w', header=True)
			else: #if sql_script_name is not present in config file add new entry
			 	new_line= {'fileName':sql_script_name,'maxValueInLastLoad':max_value,'dataType':increment_datatype}
			 	new_df = df_configure_file.append(new_line, ignore_index = True, sort = False)
			 	new_df.to_csv(max_date_log, sep = '|', index=False, quoting=1, mode= 'w', header=True)
				

	except Exception as e:
			modify_log().exception(e)
			send_mail(	to_address= 'xxx@xxx.com', 
				subject='ALERT: xxx Cloud Data Feed - Execution Error' , 
    			email_message = traceback.format_exc())
