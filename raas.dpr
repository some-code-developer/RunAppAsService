program raas;

uses
  Vcl.SvcMgr,
  SysUtils,
  windows,
  ServiceTools in 'ServiceTools.pas',
  SVCMainUn in 'SVCMainUn.pas' {AgentSvc: TService},
  DMUn in 'DMUn.pas' {DM: TDataModule},
  ServiceUn in 'ServiceUn.pas',
  RegisterMessages in 'RegisterMessages.pas',
  ServiceParameters in 'ServiceParameters.pas';

{$R 'MessageFile.res'}
{$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE or IMAGE_FILE_RELOCS_STRIPPED}

begin
  if FindCmdLineSwitch('STOP') then
    begin
     if ServiceRunning('', AnsiUpperCase(ServiceName)) then
        ServiceStop('', AnsiUpperCase(ServiceName));
     exit;
    end;

  if FindCmdLineSwitch('INSTALL') then
     if ServiceExists('', AnsiUpperCase(ServiceName)) then exit;
  if FindCmdLineSwitch('UNINSTALL') then
     if ServiceExists('', AnsiUpperCase(ServiceName))=false then exit;

  if not Application.DelayInitialize or Application.Installing then
     Application.Initialize;
  Application.CreateForm(TAgentSvc, AgentSvc);
  AgentSvc.Description:=ServiceDescription;
  AgentSvc.DisplayName:=ServiceDescription+GetTitle;
  AgentSvc.Name:=LowerCase(ServiceName);
  RegisterMessageFile(AgentSvc.Name);
  Application.Run;
end.
