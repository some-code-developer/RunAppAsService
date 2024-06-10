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
   Settings              :TStrings;

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
   Settings.LoadFromFile(ChangeFileExt(ParamStr(0), '.ini'));
   ServiceName     := Settings.Values['ServiceName'];
   AppName := Settings.Values['AppName'];
   ServiceDescription := Settings.Values['ServiceDescription'];
  finalization
   FreeAndNil(Settings);
end.


