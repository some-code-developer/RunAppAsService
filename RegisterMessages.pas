unit RegisterMessages;

interface

Uses SysUtils, Windows, Classes,Registry;

type

  ELogException = class(Exception);

const
  SEventLogKey = '\SYSTEM\CurrentControlSet\Services\Eventlog\Application\';
  StrNoRegistryConnection = 'Could not connect to registry on server %s';
  SDefaultSource = 'RAAS';

function RegisterMessageFile(
  ASource: string =SDefaultSource;
  AServer: string = '';
  AEventId: word = 0;
  AMessageFile: string = ''): boolean;

implementation

function RegisterMessageFile(
  ASource: string =SDefaultSource;
  AServer: string = '';
  AEventId: word = 0;
  AMessageFile: string = ''): boolean;

var
  Reg: TRegistry;
  Key: string;

begin
  Result := False;

  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Length(AServer) > 0 then
      if not Reg.RegistryConnect(AServer) then
        raise ELogException.CreateFmt(StrNoRegistryConnection, [AServer]);
    Key := SEventLogKey + ASource;
    if Reg.OpenKey(Key, True) then
    begin
      if Length(AMessageFile) = 0 then
        AMessageFile := ParamStr(0); // Default to current application
      Reg.WriteString('EventMessageFile', AMessageFile); // do not translate
      Reg.WriteInteger('TypesSupported', 7); // do not translate
      Reg.CloseKey;
      Result := True;
    end;
  finally
    Reg.Free;
  end;
end;


end.
