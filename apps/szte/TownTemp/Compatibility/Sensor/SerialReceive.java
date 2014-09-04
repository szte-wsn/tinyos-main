/** Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Csepe Zoltan
*/

import static java.lang.System.out;
import net.tinyos.packet.*;
import net.tinyos.message.*;
import net.tinyos.util.PrintStreamMessenger;
import java.io.*;

class SerialReceive implements MessageListener{
	
	private MoteIF moteIF;
	static PrintWriter fop;
	static int file=0;
	int time=-1;
	public SerialReceive(MoteIF moteIF){
		this.moteIF=moteIF;
		this.moteIF.registerListener(new SerialMsg(),this);
	}
	
	public void messageReceived(int dest_addr,Message msg){
		int temp;
		int counter;
		long time;
		int hum;
		if (msg instanceof SerialMsg) {
			SerialMsg serialData = (SerialMsg)msg;
			SerialPacket serPkt = msg.getSerialPacket();
			temp = serialData.get_temperature();
			time=serialData.get_time();
			counter=serialData.get_counter();
			hum=serialData.get_humidity();
			try{
		fop = new PrintWriter(new FileWriter("temp"+file+".txt",true));
		}catch(IOException ex){}
			if( temp == SerialConsts.END_VALUE && time == SerialConsts.END_VALUE && counter == SerialConsts.END_VALUE && hum == SerialConsts.END_VALUE)
				System.exit(0);
			out.println("Counter: "+counter+" Temp_measured:\t"+temp+"\tTime\t"+time+"\tHumidity:\t"+hum);
			fop.println(counter+"\t"+temp+"\t"+hum+"\t"+time);
			fop.close();
		}
	}
	
	public void send(String data, String id)  
	{
		ControlMsg msg=new ControlMsg();
		try{
			long time = System.currentTimeMillis();
       			int seged=(int) (time/1000);
       			short s1=(short) (seged/100000);
		       	int seged2=seged%(s1*100000);
		       	short s2=(short)(seged2-Short.MAX_VALUE);
			msg.set_control(Integer.parseInt(data));
			msg.set_time(seged);
			System.out.println(seged);
			moteIF.send(Integer.parseInt(id),msg);
			out.println("Message sent to the mote "+ Integer.parseInt(id));
		}catch(IOException e)
		{
			out.println("Cannot send message to mote ");
		}
	}

	public static void main(String[] args)throws IOException  
	{
		PhoenixSource phoenix = null;
		MoteIF mif = null;
		String data=null;
		String data2=null;
		int seged=-1;
				
		if( args.length == 1 ){
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
			data=args[0];
		} else if ( args.length == 4 && args[0].equals("-comm") ) {
			phoenix = BuildSource.makePhoenix(args[1], PrintStreamMessenger.err);
			data=args[2];
			data2=args[3];
		} else {
			System.err.println("usage: java TestSerial [-comm <source>] [data to send] [ID to send]");
			System.exit(1);
		}
		mif = new MoteIF(phoenix);
		SerialReceive app= new SerialReceive(mif);
		app.send(data,data2);
		seged=Integer.parseInt(data);
		file=Integer.parseInt(args[3]);
		if((seged!=2)&&(seged!=5)) {
			if (seged==3){
				File del = new File("temp"+file+".txt");
				del.delete();
			}
			System.exit(0);
		}
		else if(seged==2){
			out.println("letoltes");
			fop = new PrintWriter(new FileWriter("temp"+file+".txt",true));
			File temp_file = new File("temp"+file+".txt");
				if (temp_file.length()==0){
				fop.println("Counter\t"+"Temp\t"+"Humidity\tTime");
				}
			fop.close();
		}else if(seged==5){
			out.println("ellenorzes");
			fop = new PrintWriter(new FileWriter("check"+file+".txt",true));
			File temp_file = new File("check"+file+".txt");
				if (temp_file.length()==0){
				fop.println("PCTime\t"+"Temp\t"+"Humidity\tTime");
				fop.println(System.currentTimeMillis()>>10);
				}
			fop.close();
		}
		
	}
}

	

	
	
	
