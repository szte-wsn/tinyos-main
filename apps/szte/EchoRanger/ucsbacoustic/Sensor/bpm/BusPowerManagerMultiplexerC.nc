generic module BusPowerManagerMultiplexerC(uint8_t slaveNum){
	provides interface BusPowerManager as Master;
	uses interface BusPowerManager as Slave[uint8_t id];
}
implementation{
	uint8_t slavesOn=0;
	
	command void Master.configure(uint16_t startup, uint16_t keepalive){
		uint8_t i;
		for(i=0;i<slaveNum;i++)
			call Slave.configure[i](startup, keepalive);
	}

	command void Master.requestPower(){
		uint8_t i;
		for(i=0;i<slaveNum;i++)
			call Slave.requestPower[i]();
	}

	command void Master.releasePower(){
		uint8_t i;
		for(i=0;i<slaveNum;i++)
			call Slave.releasePower[i]();
	}
	
	command bool Master.isPowerOn(){
		return slaveNum == slavesOn;
	}

	event void Slave.powerOn[uint8_t id](){
		if( ++slavesOn == slaveNum )
			signal Master.powerOn();
	}

	event void Slave.powerOff[uint8_t id](){
		if( --slavesOn == slaveNum )
			signal Master.powerOff();
	}
	
	default command void Slave.requestPower[uint8_t id](){
		slavesOn++;
	}
	
	default command void Slave.releasePower[uint8_t id](){
		slavesOn--;
	}
}