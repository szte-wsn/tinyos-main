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
package org.szte.wsn.downloader2;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashSet;
import java.util.Timer;
import java.util.TimerTask;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;

public class Communication  implements MessageListener {

	private static final int WAIT_DISCOVER = 5000;
	private static final int WAIT_ERASE = 30000;
	private static final int WAIT_COMMAND = 3000;
	private static final int GET_TIMEOUT = 3000;
	private static final int DOWNLOAD_TIMEOUT = 20000;
	private final int M_NOTHING=0;
	private final int M_DISCOVER=1;
	private static final int M_ERASE_ALL = 2;
	private static final int M_ERASE = 3;
	private static final int M_DOWNLOAD = 4;
	private static final int M_DOWNLOAD_PING = 5;
	private static final int M_USER = 6;
	private static final int M_USER_ALL = 7;
	private static final int M_AUTODOWNLOAD=99;
	
	public static final int E_SUCCESS = 0;
	public static final int E_TIMEOUT = 1;


	private int mode=M_AUTODOWNLOAD;
	private int currentMote;
	private long lastData=0;
	private Timer timer=new Timer();
	private TimerTask downloadtask=null;
	private TimerTask pingtask=null;
	
	private MoteIF moteIF;
	private PhoenixSource phoenix;
	private StreamDownloader sd;
	private short seqnum=0;

	private HashSet<Integer> motes=new HashSet<Integer>();
	private ArrayList<Pong> pongsReceived=new ArrayList<Pong>(); 
	
	private static HashSet<Integer> getNodeIds(ArrayList<Pong> pongs) {
		HashSet<Integer> ret=new HashSet<Integer>();
		for(Pong current: pongs){
			ret.add(current.getNodeID());
		}
		return ret;
	}

	public HashSet<Integer> getMotes() {
		return motes;
	}

	private boolean verbose=true;
	
	private void exception(IOException e){
		System.err.println("Communication error, can't send message. Exiting");
		e.printStackTrace();
		System.exit(1);
	}
	
	private HashSet<Integer> oneElementHashSet(int element){
		HashSet<Integer> ret=new HashSet<Integer>();
		ret.add(element);
		return ret;		
	}
	
	private boolean everyMoteAnswerd(HashSet<Integer> motes, ArrayList<Pong> pongs){
		if(pongsReceived.size()<motes.size())
			return false;
		HashSet<Integer> pongIds=getNodeIds(pongsReceived);
		for(Integer moteid:motes){
			if(!pongIds.contains(moteid)){
				return false;
			}
		}
		return true;
	}
	
	@Override
	public void messageReceived(int to, Message m) {
		if(m instanceof CtrlMsg){
			CtrlMsg rec=(CtrlMsg)m;
			int nodeid=m.getSerialPacket().get_header_src();
			long min_address=rec.get_min_address();
			long max_address=rec.get_max_address();
			if(!motes.contains(nodeid))
				motes.add(m.getSerialPacket().get_header_src());
			switch(mode){
				case M_DISCOVER:{
					if(verbose)
						System.out.println("New node #"+nodeid+" "+min_address+"-"+max_address);	
				}break;
				case M_DOWNLOAD_PING:{
					if(verbose)
						System.out.println("Node #"+nodeid+" "+min_address+"-"+max_address);
					pongsReceived.add(new Pong(nodeid, min_address, max_address));
				}break;
				case M_ERASE_ALL:{
					if(min_address==max_address&&min_address==0){
						if(verbose)
							System.out.println("Node #"+nodeid+" erased.");
						pongsReceived.add(new Pong(nodeid, min_address, max_address));
						if(everyMoteAnswerd(motes, pongsReceived))
							sd.eraseComplete(motes,E_SUCCESS);
					}
				}break;
				
				case M_ERASE:{
					if(min_address==max_address&&min_address==0){
						if(verbose)
							System.out.println("Node #"+nodeid+" erased.");
						if(currentMote==nodeid){
							pingtask.cancel();
							mode=M_NOTHING;
							sd.eraseComplete(oneElementHashSet(nodeid),E_SUCCESS);
						}
					}
				}break;
				case M_USER_ALL:{
					if(min_address==max_address&&min_address==0){
						if(verbose)
							System.out.println("Node #"+nodeid+" command done.");
						pongsReceived.add(new Pong(nodeid, min_address, max_address));
						if(everyMoteAnswerd(motes, pongsReceived))
							sd.userComplete(motes,E_SUCCESS);
					}
				}break;
				
				case M_USER:{
					if(min_address==max_address&&min_address==0){
						if(verbose)
							System.out.println("Node #"+nodeid+" command done.");
						if(currentMote==nodeid){
							pingtask.cancel();
							mode=M_NOTHING;
							sd.userComplete(oneElementHashSet(nodeid),E_SUCCESS);
						}
					}
				}break;				
				case M_DOWNLOAD:{
					if(currentMote==nodeid){
						downloadtask.cancel();
						mode=M_NOTHING;
						sd.downloadComplete(E_SUCCESS, min_address, max_address);
					}
				}break;
			}
		} else if(m instanceof DataMsg){
			DataMsg rec=(DataMsg)m;
			if(rec.get_source()!=currentMote||mode!=M_DOWNLOAD){
				int nodeid=rec.getSerialPacket().get_header_src();
				if(verbose)
					System.out.println("Unwanted data from node #"+nodeid+". Sending stop download command.");
					stopSending(nodeid);
				
			} else {
				lastData=new Date().getTime();
				byte[] data=rec.get_payload();
				sd.newData(rec.get_source(),rec.get_address(),data);
			}
		} else if(m instanceof TimeMsg){
			TimeMsg rec=(TimeMsg)m;
			sd.newTimeSync(rec.get_remoteTime()+rec.get_sendTime()-rec.get_localTime(),
					rec.get_bootCount(), new Date().getTime(),m.getSerialPacket().get_header_src());
		}
	}
	
	private void sendGet(int nodeID, long minaddress, long maxaddress, int waitForAnswer, boolean startTimeOut){
		GetMsg get=new GetMsg();
		get.set_nodeid(nodeID);
		get.set_min_address(minaddress);
		get.set_max_address(maxaddress);
		get.set_seq_num(++seqnum);
		if(startTimeOut){
			downloadtask=new GetWaiter();
			timer.schedule(downloadtask, waitForAnswer);
		}
		try {
			moteIF.send(MoteIF.TOS_BCAST_ADDR, get);
		} catch (IOException e) {
			exception(e);
		}
	}
	
	private void sendCommnad(short command, int waitForAnswer){
		CommandMsg cmd=new CommandMsg();
		cmd.set_cmd(command);
		if(waitForAnswer>0){
			pingtask=new PongWaiter();
			timer.schedule(pingtask, waitForAnswer);
		}
		try {
			moteIF.send(MoteIF.TOS_BCAST_ADDR, cmd);
		} catch (IOException e) {
			exception(e);
		}
	}
	
	private void sendCommnad(int nodeid, short command, int waitForAnswer, int argument){
		if(waitForAnswer>0)
			timer.schedule(new PongWaiter(), waitForAnswer);
		long realcommand=(argument<<16)+command;
		sendGet(nodeid, realcommand, realcommand, GET_TIMEOUT, false);
	}
	
	private void sendCommnad(int nodeid, short command, int waitForAnswer){
		sendCommnad(nodeid, command, waitForAnswer, 0);
	}
	
	public Communication(StreamDownloader sd,String source){
		this.sd=sd;
		if (source == null) {
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		} else {
			phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
		}
		this.moteIF = new MoteIF(phoenix);
		this.moteIF.registerListener(new DataMsg(), this);
		this.moteIF.registerListener(new CtrlMsg(), this);
		this.moteIF.registerListener(new TimeMsg(), this);
	}
	
	public void stop(){
		timer.cancel();
		phoenix.shutdown();
	}

	public void discover(HashSet<Integer> pastmotes){
		if(pastmotes==null)
			motes.clear();
		else
			motes=pastmotes;
		if(verbose)
			System.out.println("Starting discovery");
		mode=M_DISCOVER;
		sendCommnad(CommandMsg.COMMAND_PING, WAIT_DISCOVER);
	}
	
	public void sendErase(){
		mode=M_ERASE_ALL;
		pongsReceived.clear();
		sendCommnad(CommandMsg.COMMAND_ERASE, WAIT_ERASE);
	}
	
	public void getAddresses(){
		mode=M_DOWNLOAD_PING;
		pongsReceived.clear();
		sendCommnad(CommandMsg.COMMAND_PING, WAIT_COMMAND);
	}
	
	public void sendUser(short cmd){
		mode=M_USER_ALL;
		pongsReceived.clear();
		sendCommnad(cmd, WAIT_COMMAND);
	}
	
	public void sendUser(int nodeid, short cmd, int argument){
		if(nodeid==0xffff)
			sendUser(cmd);
		else{
			currentMote=nodeid;
			mode=M_USER;
			sendCommnad(nodeid,cmd, WAIT_COMMAND,argument);
		}
	}

	public void sendErase(int nodeid){
		if(nodeid==0xffff)
			sendErase();
		else{
			currentMote=nodeid;
			mode=M_ERASE;
			sendCommnad(nodeid, CommandMsg.COMMAND_ERASE, WAIT_ERASE);
		}
	}
	
	public void download(int nodeid, long from, long to){
		currentMote=nodeid;
		mode=M_DOWNLOAD;
		sendGet(nodeid, from, to, DOWNLOAD_TIMEOUT, true);
	}
	

	
	public void stopSending(int nodeid) {
		sendCommnad(nodeid,CommandMsg.COMMAND_STOPSEND, 0);
	}
	
	public final class PongWaiter extends TimerTask {

		@Override
		public void run() {
			int prevmode=mode;
			mode=M_NOTHING;
			switch(prevmode){
				case M_DISCOVER:{
					sd.discoveryComplete(motes);
				}break;
				case M_ERASE_ALL:{
					sd.eraseComplete(getNodeIds(pongsReceived), E_SUCCESS);
				}break;
				case M_DOWNLOAD_PING:{
					sd.getAddressesComplete(pongsReceived, false);
				}break;
				case M_ERASE:{
					sd.eraseComplete(oneElementHashSet(currentMote),E_TIMEOUT);;
				}break;
				case M_USER:{
					sd.userComplete(oneElementHashSet(currentMote),E_TIMEOUT);;
				}break;
				case M_USER_ALL:{
					sd.userComplete(getNodeIds(pongsReceived),E_SUCCESS);;
				}break;
			}
		}
	
	}
	
	public final class GetWaiter extends TimerTask {

		

		@Override
		public void run() {
			switch(mode){
				case M_DOWNLOAD:{
					long now=(new Date()).getTime();
					if(lastData+DOWNLOAD_TIMEOUT<now){
						mode=M_NOTHING;
						sd.downloadComplete(E_TIMEOUT,0,0);
					} else {
						downloadtask=new GetWaiter();
						timer.schedule(downloadtask, DOWNLOAD_TIMEOUT);
					}
				}break;
			}
		}
		
	}



}
