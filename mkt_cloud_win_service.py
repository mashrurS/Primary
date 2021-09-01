import servicemanager
import socket
import sys
import win32event
import win32service
import win32serviceutil
from sf_audience_builder_main import mkt_cloud_feed_main


class ETLService(win32serviceutil.ServiceFramework):
    _svc_name_ = "mkt-sf-cloud-etl-service"
    _svc_display_name_ = "mkt-sf-cloud-etl-service"
    _svc_description_ = "Data feed to sales force marketing cloud"

    def __init__(self, args):
        win32serviceutil.ServiceFramework.__init__(self, args)
        self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
        socket.setdefaulttimeout(60)

    def SvcStop(self):
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        win32event.SetEvent(self.hWaitStop)

    def SvcDoRun(self):
        rc = None
        while rc != win32event.WAIT_OBJECT_0:
            mkt_cloud_feed_main()
            rc = win32event.WaitForSingleObject(self.hWaitStop, 120000)


if __name__ == '__main__':
    if len(sys.argv) == 1:
        servicemanager.Initialize()
        servicemanager.PrepareToHostSingle(ETLService)
        servicemanager.StartServiceCtrlDispatcher()
    else:
        win32serviceutil.HandleCommandLine(ETLService)