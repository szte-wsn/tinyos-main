generic configuration I2CPowerC(){
	provides interface Resource;
	uses interface Resource as SubResource;
}
implementation{
	components new ResourcePowerManagerProviderP(), new DeferredPowerManagerP(200), I2CPowerP, I2CPowerManagerC, new TimerMilliC();
	DeferredPowerManagerP -> I2CPowerP.SplitControl;
	DeferredPowerManagerP.TimerMilli -> TimerMilliC;
	
	Resource = ResourcePowerManagerProviderP.Resource;
	SubResource = ResourcePowerManagerProviderP.SubResource;
	
	DeferredPowerManagerP.ResourceDefaultOwner -> ResourcePowerManagerProviderP;
	
// 	components NoDiagMsgC as DiagMsgC;
// 	ResourcePowerManagerProviderP.DiagMsg -> DiagMsgC;
}