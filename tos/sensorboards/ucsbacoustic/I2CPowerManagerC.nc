configuration I2CPowerManagerC{
	provides interface BusPowerManager;
}
implementation{
	components new BusPowerManagerMultiplexerC(2), GainPotPowerManagerC, IntPotPowerManagerC;
	BusPowerManager = BusPowerManagerMultiplexerC;
	BusPowerManagerMultiplexerC.Slave[0] -> GainPotPowerManagerC;
	BusPowerManagerMultiplexerC.Slave[1] -> IntPotPowerManagerC;

// 	components new DummyBusPowerManagerC();
// 	BusPowerManager = DummyBusPowerManagerC;

// 	components IntPotPowerManagerC;
// 	BusPowerManager = IntPotPowerManagerC;
}