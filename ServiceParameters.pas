unit ServiceParameters;

interface

Uses types,SysUtils,Classes;

function GetTitle:string;


var
   ServiceName:          String;
   AppName:              String;
   ServiceDescription:   String;
   _User:                String;
   _Password:            String;
   Settings:             TStrings;
   _IniFileName:         String;
implementation

function GetTitle:string;
 begin
  {$IFDEF WIN64}
    result:=' (64bit)';
  {$ELSE}
    result:=' (32bit)';
  {$ENDIF}
 end;

 initialization
   Settings    := TStringList.Create;
   _IniFileName:=ChangeFileExt(ParamStr(0), '.ini');
   if FileExists(_IniFileName) then
    begin
     Settings.LoadFromFile(ChangeFileExt(ParamStr(0), '.ini'));
     ServiceName     := Settings.Values['ServiceName'];
     AppName := Settings.Values['AppName'];
     ServiceDescription := Settings.Values['ServiceDescription'];

    Settings.delimiter:=' ';
    Settings.DelimitedText:=cmdline;
    _User:= Settings.Values['USER'];
    _PASSWORD:= Settings.Values['PASSWORD'];
    end;
  finalization
   FreeAndNil(Settings);
end.


