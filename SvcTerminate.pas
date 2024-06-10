unit SvcTerminate;

interface

uses
  Windows, WinSvc;

const
  SC_STATUS_PROCESS_INFO        =  0;

type
  _SERVICE_STATUS_PROCESS       =  packed record
     dwServiceType:             DWORD;
     dwCurrentState:            DWORD;
     dwControlsAccepted:        DWORD;
     dwWin32ExitCode:           DWORD;
     dwServiceSpecificExitCode: DWORD;
     dwCheckPoint:              DWORD;
     dwWaitHint:                DWORD;
     dwProcessId:               DWORD;
     dwServiceFlags:            DWORD;
  end;
  SERVICE_STATUS_PROCESS        =  _SERVICE_STATUS_PROCESS;
  TServiceStatusProcess         =  SERVICE_STATUS_PROCESS;
  LPSERVICE_STATUS_PROCESS      =  ^SERVICE_STATUS_PROCESS;
  PServiceStatusProcess         =  ^TServiceStatusProcess;

function   QueryServiceStatusEx(hService: SC_HANDLE; InfoLevel: Integer; lpBuffer: Pointer; cbBufSize: DWORD; pcbBytesNeeded: PDWORD): BOOL; stdcall; external 'advapi32';

procedure  ModifySecurity(Enable: Boolean);
function   ServiceGetProcessID(MachineName, ServiceName: String): DWORD;
function   KillProcessByPID(ProcessID: DWORD): Boolean;

implementation

function KillProcessByPID(ProcessID: DWORD): Boolean;
var  hProc:         THandle;
begin

  // Set default result
  result:=False;

  // Enable permissions
  ModifySecurity(True);

  // Resource protection
  try
     // Open process
     hProc:=OpenProcess(PROCESS_ALL_ACCESS, False, ProcessID);
     // Check handle
     if not(hProc = 0) then
     begin
        // Resource protection
        try
           // Terminate
           result:=TerminateProcess(hProc, 0);
        finally
           // Close process handle
           CloseHandle(hProc);
        end;
     end;
  finally
     // Disable the permissions
     ModifySecurity(False);
  end;

end;

function ServiceGetProcessID(MachineName, ServiceName: String): DWORD;
var  lpStatus:      TServiceStatusProcess;
     hSCM:          SC_HANDLE;
     hSC:           SC_HANDLE;
     dwNeeded:      DWORD;
begin

  // Default result
  result:=0;

  // Connect to the service control manager
  hSCM:=OpenSCManager(PChar(MachineName), nil, SC_MANAGER_CONNECT);

  // Check handle
  if not(hSCM = 0) then
  begin
     // Resource protection
     try
        // Open service
        hSC:=OpenService(hSCM, PChar(ServiceName), SERVICE_QUERY_STATUS);
        // Check handle
        if not(hSC = 0) then
        begin
           // Resource protection
           try
              // Query service
              if QueryServiceStatusEx(hSC, SC_STATUS_PROCESS_INFO, @lpStatus, SizeOf(TServiceStatusProcess), @dwNeeded) then
              begin
                 // Update the result
                 result:=lpStatus.dwProcessId;
              end;
           finally
              // Close handle
              CloseServiceHandle(hSC);
           end;
        end;
     finally
        // Close handle
        CloseServiceHandle(hSCM);
     end;
  end;

end;

procedure ModifySecurity(Enable: Boolean);
var  hToken:        THandle;
     lpszSecName:   Array [0..2] of PChar;
     tp:            TOKEN_PRIVILEGES;
     tpPrevious:    TOKEN_PRIVILEGES;
     luid:          TLargeInteger;
     cbUnused:      DWORD;
     cbPrevious:    DWORD;
     dwCount:       Integer;
begin

  // Set security names
  lpszSecName[0]:='SeSecurityPrivilege';
  lpszSecName[1]:='SeTcbPrivilege';
  lpszSecName[2]:='SeDebugPrivilege';

      // Enable our process to super-level rights
  if OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken) then
  begin
     // Iterate the security names to elevate
     for dwCount:=Low(lpszSecName) to High(lpszSecName) do
     begin
        cbPrevious:=SizeOf(TOKEN_PRIVILEGES);
        if LookupPrivilegeValue(nil, lpszSecName[dwCount], luid) then
        begin
           tp.PrivilegeCount:=1;
           tp.Privileges[0].Luid:=luid;
           tp.Privileges[0].Attributes:=0;
           if AdjustTokenPrivileges(hToken, False, tp, SizeOf(TOKEN_PRIVILEGES), @tpPrevious, cbPrevious) then
           begin
              tpPrevious.PrivilegeCount:=1;
              tpPrevious.Privileges[0].Luid:=luid;
              if Enable then
                 tpPrevious.Privileges[0].Attributes:=SE_PRIVILEGE_ENABLED
              else
                     tpPrevious.Privileges[0].Attributes:=0;
              if not(AdjustTokenPrivileges(hToken, False, tpPrevious, cbPrevious, nil, cbUnused)) then break;
           end;
        end;
     end;
  end;

end;

end.
