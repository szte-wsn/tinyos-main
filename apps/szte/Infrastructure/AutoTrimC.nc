configuration AutoTrimC{
	provides interface AutoTrim;
}
implementation{
	components AutoTrimP as AutoTrimP;
	AutoTrim = AutoTrimP;
}
