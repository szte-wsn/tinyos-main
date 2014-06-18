module I2CPowerP{
	provides interface SplitControl;
	uses interface BusPowerManager;
	uses interface DiagMsg;
}
implementation{
	bool requested;
	
	command error_t SplitControl.start(){
		if(call DiagMsg.record()){
			call DiagMsg.str("SC Start");
			call DiagMsg.uint8(requested);
			call DiagMsg.send();
		}
		if(!requested){
			call BusPowerManager.requestPower();
			requested = TRUE;
		}
		if(call BusPowerManager.isPowerOn())
			signal SplitControl.startDone(SUCCESS);
		return SUCCESS;
	}
	
	command error_t SplitControl.stop(){
		if(call DiagMsg.record()){
			call DiagMsg.str("SC stop");
			call DiagMsg.uint8(requested);
			call DiagMsg.send();
		}
		if(requested){
			call BusPowerManager.releasePower();
			requested = FALSE;
		}
		signal SplitControl.stopDone(SUCCESS);
		return SUCCESS;
	}
	
	event void BusPowerManager.powerOn(){
		if(call DiagMsg.record()){
			call DiagMsg.str("SC on");
			call DiagMsg.uint8(requested);
			call DiagMsg.send();
		}
		signal SplitControl.startDone(SUCCESS);
	}
	
	event void BusPowerManager.powerOff(){
		if(call DiagMsg.record()){
			call DiagMsg.str("SC off");
			call DiagMsg.uint8(requested);
			call DiagMsg.send();
		}
	}
}