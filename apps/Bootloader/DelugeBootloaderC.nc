configuration DelugeBootloaderC{
  provides interface BootloaderInterface;
}
implementation{
  components DelugeBootloaderP, ExtFlashC, InternalFlashC, AtmelBootloaderP;
  DelugeBootloaderP.ExtFlash -> ExtFlashC;
  DelugeBootloaderP.IntFlash -> InternalFlashC;
  DelugeBootloaderP.AtmelBootloader -> AtmelBootloaderP;
  BootloaderInterface = DelugeBootloaderP;
  
//   components PlatformSerialC;
//   DelugeBootloaderP.StdControl -> PlatformSerialC;
//   DelugeBootloaderP.UartByte -> PlatformSerialC;
}