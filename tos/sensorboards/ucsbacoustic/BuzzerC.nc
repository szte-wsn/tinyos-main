generic configuration BuzzerC(){
	provides interface GeneralIO;
}
implementation{
	components MicaBusC;
	GeneralIO = MicaBusC.PW3;
}