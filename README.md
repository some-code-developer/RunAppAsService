# Run Application As Service

## About

Minimalistic windows serivice mananager. Originally was created to run NodeJS applications as windows service. Can be used as part InnoSetup script to istall the service 

## Usage

1 Copy raas.exe into separate folder
2 Create raas.ini file in the same folder
3 Edit raas.ini and set parameters 
4 Run raas.exe /INSTALL to install the serivice

## raas.ini parameters

AppName=some.exe
ServiceName=ImportantService
ServiceDescription=Very Important Service

**Note:** if AppName is missing service will start and write an error into windows event log

## Command line switches

- INSTALL - Create windows service
- UNINSTALL - Delete windows service
- STOP - Stop windows service
- SILENT - Supresses instalaltion messages

## Using with InnoSetup

[Run]
Filename: "{app}\rass.exe"; Parameters: "/INSTALL /SILENT ; Flags: shellexec hidewizard runminimized waituntilterminated runascurrentuser dontlogparameters; 

[UninstallRun]
Filename: "{app}\rass.exe"; Parameters: "/STOP"; Flags: skipifdoesntexist runhidden shellexec waituntilterminated; 
Filename: "{app}\rass.exe"; Parameters: "/UNINSTALL /SILENT"; Flags: skipifdoesntexist runhidden shellexec waituntilterminated; 

## License 

MIT