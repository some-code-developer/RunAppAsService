unit DMUn;

interface

uses
  Winapi.Windows, SysUtils, Vcl.SvcMgr,Classes,variants,ServiceParameters;

type
  TDM = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }
   Fpi: TProcessInformation;
   Fsi: TStartupInfo;
   FExecutableFile,FExecutableDir: string;
   FCreateOk: boolean;
   public
    { Public declarations }
   procedure  StartNode;
   procedure  StopNode;
  end;

var
  DM: TDM;

implementation

{$R *.dfm}
{ TAgentDM }

procedure TDM.DataModuleCreate(Sender: TObject);
begin
 StartNode;
end;

procedure TDM.DataModuleDestroy(Sender: TObject);
begin
 StopNode;
end;

procedure TDM.StartNode;
begin
  FCreateOk:=false;
  fExecutableFile:=ExtractFileDir(ParamStr(0))+'\'+AppName;
  if not FileExists(fExecutableFile) then raise Exception.Create(fExecutableFile+' - Not found');
  FExecutableDir:=ExtractFileDir(ParamStr(0));
  FillMemory( @fsi, sizeof( fsi ), 0 );
  fsi.cb := sizeof( fsi );
  FCreateOk:=CreateProcess(Nil, PChar( fExecutableFile ),
                          Nil, Nil, False, CREATE_NO_WINDOW,
                          Nil, Pchar(FExecutableDir), fsi, fpi);
end;

procedure TDM.StopNode;
begin
 if FCreateOk then
   begin
    TerminateProcess(Fpi.hProcess, 0);
    CloseHandle(Fpi.hProcess);
    CloseHandle(Fpi.hThread);
   end;
end;

end.
