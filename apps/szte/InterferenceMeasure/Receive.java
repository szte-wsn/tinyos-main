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

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class Receive implements MessageListener {

  private MoteIF moteIF;
  private ArrayList<Measurement> measurements= new ArrayList<Measurement>();
  
  private class Measurement{
    public int nodeid;
    private long time;
    private ArrayList<String> data;
    
    public Measurement(int nodeid){
        this.nodeid = nodeid;
        this.data = new ArrayList<String>();
    }
    
    public void setTime(long time){
      this.time = time;
    }
    
    public void addData(int offset, short[] newData){
      while( data.size() < offset+newData.length )
        data.add("-1");
      for(int i=0; i<newData.length;i++){
        data.set(offset+i, Short.toString(newData[i]) );
      }
    }
    
    public int size(){
      return data.size();
    }
    
    public void print(){
      String now = new SimpleDateFormat("dd. HH:mm:ss.SSS").format(new Date());
      Path path = Paths.get(now+"_"+Integer.toString(nodeid)+"_"+Long.toString(time)+".txt");
      try {
        Files.write(path, data, StandardCharsets.UTF_8, StandardOpenOption.CREATE_NEW);
      } catch (IOException e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
      }
    }
  }
  
  public Receive(MoteIF moteIF) {
    this.moteIF = moteIF;
    this.moteIF.registerListener(new RssiMsg(), this);
    this.moteIF.registerListener(new RssiDoneMsg(), this);
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
          Measurement meas = new Measurement(from);
          meas.addData(msg.get_index(), msg.get_data());
          measurements.add(meas);
        }
      }
    } else if( message instanceof RssiDoneMsg ){
      synchronized (measurements) {
        for(int i=0;i<measurements.size();i++){
          RssiDoneMsg msg = (RssiDoneMsg)message;
          if(measurements.get(i).nodeid == from){
            measurements.get(i).setTime(msg.get_time());
            measurements.get(i).print();
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
      new Receive( new MoteIF(phoenix) );	    
  }


}
