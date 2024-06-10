unit ServiceUn;

interface

uses
  Windows, Messages, SysUtils, Classes, DMUn,Vcl.SvcMgr,
  SyncObjs,ComObj,ActiveX;
type
  TServiceThread = class(TThread)
  private
    { Private declarations }
  FEventLogger : TEventLogger;
  FName: String;
  FDisplayName: String;
  procedure LogMessage(Message: String; EventType: DWord; Category, ID: Integer);
  protected
   procedure Execute; override;
  public
   property Name        :String read FName        write FName;
   property DisplayName :String read FDisplayName write FDisplayName;
  end;

implementation

{ TServiceThread }

procedure TServiceThread.LogMessage(Message: String; EventType: DWord; Category, ID: Integer);
begin
  if FEventLogger = nil then
    FEventLogger := TEventLogger.Create(Name);
  FEventLogger.LogMessage(Message, EventType, Category, ID);
end;

procedure TServiceThread.Execute;
const
  SecBetweenRuns = 10;
var
  Count: Integer;
begin
  { Place thread code here }
  FEventLogger := nil;
   ///initialising
  OleInitialize(nil);
 try

  DM := TDM.Create(nil);
  Count     := 0;
  // attempting to connect to the repository

  while not Terminated do  // loop around until we should stop
   try
    Inc(Count);
    if Count >= SecBetweenRuns then
     begin
      Count := 0;
     end;
    Sleep(500);
   except // execution error handler
    on e: exception do
      begin
       LogMessage(DisplayName+ ' - ' +e.Message, EVENTLOG_ERROR_TYPE, 0, 1);
      end;
   end;

 FreeAndNil(DM);
 OleUninitialize;

 except // Global error handler
  on e: exception do
   begin
    LogMessage(DisplayName+ ' - ' +e.Message, EVENTLOG_ERROR_TYPE, 0, 1);
   end;
 end;
end;

end.
