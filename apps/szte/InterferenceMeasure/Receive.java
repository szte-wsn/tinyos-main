/*									tab:4
* Copyright (c) 2005 The Regents of the University  of California.  
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
*   notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright
*   notice, this list of conditions and the following disclaimer in the
*   documentation and/or other materials provided with the
*   distribution.
* - Neither the name of the copyright holders nor the names of
*   its contributors may be used to endorse or promote products derived
*   from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
* THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
*/

/**
* Java-side application for testing serial port communication.
* 
*
* @author Phil Levis <pal@cs.berkeley.edu>
* @date August 12 2005
*/

import java.io.BufferedWriter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class Receive implements MessageListener {

  private MoteIF moteIF;
  private ArrayList<RawMeasurement> measurements= new ArrayList<RawMeasurement>();
  private String pathprefix;
  
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
      * 	typedef nx_struct result_t{
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
  
  private class RawMeasurement{
    public int nodeid;
  private ArrayList<Short> data;
    
    public RawMeasurement(int nodeid){
        this.nodeid = nodeid;
        this.data = new ArrayList<Short>();
    }
    
    public void addData(int offset, short[] newData){
      while( data.size() < offset+newData.length ){
        data.add((short) -1);
      }
      for(int i=0; i<newData.length;i++){
        data.set(offset+i, newData[i] );
      }
    }
    
    public int size(){
      return data.size();
    }   
    
  }
  
  public Receive(MoteIF moteIF, String pathprefix) {
    this.moteIF = moteIF;
    this.moteIF.registerListener(new RssiMsg(), this);
    this.moteIF.registerListener(new RssiDoneMsg(), this);
    this.pathprefix = pathprefix;
  }


  public void messageReceived(int to, Message message) {
    int from = message.getSerialPacket().get_header_src();
    if( message instanceof RssiMsg ){
      RssiMsg msg = (RssiMsg)message;
      int i;
      synchronized (measurements) {
        for(i=0;i<measurements.size();i++){
          if(measurements.get(i).nodeid == from){
            measurements.get(i).addData(msg.get_index(), msg.get_data());
            break;
          }
        }
        if(i == measurements.size()){
          RawMeasurement meas = new RawMeasurement(from);
          meas.addData(msg.get_index(), msg.get_data());
          measurements.add(meas);
        }
      }
    } else if( message instanceof RssiDoneMsg ){
      synchronized (measurements) {
        for(int i=0;i<measurements.size();i++){
          RssiDoneMsg msg = (RssiDoneMsg)message;
          if(measurements.get(i).nodeid == from){
            Measurement meas = new Measurement(new Date(), measurements.get(i).nodeid, measurements.get(i).data, pathprefix);
            meas.print();
            System.out.println("Data saved from NodID#"+Integer.toString(from));
            measurements.remove(i);
            break;
          }
        }
      }
    }
  }
  
  public static void main(String[] args) throws Exception {
  
      PhoenixSource phoenix;
      phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
      new Receive( new MoteIF(phoenix), args[0] );	    
  }


}
