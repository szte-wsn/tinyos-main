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
import java.util.Timer;
import java.util.TimerTask;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class Receive implements MessageListener {

  private MoteIF moteIF;
  private ArrayList<Measurement> measurements= new ArrayList<Measurement>();
  
  private class Write extends TimerTask {

	@Override
	public void run() {
		synchronized (measurements) {
			for( int i=0;i<measurements.size();i++){
				measurements.get(i).print();
				measurements.remove(i);
			}
		}
	}
	  
  }
  
  private class Measurement{
    public int nodeid;
    private long time;
    private ArrayList<String> data;
    
    public Measurement(int nodeid, long time){
	      this.nodeid = nodeid;
	      this.time = time;
	      this.data = new ArrayList<String>();
    }
    
    public void addData(int offset, short[] newData){
      while( data.size() < offset )
    	  data.add("-1");
      for(short newElement:newData){
    	  data.add(offset, Short.toString(newElement) );
      }
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
	  Write tt = new Write();
	  Timer timer = new Timer("Printer");
	  timer.schedule(tt, 0, 10000);
  }


  public void messageReceived(int to, Message message) {
	  RssiMsg msg = (RssiMsg)message;
	  int from = message.getSerialPacket().get_header_src();
	  int i;
	  synchronized (measurements) {
		  for(i=0;i<measurements.size();i++){
			  if(measurements.get(i).nodeid == from){
				  measurements.get(i).addData(msg.get_index(), msg.get_data());
				  break;
			  }
		  }
		  if(i == measurements.size()){
			  Measurement meas = new Measurement(from, msg.get_time());
			  meas.addData(msg.get_index(), msg.get_data());
			  measurements.add(meas);
		  }
	  }
  }
  
  public static void main(String[] args) throws Exception {
  
	    PhoenixSource phoenix;
	    phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
	    new Receive( new MoteIF(phoenix) );	    
  }


}
