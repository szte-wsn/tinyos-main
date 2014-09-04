/**
  *
  * @author Zsolt Szabó <szabomeister@gmail.com>
  */

generic configuration DemoSensorC() {
  provides interface Read<uint16_t>;
}
implementation {
  components new Atm128InternalTemperatureC() as Sensor;
  Read = Sensor;
}
