configuration HplAd524xC{
	provides interface I2CPacket<TI2CBasicAddr>;
	provides interface Resource;
	provides interface GetNow<uint8_t>;
	provides interface BusPowerManager as SelfPower;
}
implementation{
	components new Atm128I2CMasterC(), Ad524xAddrC;

	I2CPacket = Atm128I2CMasterC;
	
	GetNow = Ad524xAddrC;
	components IntPotPowerManagerC;
	//components new DummyBusPowerManagerC() as IntPotPowerManagerC;
	SelfPower = IntPotPowerManagerC;
	
	components new I2CPowerC();
	Resource = I2CPowerC.Resource;
	I2CPowerC.SubResource -> Atm128I2CMasterC.Resource;
	
	components I2CWireC;
}