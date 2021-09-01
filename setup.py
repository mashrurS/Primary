from extract_to_csv_incremental import extract_to_csv_incremental
import sys
from cx_Freeze import setup, Executable

# Dependencies are automatically detected, but it might need fine tuning.
# "packages": ["os"] is used as example only
#build_exe_options = {"packages": ["os"], "excludes": ["tkinter"], "includes":["extract_to_csv_incremental"]}

#includefiles = ['C:/Test/Python\configFile', 'CHANGELOG.txt', 'helpers\uncompress\unRAR.exe', , 'helpers\uncompress\unzip.exe']
includes = []
excludes = ['Tkinter']
packages = ['extract_to_csv_full','extract_to_csv_incremental', 'modify_log', 'send_mail', 'sftp_upload','zip_archive_remove', 'database_connection']

# base="Win32GUI" should be used only for Windows GUI app
base = None
if sys.platform == "win32":
    base = "Win32GUI"

setup(
    name = "mkt-sf-cloud-etl-service",
    version = "0.1",
    description = "Data feed to salesforce marketing cloud",
    options = {"build_exe": {'includes':includes,'excludes':excludes,'packages':packages}},
    executables = [Executable("mkt_cloud_win_service.py", base=base)]
)
