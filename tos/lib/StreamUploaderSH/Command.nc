interface Command
{
    event void newCommand(uint32_t id);
    command error_t sendData(uint32_t data);
}