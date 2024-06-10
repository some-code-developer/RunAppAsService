object AgentSvc: TAgentSvc
  OldCreateOrder = False
  DisplayName = 'Service'
  BeforeInstall = ServiceBeforeInstall
  AfterInstall = ServiceAfterInstall
  OnContinue = ServiceContinue
  OnPause = ServicePause
  OnShutdown = ServiceShutdown
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 105
  Width = 190
end
