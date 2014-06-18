configuration Ad524xC{
	provides interface Write<uint8_t> as Write1;
	provides interface Write<uint8_t> as Write2;
	provides interface Get<uint8_t> as Get1;
	provides interface Get<uint8_t> as Get2;
	provides interface SplitControl;
}
implementation{
	components Ad524xP, HplAd524xC, MainC;
	Write1 = Ad524xP.Write1;
	Write2 = Ad524xP.Write2;
	Get1 = Ad524xP.Get1;
	Get2 = Ad524xP.Get2;
	SplitControl = Ad524xP;
	
	Ad524xP.I2CPacket -> HplAd524xC;
	Ad524xP.Resource -> HplAd524xC;
	Ad524xP.GetAddress -> HplAd524xC;
	Ad524xP.BusPowerManager -> HplAd524xC;
	Ad524xP.Init <- MainC.SoftwareInit;
	
	components DiagMsgC;
	Ad524xP.DiagMsg -> DiagMsgC;
}