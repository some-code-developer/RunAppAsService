unit SVCMainUn;

interface

uses
  Winapi.Windows, SysUtils, Vcl.SvcMgr, ServiceUn,ServiceParameters,Registry;

 type
  TAgentSvc = class(TService)
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceShutdown(Sender: TService);
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceAfterInstall(Sender: TService);
    procedure ServiceBeforeInstall(Sender: TService);
  private
    { Private declarations }
    ServiceThread : TServiceThread;
  public
    Description: String;
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  AgentSvc: TAgentSvc;

implementation

{$R *.DFM}

uses DMUn;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  AgentSvc.Controller(CtrlCode);
end;

function TAgentSvc.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TAgentSvc.ServiceAfterInstall(Sender: TService);
var
  Reg: TRegistry;
begin
  LogMessage(DisplayName+' - Installed', EVENTLOG_SUCCESS, 0, 1);
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey('\SYSTEM\CurrentControlSet\Services\' + Name, false) then
    begin
      Reg.WriteString('Description', Description);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TAgentSvc.ServiceBeforeInstall(Sender: TService);
begin
  Sender.ServiceStartName := _User;
  Sender.Password         := _Password;
  Sender.StartType        := stManual;
end;

procedure TAgentSvc.ServiceContinue(Sender: TService; var Continued: Boolean);
begin
  ServiceThread.Resume;
  Continued:=True;
  LogMessage(DisplayName+' - Resumed', EVENTLOG_SUCCESS, 0, 1);
end;

procedure TAgentSvc.ServicePause(Sender: TService; var Paused: Boolean);
begin
  ServiceThread.Suspend;
  Paused:=True;
  LogMessage(DisplayName+' - Suspended', EVENTLOG_SUCCESS, 0, 1);
end;

procedure TAgentSvc.ServiceShutdown(Sender: TService);
var
  Stopped : boolean;
begin
  // is called when windows shuts down
  ServiceStop(Self, Stopped);
end;

procedure TAgentSvc.ServiceStart(Sender: TService; var Started: Boolean);
begin
  ServiceThread := TServiceThread.Create(true);
  ServiceThread.FreeOnTerminate:=False;
  ServiceThread.Name:=Name;
  ServiceThread.DisplayName:=DisplayName;
  ServiceThread.Start;
  LogMessage(DisplayName+' - Started '+IntToStr(ServiceThread.ThreadID), EVENTLOG_SUCCESS, 0, 1);
  Started:=true;
 end;

procedure TAgentSvc.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  stopped:=false;
  if Assigned(ServiceThread) then
  begin
   ServiceThread.Terminate;
   ServiceThread.WaitFor;
   FreeAndNil(ServiceThread);
  end;
  LogMessage(DisplayName+' - Stopped', EVENTLOG_SUCCESS, 0, 1);
  stopped:=true;
end;

end.
