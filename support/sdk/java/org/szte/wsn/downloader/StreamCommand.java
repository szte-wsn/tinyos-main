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
import java.io.File;
import java.util.HashSet;

import argparser.ArgParser;
import argparser.BooleanHolder;
import argparser.LongHolder;
import argparser.StringHolder;
import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;


public class StreamCommand implements MessageListener {
	private MoteIF moteIF;
	private int nodeid;
	public static final int ALL_NODE=0xffff;
	public static final int FIRST_NODE=0xffff+1;
	private long command;
	//private ArrayList<dataFile> files = new ArrayList<dataFile>();
	
	private static long twopow(int exponent){
		return 1L<<(exponent+1)-1;
	}
	
	private HashSet<Integer> commanded=new HashSet<Integer>();  
	
	public StreamCommand(String source, int nodeid, long comm) {
		PhoenixSource phoenix;
		this.nodeid=nodeid;
		this.command=comm;
		if (source == null) {
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		} else {
			phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
		}
		this.moteIF = new MoteIF(phoenix);
		this.moteIF.registerListener(new ctrltsMsg(), this);
		if(nodeid!=FIRST_NODE&&nodeid!=ALL_NODE)
			System.out.println("Waiting for node #"+nodeid);
		else if(nodeid==FIRST_NODE)
			System.out.println("Waiting for first node");
		else if(nodeid==ALL_NODE)
			System.out.println("Waiting for nodes");
	}

	public void messageReceived(int to, Message message) {
		if (message instanceof ctrltsMsg && message.dataLength() == ctrltsMsg.DEFAULT_MESSAGE_SIZE) {
			ctrltsMsg msg = (ctrltsMsg) message;
			if(!commanded.contains(msg.getSerialPacket().get_header_src())&&(nodeid==FIRST_NODE||nodeid==ALL_NODE||msg.getSerialPacket().get_header_src()==nodeid)){
				if(command==internalCommandConsts.CMD_ERASE&&(msg.get_max_address()-msg.get_min_address()<=200&&msg.get_min_address()!=twopow(32))){
					commanded.add(msg.getSerialPacket().get_header_src());
				} else {
					System.out.println("Found node #"+msg.getSerialPacket().get_header_src()+" data:"+ (msg.get_max_address()-msg.get_min_address())+" , sending command ("+command+")");
					if(nodeid==FIRST_NODE)
						nodeid=msg.getSerialPacket().get_header_src();
					ctrlMsg response = new ctrlMsg();
					response.set_min_address(command);
					response.set_max_address(command);
					try {
						moteIF.send(msg.getSerialPacket().get_header_src(), response);
						commanded.add(msg.getSerialPacket().get_header_src());
						if(command==internalCommandConsts.CMD_ERASE){
							System.out.println("Deleting local files");
							File bin=new File(dataWriter.nodeidToPath(nodeid, ".bin"));
							File ts=new File(dataWriter.nodeidToPath(nodeid, ".gap"));
							File gap=new File(dataWriter.nodeidToPath(nodeid, ".ts"));
							if(bin.exists()){
								bin.delete();
								System.out.println(bin.getPath()+" deleted");
							} 
							if(gap.exists()){
								gap.delete();
								System.out.println(gap.getPath()+" deleted");
							} 
							if(ts.exists()){
								ts.delete();
								System.out.println(ts.getPath()+" deleted");
							}
						}
//						if(nodeid!=ALL_NODE)
//							cmdSent=true;
					} catch (IOException e) {
						//TODO
					}
				}
			} else if(commanded.contains(msg.getSerialPacket().get_header_src())){
					System.out.println("Command done: "+msg.get_min_address());
					commanded.remove(msg.getSerialPacket().get_header_src());
					if(nodeid!=ALL_NODE&&commanded.size()==0)
						System.exit(0);
			} else {
					System.out.print("New message from node#"+msg.getSerialPacket().get_header_src()+": ");
					if(msg.get_min_address()==0||msg.get_min_address()!=msg.get_max_address()){
						System.out.println("MinAddress: " + msg.get_min_address()+" MaxAddress: "+msg.get_max_address());
					} else if(msg.get_min_address()==twopow(32)){ 
						System.out.println("StreamStorage didn't started! Maybe you should erase the mote");
					}
			}
		}
	}
	
	private static long commandParser(String command, long argument, long argument2) {
		if(command.equals("erase"))
			return internalCommandConsts.CMD_ERASE;
		else if(command.equals("setgain")){
			long ret=externalCommandConsts.CMD_SETGAIN;
			if(argument<0)
				return -1;
			else
				return StreamCommand.setArgument(ret,argument, 0);
		}else if(command.equals("setgaindual")){
			long ret=externalCommandConsts.CMD_SETGAIN_DUAL;
			if(argument<0 || argument2<0)
				return -1;
			else {
				ret = StreamCommand.setArgument(ret,argument, 0);
				return StreamCommand.setArgument(ret,argument2, 1);
			}
		}else if(command.equals("setwait")){
			long ret=externalCommandConsts.CMD_SETWAIT;
			if(argument<0)
				return -1;
			else
				return StreamCommand.setArgument(ret,argument, 0);
		}else if(command.equals("measnow")){
			return externalCommandConsts.CMD_MEASNOW;
		} else
			return -1;
	}

	private static long setArgument(long command, long argument, int argumentindex) {
		argument<<=(8*(argumentindex+1));
		return command+argument;
	}
	
	public static void main(String[] args) throws Exception {

		BooleanHolder help=new BooleanHolder();
		StringHolder source=new StringHolder("sf@localhost:9002");
		StringHolder nodeid=new StringHolder();
		StringHolder command=new StringHolder();
		LongHolder commandValue=new LongHolder(-1L);
		LongHolder commandValue2=new LongHolder(-1L);
		LongHolder rawcommand=new LongHolder(-1L);
		
		
		ArgParser parser = new ArgParser("java StreamCommand [options]",false);
		parser.addOption("-h,--help %v#Displays help information",help);
		parser.addOption("-s,--source %s#Select serial port source (default: sf@localhost:9002)",source);
		parser.addOption("-n,--nodeid %s#Select node (special nodeids: all; first)",nodeid);
		parser.addOption("-c,--command %s#Select command: erase, setgain, setgaindual, measnow, setwait (default: erase; working only if --raw doesn't set)",command);
		parser.addOption("-r,--raw %d#Select command with number (working only if --command doesn't set)",rawcommand);
		parser.addOption("-v,--value1 %d#Setting first command argument",commandValue);
		parser.addOption("-V,--value2 %d#Setting second command argument",commandValue2);
		parser.matchAllArgs (args);
		
		if(help.value||(command.value!=null&&rawcommand.value>=0||nodeid.value==null)){
			System.out.println(parser.getHelpMessage());
			System.exit(0);
		}
		int node_id=0;
		try{
			node_id=Integer.valueOf(nodeid.value);
		}catch(NumberFormatException e){
			if(nodeid.value.equals("all"))
				node_id=ALL_NODE;
			else if(nodeid.value.equals("first"))
				node_id=FIRST_NODE;
			else{
				throw e;
			}
		}catch(Exception e){
			System.out.println(parser.getHelpMessage());
			System.exit(0);
		}
		long comm=rawcommand.value;
		if(comm<0&&command.value!=null)
		{
			comm=StreamCommand.commandParser(command.value, commandValue.value, commandValue2.value);
			if(comm<0){
				System.out.println(parser.getHelpMessage());
				System.exit(0);
			}
		} 
		else {
			comm=internalCommandConsts.CMD_ERASE;
		}

		new StreamCommand(source.value, node_id, comm);
	}

}
