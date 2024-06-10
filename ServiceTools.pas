unit ServiceTools;

{$WARN SYMBOL_PLATFORM OFF}
{$R+}

interface

uses
  Windows,WinSvc;

type
  TServiceStartType =
   (sstBoot,      // SERVICE_BOOT_START
    sstSystem,    // SERVICE_SYSTEM_START
    sstAuto,      // SERVICE_AUTO_START
    sstDemand,    // SERVICE_DEMAND_START
    sstDisabled); // SERVICE_DISABLED

function ServiceExists( sMachine,  sService : string): boolean;
function ServiceStart( sMachine,  sService : string): boolean;
function ServiceStop(sMachine, sService : string): boolean;
function ServiceRunning(sMachine, sService : string): boolean;
function ServiceUpdateAccount(sMachine, sService,UserName,Password : string; StartType: TServiceStartType): boolean;
function GetServiceStartType(sMachine, sService: string): TServiceStartType;
function SetServiceStartType(sMachine, sService: string; StartType: TServiceStartType): boolean;
function GetServiceUser(sMachine, sService: string): String;

implementation

 //
// start service
//
// return TRUE if successful
//
// sMachine:
//   machine name, ie: \SERVER
//   empty = local machine
//
// sService
//   service name, ie: Alerter
//
function ServiceStart(
  sMachine,
  sService : string ) : boolean;
var
  //
  // service control
  // manager handle
  schm,
  //
  // service handle
  schs   : SC_Handle;
  //
  // service status
  ss     : TServiceStatus;
  //
  // temp char pointer
  psTemp : PChar;
  //
  // check point
  dwChkP : DWord;
begin

  ss.dwCurrentState := 0;

  // connect to the service
  // control manager
  schm := OpenSCManager(
    PChar(sMachine),
    Nil,
    SC_MANAGER_CONNECT);

  // if successful...
  if(schm > 0)then
  begin
    // open a handle to
    // the specified service
    schs := OpenService(
      schm,
      PChar(sService),
      // we want to
      // start the service and
      SERVICE_START or
      // query service status
      SERVICE_QUERY_STATUS);

    // if successful...
    if(schs > 0)then
    begin
      psTemp := Nil;
      if(StartService(
           schs,
           0,
           psTemp))then
      begin
        // check status
        if(QueryServiceStatus(
             schs,
             ss))then
        begin
          while(SERVICE_RUNNING
            <> ss.dwCurrentState)do
          begin
            //
            // dwCheckPoint contains a
            // value that the service
            // increments periodically
            // to report its progress
            // during a lengthy
            // operation.
            //
            // save current value
            //
            dwChkP := ss.dwCheckPoint;

            //
            // wait a bit before
            // checking status again
            //
            // dwWaitHint is the
            // estimated amount of time
            // the calling program
            // should wait before calling
            // QueryServiceStatus() again
            //
            // idle events should be
            // handled here...
            //
            Sleep(ss.dwWaitHint);

            if(not QueryServiceStatus(
                 schs,
                 ss))then
            begin
              // couldn't check status
              // break from the loop
              break;
            end;

            if(ss.dwCheckPoint <
              dwChkP)then
            begin
              // QueryServiceStatus
              // didn't increment
              // dwCheckPoint as it
              // should have.
              // avoid an infinite
              // loop by breaking
              break;
            end;
          end;
        end;
      end;

      // close service handle
      CloseServiceHandle(schs);
    end;

    // close service control
    // manager handle
    CloseServiceHandle(schm);
  end;

  // return TRUE if
  // the service status is running
  Result :=
    SERVICE_RUNNING =
      ss.dwCurrentState;
end;

function ServiceStop(
  sMachine,
  sService : string ) : boolean;
var
  //
  // service control
  // manager handle
  schm,
  //
  // service handle
  schs   : SC_Handle;
  //
  // service status
  ss     : TServiceStatus;
  //
  // check point
  dwChkP : DWord;
begin
  // connect to the service
  // control manager
  schm := OpenSCManager(
    PChar(sMachine),
    Nil,
    SC_MANAGER_CONNECT);

  // if successful...
  if(schm > 0)then
  begin
    // open a handle to
    // the specified service
    schs := OpenService(
      schm,
      PChar(sService),
      // we want to
      // stop the service and
      SERVICE_STOP or
      // query service status
      SERVICE_QUERY_STATUS);

    // if successful...
    if(schs > 0)then
    begin
      if(ControlService(
           schs,
           SERVICE_CONTROL_STOP,
           ss))then
      begin
        // check status
        if(QueryServiceStatus(
             schs,
             ss))then
        begin
          while(SERVICE_STOPPED
            <> ss.dwCurrentState)do
          begin
            //
            // dwCheckPoint contains a
            // value that the service
            // increments periodically
            // to report its progress
            // during a lengthy
            // operation.
            //
            // save current value
            //
            dwChkP := ss.dwCheckPoint;

            //
            // wait a bit before
            // checking status again
            //
            // dwWaitHint is the
            // estimated amount of time
            // the calling program
            // should wait before calling
            // QueryServiceStatus() again
            //
            // idle events should be
            // handled here...
            //
            Sleep(ss.dwWaitHint);

            if(not QueryServiceStatus(
                 schs,
                 ss))then
            begin
              // couldn't check status
              // break from the loop
              break;
            end;

            if(ss.dwCheckPoint <
              dwChkP)then
            begin
              // QueryServiceStatus
              // didn't increment
              // dwCheckPoint as it
              // should have.
              // avoid an infinite
              // loop by breaking
              break;
            end;
          end;
        end;
      end;

      // close service handle
      CloseServiceHandle(schs);
    end;

    // close service control
    // manager handle
    CloseServiceHandle(schm);
  end;

  // return TRUE if
  // the service status is stopped
  Result :=
    SERVICE_STOPPED =
      ss.dwCurrentState;
end;

 function ServiceRunning(sMachine, sService : string): boolean;
var
  SCManHandle, SvcHandle: SC_Handle;
  SS: TServiceStatus;
  dwStat: DWORD;
begin
  dwStat := 0;
  // Open service manager handle.
  SCManHandle := OpenSCManager(PChar(sMachine), nil, SC_MANAGER_CONNECT);
  if (SCManHandle > 0) then
  begin
    SvcHandle := OpenService(SCManHandle, PChar(sService), SERVICE_QUERY_STATUS);
    // if Service installed
    if (SvcHandle > 0) then
    begin
      // SS structure holds the service status (TServiceStatus);
      if (QueryServiceStatus(SvcHandle, SS)) then
        dwStat := ss.dwCurrentState;
      CloseServiceHandle(SvcHandle);
    end;
    CloseServiceHandle(SCManHandle);
  end;
  Result := dwStat = SERVICE_RUNNING
end;

function ServiceExists( sMachine,  sService : string): boolean;
var
  SCManHandle, SvcHandle: SC_Handle;
begin
  Result:=False;
  // Open service manager handle.
  SCManHandle := OpenSCManager(PChar(sMachine), nil, SC_MANAGER_CONNECT);
  if (SCManHandle > 0) then
  begin
    SvcHandle := OpenService(SCManHandle, PChar(sService), SERVICE_QUERY_STATUS);
    // if Service installed
    Result:= (SvcHandle > 0);
    CloseServiceHandle(SCManHandle);
  end;
end;


function ServiceUpdateAccount(sMachine, sService,UserName,Password : string; StartType: TServiceStartType): boolean;
var
  Ret: BOOL;
  SvcMgr, Svc: SC_HANDLE;
  BytesNeeded: DWORD;
  PQrySvcCnfg: LPQUERY_SERVICE_CONFIG;
begin
 Result := False;
 SvcMgr := OpenSCManager(PChar(sMachine), nil, SC_MANAGER_ALL_ACCESS);
 if SvcMgr <> 0 then
  begin
   Svc := OpenService(SvcMgr, PChar(sService), STANDARD_RIGHTS_REQUIRED or SERVICE_CHANGE_CONFIG or SERVICE_QUERY_STATUS or SERVICE_QUERY_CONFIG);
   if Svc <> 0 then
    begin
      PQrySvcCnfg := nil;
      BytesNeeded := 4096;
      repeat
        ReallocMem(PQrySvcCnfg, BytesNeeded);
        Ret := QueryServiceConfig(Svc, PQrySvcCnfg, BytesNeeded, BytesNeeded);
      until Ret or (GetLastError <> ERROR_INSUFFICIENT_BUFFER);

      PQrySvcCnfg^.lpServiceStartName:=PChar(UserName);
      PQrySvcCnfg^.dwStartType:=Ord(StartType);

      Result := ChangeServiceConfig(Svc,
        PQrySvcCnfg^.dwServiceType,
        PQrySvcCnfg^.dwStartType,
        PQrySvcCnfg^.dwErrorControl,
        nil, {PQrySvcCnfg^.lpBinaryPathName,}
        nil, {PQrySvcCnfg^.lpLoadOrderGroup,}
        nil, {PQrySvcCnfg^.dwTagId,}
        nil, {PQrySvcCnfg^.lpDependencies,}
        PQrySvcCnfg^.lpServiceStartName,
        PChar(Password), {password-write only-not readable}
        nil {PQrySvcCnfg^.lpDisplayName} );

     CloseServiceHandle(Svc);
    end;
  CloseServiceHandle(SvcMgr);
 end;
end;

function GetServiceStartType(sMachine, sService: string): TServiceStartType;
var
  Ret: BOOL;
  SvcMgr, Svc: SC_HANDLE;
  BytesNeeded: DWORD;
  PQrySvcCnfg: LPQUERY_SERVICE_CONFIG;
begin
 SvcMgr := OpenSCManager(PChar(sMachine), nil, SC_MANAGER_ALL_ACCESS);
 if SvcMgr <> 0 then
  begin
   Svc := OpenService(SvcMgr, PChar(sService), STANDARD_RIGHTS_REQUIRED or SERVICE_CHANGE_CONFIG or SERVICE_QUERY_STATUS or SERVICE_QUERY_CONFIG);
   if Svc <> 0 then
    begin
      PQrySvcCnfg := nil;
      BytesNeeded := 4096;
      repeat
        ReallocMem(PQrySvcCnfg, BytesNeeded);
        Ret := QueryServiceConfig(Svc, PQrySvcCnfg, BytesNeeded, BytesNeeded);
      until Ret or (GetLastError <> ERROR_INSUFFICIENT_BUFFER);

      Result := TServiceStartType(PQrySvcCnfg^.dwStartType);

     CloseServiceHandle(Svc);
    end;
  CloseServiceHandle(SvcMgr);
 end;
end;


function GetServiceUser(sMachine, sService: string): String;
var
  Ret: BOOL;
  SvcMgr, Svc: SC_HANDLE;
  BytesNeeded: DWORD;
  PQrySvcCnfg: LPQUERY_SERVICE_CONFIG;
begin
 SvcMgr := OpenSCManager(PChar(sMachine), nil, SC_MANAGER_ALL_ACCESS);
 if SvcMgr <> 0 then
  begin
   Svc := OpenService(SvcMgr, PChar(sService), STANDARD_RIGHTS_REQUIRED or SERVICE_CHANGE_CONFIG or SERVICE_QUERY_STATUS or SERVICE_QUERY_CONFIG);
   if Svc <> 0 then
    begin
     PQrySvcCnfg := nil;
     BytesNeeded := 4096;
     repeat
      ReallocMem(PQrySvcCnfg, BytesNeeded);
      Ret := QueryServiceConfig(Svc, PQrySvcCnfg, BytesNeeded, BytesNeeded);
     until Ret or (GetLastError <> ERROR_INSUFFICIENT_BUFFER);
     Result := PQrySvcCnfg^.lpServiceStartName;
     CloseServiceHandle(Svc);
    end;
  CloseServiceHandle(SvcMgr);
 end;
end;

function SetServiceStartType(sMachine, sService: string; StartType: TServiceStartType):Boolean;
var
  Ret: BOOL;
  SvcMgr, Svc: SC_HANDLE;
  BytesNeeded: DWORD;
  PQrySvcCnfg: LPQUERY_SERVICE_CONFIG;
begin
 Result := False;
 SvcMgr := OpenSCManager(PChar(sMachine), nil, SC_MANAGER_ALL_ACCESS);
 if SvcMgr <> 0 then
  begin
   Svc := OpenService(SvcMgr, PChar(sService), STANDARD_RIGHTS_REQUIRED or SERVICE_CHANGE_CONFIG or SERVICE_QUERY_STATUS or SERVICE_QUERY_CONFIG);
   if Svc <> 0 then
    begin
      PQrySvcCnfg := nil;
      BytesNeeded := 4096;
      repeat
        ReallocMem(PQrySvcCnfg, BytesNeeded);
        Ret := QueryServiceConfig(Svc, PQrySvcCnfg, BytesNeeded, BytesNeeded);
      until Ret or (GetLastError <> ERROR_INSUFFICIENT_BUFFER);

      PQrySvcCnfg^.dwStartType:=Ord(StartType);

      Result := ChangeServiceConfig(Svc,
        PQrySvcCnfg^.dwServiceType,
        PQrySvcCnfg^.dwStartType,
        PQrySvcCnfg^.dwErrorControl,
        nil, {PQrySvcCnfg^.lpBinaryPathName,}
        nil, {PQrySvcCnfg^.lpLoadOrderGroup,}
        nil, {PQrySvcCnfg^.dwTagId,}
        nil, {PQrySvcCnfg^.lpDependencies,}
        nil, {PQrySvcCnfg^.lpServiceStartName,}
        nil, {password-write only-not readable}
        nil {PQrySvcCnfg^.lpDisplayName} );

     CloseServiceHandle(Svc);
    end;
  CloseServiceHandle(SvcMgr);
 end;
end;


end.
