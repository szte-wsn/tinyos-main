configuration Si443xOffC 
{
  provides interface Init;
}
implementation 
{
  components Si443xOffP, HplAtm128GeneralIOC as PinsC;
  Init = Si443xOffP;
  
  components Atm128SpiC as SpiC;
  Si443xOffP.SpiResource -> SpiC.Resource[unique("Atm128SpiC.Resource")];
  Si443xOffP.SpiByte -> SpiC;

  Si443xOffP.CSN -> PinsC.PortF0;
  Si443xOffP.IO -> PinsC.PortD4;
  Si443xOffP.IRQ -> PinsC.PortB4;
}
