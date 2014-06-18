generic configuration HplMcp4x3_5xI2cC(){
	provides interface I2CPacket<TI2CBasicAddr>;
	provides interface Resource;
	provides interface BusPowerManager as SelfPower;
}
implementation{
	components new Atm128I2CMasterC(), new DummyBusPowerManagerC();
	I2CPacket = Atm128I2CMasterC;
	
	components GainPotPowerManagerC;
	//components new DummyBusPowerManagerC() as GainPotPowerManagerC;
	SelfPower = GainPotPowerManagerC;
	
	components new I2CPowerC();
	Resource = I2CPowerC.Resource;
	I2CPowerC.SubResource -> Atm128I2CMasterC;
	
	components I2CWireC;
}