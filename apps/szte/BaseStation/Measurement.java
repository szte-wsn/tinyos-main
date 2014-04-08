private class Measurement{
    private List<Short> data;
    private String pathprefix;
      
    private Date timeStamp;
    private int nodeid;
    
    private int measureTime;
    private long period;
    private long phase;
    
    //dev stuff
    private int[] senders = new int[2];
    private int[] fineTune = new int[2];
    private int[] power = new int[2];
    private int channel;
    
    private int toInt(List<Short> list){
      int ret = (list.get(0)<<8) | list.get(1);
    return ret;
    }

    private long toLong(List<Short> from){
      long ret = (from.get(0)<<24) | (from.get(1)<<16) | (from.get(2)<<8) | from.get(3);
    return ret;
    }
    
    private byte toSignedByte(short from){
      byte ret;
      if( from < 128 ){
        ret = (byte) from;
      } else {
        ret = (byte)(from - 256);
      }
      return ret;
    }
    
    public Measurement(Date timeStamp, int nodeid, ArrayList<Short> rawData, String pathprefix){
      this.timeStamp = timeStamp;
      this.nodeid = nodeid;
      this.pathprefix = pathprefix;
      /*
      * Header:
      *   typedef nx_struct result_t{
        nx_uint16_t measureTime;
        nx_uint32_t period;
        nx_uint32_t phase;
        //debug only:
        nx_uint8_t channel;
        nx_uint16_t senders[2];
        nx_int8_t fineTunes[2];
        nx_uint8_t power[2];
      } result_t;
      */
      //19B
      int offset = 0;
      measureTime = toInt(rawData.subList(offset, offset + 2)); offset+=2;
      period = toLong(rawData.subList(offset, offset + 4)); offset+=4;
      phase = toLong(rawData.subList(offset, offset + 4)); offset+=4;
      channel = rawData.get(offset); offset+=1;
      senders[0] = toInt(rawData.subList(offset, offset + 2)); offset+=2;
      senders[1] = toInt(rawData.subList(offset, offset + 2)); offset+=2;
      fineTune[0] = toSignedByte(rawData.get(offset)); offset+=1;
      fineTune[1] = toSignedByte(rawData.get(offset)); offset+=1;
      power[0] = rawData.get(offset); offset+=1;
      power[1] = rawData.get(offset); offset+=1;
      data = rawData.subList(offset, rawData.size());
    }

    public void print(){
      String now = new SimpleDateFormat("dd. HH:mm:ss.SSS").format(timeStamp);
      Path path = Paths.get(pathprefix + now+"_"+Integer.toString(nodeid)+".csv");
      try (BufferedWriter writer = Files.newBufferedWriter(path, StandardCharsets.UTF_8, StandardOpenOption.CREATE_NEW)){
        writer.write("Timestamp, "+ new SimpleDateFormat("YYYY.MM.dd. HH:mm:ss.SSS").format(timeStamp)+"\n");
        writer.write("NodeId, "+ Integer.toString(nodeid)+"\n");
        writer.write("MeasureTime, "+ Integer.toString(measureTime)+"\n");
        writer.write("Period, "+ Long.toString(period)+"\n");
        writer.write("Phase, "+ Long.toString(phase)+"\n");
        writer.write("Channel, " + Integer.toString(channel) + "\n");
        writer.write("Sender, " + Integer.toString(senders[0]) + ", " + Integer.toString(senders[1]) + "\n");
        writer.write("Finetune, " + Integer.toString(fineTune[0]) + ", " + Integer.toString(fineTune[1]) + "\n");
        writer.write("Power, " + Integer.toString(power[0]) + ", " + Integer.toString(power[1]) + "\n");
        writer.write("--\n");
        for(Short meas:data){
          writer.write(Short.toString(meas) + "\n");
        }
        writer.close();
      } catch (IOException e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
      }
    }
    
}