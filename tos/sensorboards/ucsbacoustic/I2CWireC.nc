configuration I2CWireC{
}
implementation{
  components I2CPowerP, I2CPowerManagerC, NoDiagMsgC;
  I2CPowerP.BusPowerManager -> I2CPowerManagerC;
  I2CPowerP.DiagMsg -> NoDiagMsgC;
}