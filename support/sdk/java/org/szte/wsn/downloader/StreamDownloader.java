/*
 * Copyright (c) 2010, University of Szeged
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
 * Author:Andras Biro
 */

package org.szte.wsn.downloader;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashSet;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;
import java.util.Timer;
import java.util.TimerTask;

import org.szte.wsn.dataprocess.file.Gap;

public class StreamDownloader implements MessageListener {
	private MoteIF moteIF;
	private ArrayList<dataWriter> writers = new ArrayList<dataWriter>();
	private int listenonly;
	private int maxnode;
	private HashSet<Integer> currently_handled = new HashSet<Integer>();
	public static final int MIN_DOWNLOAD_SIZE=dataMsg.numElements_data()*4;
	private static final byte FRAME=0x5e;
	private static final byte ESCAPE=0x5d;
	private static final byte XORESCAPE=0x20;
	
	public final class ClearHandled extends TimerTask {
		public void run() {
			long now=(new Date()).getTime();
			HashSet<Integer> remove=new HashSet<Integer>();
			for(Integer i:currently_handled){
				if(writers.get(i).getLastModified()+10000<now)
					remove.add(i);
			}
			synchronized (currently_handled) {
				currently_handled.removeAll(remove);
			}
		}
	}

	public StreamDownloader(int listenonly,int maxnode, String source) {
		Runtime.getRuntime().addShutdownHook(new RunWhenShuttingDown());
		PhoenixSource phoenix;
		this.listenonly=listenonly;
		this.maxnode=maxnode;
		if (source == null) {
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		} else {
			phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
		}
		this.moteIF = new MoteIF(phoenix);
		this.moteIF.registerListener(new dataMsg(), this);
		this.moteIF.registerListener(new ctrltsMsg(), this);
		Timer timer = new Timer();
		TimerTask ch  = new ClearHandled();
	    timer.scheduleAtFixedRate(ch, 10000, 10000);
	}
	
	private dataWriter getWriter(int nodeid){
		for (int i = 0; i < writers.size(); i++) {
			if (writers.get(i).getNodeid() == nodeid) {
				return writers.get(i);
			}
		}
		return null;
	}

	public void messageReceived(int to, Message message) {
		if((listenonly<0||(message.getSerialPacket().get_header_src()==listenonly))){
			synchronized (currently_handled) {
				if (message instanceof ctrltsMsg && message.dataLength() == ctrltsMsg.DEFAULT_MESSAGE_SIZE&&(currently_handled.size()<maxnode||currently_handled.contains(writers.indexOf(getWriter(message.getSerialPacket().get_header_src()))))) {				
					long received_t=(new Date()).getTime();
					ctrltsMsg msg = (ctrltsMsg) message;
					System.out.println("Ctrl message received from #"+msg.getSerialPacket().get_header_src()+" min:"+msg.get_min_address()+" max:"+msg.get_max_address()+" timestamp:"+(Long)(msg.get_localtime()+msg.get_timestamp()));
					dataWriter currentWriter = getWriter(msg.getSerialPacket().get_header_src());
					if (currentWriter == null) {
						try {
							currentWriter = new dataWriter(msg.getSerialPacket().get_header_src(), FRAME, ESCAPE, XORESCAPE); 
							writers.add(currentWriter);
						} catch (IOException e) {
							System.err.println("Can't read gapfile for node #"+msg.getSerialPacket().get_header_src()+" data won't be downloaded from there");
							currentWriter=null;
						}
					}
					currentWriter.addTimeStamp(received_t, msg.get_localtime()+msg.get_timestamp());
					long currentMaxAddress = 0;
					try {
						currentMaxAddress = currentWriter.getMaxAddress();
						if(msg.get_max_address()-currentMaxAddress>=MIN_DOWNLOAD_SIZE){
							ctrlMsg response = new ctrlMsg();
							response.set_max_address(msg.get_max_address());
							if (msg.get_min_address() <= currentMaxAddress+1)
								response.set_min_address(currentMaxAddress+1);
							else {
								response.set_min_address(msg.get_min_address());
							}
							if(currently_handled.size()<maxnode){
								currently_handled.add(writers.indexOf(currentWriter));
								currentWriter.setLastModified(new Date().getTime());
								moteIF.send(currentWriter.getNodeid(), response);
							} else /*if(currently_handled.contains(writers.indexOf(currentWriter)))*/{
								currentWriter.setLastModified(new Date().getTime());
								moteIF.send(currentWriter.getNodeid(), response);
							}
						} else {//if we don't have to download new data, we try to fill a gap
							Long[] rep;
							rep = currentWriter.repairGap(msg.get_min_address());
							if(rep[0]<rep[1]){
								ctrlMsg response = new ctrlMsg();
								response.set_min_address(rep[0]);
								response.set_max_address(rep[1]);
								if(currently_handled.size()<maxnode){
									currently_handled.add(writers.indexOf(currentWriter));
									currentWriter.setLastModified(new Date().getTime());
									moteIF.send(currentWriter.getNodeid(), response);
								} else if(currently_handled.contains(writers.indexOf(currentWriter))){
									currentWriter.setLastModified(new Date().getTime());
									moteIF.send(currentWriter.getNodeid(), response);
								}
							}
						}
					} catch (IOException e1) {
						// TODO Auto-generated catch block
						//currentWriter.getMaxAddress()
						//moteIF.send()
						e1.printStackTrace();
					}
				} else if (message instanceof dataMsg && message.dataLength() == dataMsg.DEFAULT_MESSAGE_SIZE) {
					dataMsg msg = (dataMsg) message;
					System.out.print("Data received from "+msg.getSerialPacket().get_header_src()+" address: "+msg.get_address()+"|");
					dataWriter currentWriter = null;
					for (int i = 0; i < writers.size(); i++) {
						if (writers.get(i).getNodeid() == msg.getSerialPacket().get_header_src()) {
							currentWriter = writers.get(i);
							break;
						}
					}
					if (currentWriter != null) {
						try {
							long prevMaxAddress=currentWriter.getMaxAddress();
							currentWriter.writeData(msg.get_address(), dataMsg.numElements_data(), msg.get_data());
							if(msg.get_address()==prevMaxAddress+1){//the next bytes
								System.out.println("Data OK");
							} else if(msg.get_address()>prevMaxAddress+1){//we missed some data
								System.out.println("New gap: " + (prevMaxAddress+1) + "-" + (msg.get_address()-1));
								currentWriter.addGap(prevMaxAddress+1, msg.get_address()-1);
							} else { //we fill a gap
								ArrayList<Gap> gaps =currentWriter.getGaps();
								for(Gap currentGap:gaps){
									if(!currentGap.isUnrepairable()){
										if(((currentGap.getStart()<msg.get_address()+dataMsg.numElements_data())&&(currentGap.getStart()>=msg.get_address()))||
											((currentGap.getEnd()>=msg.get_address())&&(currentGap.getEnd()<msg.get_address()+dataMsg.numElements_data()))){
											long start_bef,end_bef,start_aft,end_aft;
											start_bef=currentGap.getStart();
											end_bef=msg.get_address()-1;
											start_aft=msg.get_address()+dataMsg.numElements_data();
											end_aft=currentGap.getEnd();
											System.out.print("Remove gap: " + currentGap.getStart()+"-"+currentGap.getEnd()+"|");
											currentWriter.removeGap(currentGap);
											if(end_bef>start_bef){//we didn't fill the whole gap
												System.out.print("New gap: " + start_bef + "-" + end_bef+"|");
												currentWriter.addGap(start_bef, end_bef);
											}
											if(end_aft>start_aft){//we didn't fill the whole gap
												System.out.print("New gap: " + start_aft + "-" + end_aft+"|");
												currentWriter.addGap(start_aft, end_aft);
											}
											System.out.print("\n");
											break;
										}
									}
								}
							}
						} catch (IOException e) {
							// TODO Auto-generated catch block
							//getMaxAddress
							//WriteData
							e.printStackTrace();
						}
					} 
				}
			}
		}
	}
	
	public class RunWhenShuttingDown extends Thread {
        public void run() {
            System.out.println("Closing files");
            for(dataWriter i:writers){
            	try {
					i.close();
				} catch (IOException e) {
					System.err.println("Can't close file "+i.getNodeid());
				}
            }
        }
    }
	
	public static void usage(){
		System.out.println("Usage: StreamDownloader [options]");
		System.out.println("Options: ");
		System.out.println("-comm <port>: Listen on <port>. Default: MOTECOMM");
		System.out.println("-only <id>: Only download mote Nr. <id>");
		System.out.println("-max <number>: Maximum <number> motes will be handled together. Default: 3");
	}

	public static void main(String[] args) throws Exception {
		String source = "sf@localhost:9002";
		int listenonly=-1;
		int maxnode=1;
		if (args.length == 0||args.length == 2||args.length == 4||args.length == 6) {
			for(int i=0;i<args.length;i+=2){
				if (args[i].equals("-comm")) {
					source = args[i+1];
				}
				if (args[i].equals("-only")) {
					listenonly = Integer.parseInt(args[i+1]);
				}
				if (args[i].equals("-max")) {
					maxnode = Integer.parseInt(args[i+1]);
				}
			}
		} else {
			StreamDownloader.usage();
		}
		new StreamDownloader(listenonly, maxnode, source);
	}

}
