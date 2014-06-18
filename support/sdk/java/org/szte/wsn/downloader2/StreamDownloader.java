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

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashSet;

import org.szte.wsn.CSVProcess.CSVHandler;
import org.szte.wsn.dataprocess.file.Gap;

public class StreamDownloader{
	private static final long MIN_DOWNLOAD_SIZE = 100;
	private Communication comm;
	private ConsoleHandler console;
	private CSVHandler timeSync;
	private ArrayList<DataWriter> writers = new ArrayList<DataWriter>();
	private Pong currently_handled;
	private int currentMote;
	private static final int ALL=0xffff;
	private static final String REFID="99999"; 
	private boolean welcomePrinted=false;
	
		
	

	
	public StreamDownloader(String source){
		comm=new Communication(this, source);
		console=new ConsoleHandler("StreamDownloader shell", ">", "help");
		console.addCommand("motelist", "Display the id of all known motes");
		console.addCommand("discover", "Discover the network for motes (motes from earlier discoveries will be removed)");
		console.addCommand("rediscover", "Discover the network for new motes (motes from earlier discoveries will be remained)");
		console.addCommand("erase", "erase <nodeid>: Erases mote with <nodeid>.\r\n" +
							"if <nodeid>=all erases all motes");
		console.addCommand("download", "downdload <nodeid>: Downloads mote with <nodeid>.\r\n" +
							"if <nodeid>=all erases all motes");
		console.addCommand("quit", "Quits from the program");
		console.addCommand("command", "command <nodeid> <command> [argument]: Sends a user command");
		try {
			this.timeSync=new CSVHandler(new File(REFID+"_time.csv"), true, ";", 2, new Integer[]{1,3,4,5,6,7});
		} catch (IOException e) {
			System.err.println("Error: Can't open or parse the timesync file");
			System.exit(1);
		}	
		comm.discover(null);
	}
	
	//a-b
	private HashSet<Integer> subtract(HashSet<Integer> a, HashSet<Integer> b){
		HashSet<Integer> ret = new HashSet<Integer>();
		ret.addAll(a);
		ret.removeAll(b);
		return ret;
	}
	
	public void discoveryComplete(HashSet<Integer> motes) {
		System.out.print(motes.size()+" motes found. Discover again?");
		if(console.readChar(new String[]{"y","n"}).endsWith("y")){
			comm.discover(motes);
		} else {
			System.out.println("Opening/initializing files");
			for(int nodeid:motes)
				if(getWriter(nodeid, writers)==null){
					writers.add(new DataWriter(nodeid));
				}
			waitForCommands();
		}
	}
	
	public void eraseComplete(HashSet<Integer> nodeIds,int error) {
		if(error==Communication.E_SUCCESS){
			System.out.println("Erasing local file(s)");
			for(Integer i:nodeIds){
				DataWriter current=getWriter(i, writers);
				try{
					if(current==null)
						new DataWriter(i).erase();
					else{
						current.erase();
					}
				} catch(IOException e){
					System.err.println("Can't erase file(s) of mote #"+i);
				}
			}
			if(currentMote==-1*ALL){
				HashSet<Integer> allNodeIds=comm.getMotes();
				for(Integer i:subtract(nodeIds, allNodeIds)){
					System.out.println("Erase complete on unknown mote: "+i+". Discover adviced.");
				}
				for(Integer i:subtract(allNodeIds, nodeIds)){
					System.out.println("Probably unerased mote: "+i+".");
				}
			} else if(nodeIds.contains(currentMote)){
				System.out.println("Erase complete on mote #"+currentMote);
			}
		} else{
			System.out.println("Erase failed on mote #"+currentMote+". Mote didn't answer.");
		}
		waitForCommands();
	}
	
	public void userComplete(HashSet<Integer> nodeIds, int error) {
		if(error==Communication.E_SUCCESS){
			if(currentMote==ALL){
				HashSet<Integer> allNodeIds=comm.getMotes();
				for(Integer i:subtract(nodeIds, allNodeIds)){
					System.out.println("User complete on unknown mote: "+i+". Discover adviced.");
				}
				for(Integer i:subtract(allNodeIds, nodeIds)){
					System.out.println("Mote didn't answer: "+i+".");
				}
			} else if(nodeIds.contains(currentMote)){
				System.out.println("User complete on mote #"+currentMote);
			}
		} else{
			System.out.println("User failed on mote #"+currentMote+". Mote didn't answer.");
		}
		waitForCommands();
		
	}

	public void getAddressesComplete(ArrayList<Pong> pongs, boolean repairOnly) {
		Pong maxdownloadPong=null;
		long maxdownload=Long.MIN_VALUE;
		currently_handled=null;
		for(Pong p:pongs){
			if(currentMote==p.getNodeID()||currentMote==ALL){
				try {
					DataWriter currentwriter=StreamDownloader.getWriter(p.getNodeID(), writers);
					if(currentwriter!=null){
						long download;
						Gap repair=currentwriter.repairGap(p.getMinAddress());
						if(repair!=null){
							maxdownload=Long.MAX_VALUE;
							maxdownloadPong=p;
							break;
						}
						if(p.getMinAddress()<currentwriter.getMaxAddress()){
							download=p.getMaxAddress()-currentwriter.getMaxAddress();
						}else{
							download=p.getMaxAddress()-p.getMinAddress();
						}
						if(download>maxdownload){
							maxdownload=download;
							maxdownloadPong=p;
						}
					} else {
						if(p.getMaxAddress()-p.getMinAddress()>maxdownload){
							maxdownload=p.getMaxAddress()-p.getMinAddress();
							maxdownloadPong=p;
						}
					}
				} catch (IOException e) {
					System.err.println("Error: Can't read file "+DataWriter.nodeidToPath(p.getNodeID(),".bin"));
				}
			}
		}
		if((maxdownload>MIN_DOWNLOAD_SIZE||(maxdownload>0&&currentMote!=ALL))&&maxdownloadPong!=null){
			DataWriter maxdownloadWriter=getWriter(maxdownloadPong.getNodeID(), writers);
			maxdownloadWriter.setLastModified();
			
			if(maxdownload==Long.MAX_VALUE){
				Gap repair=maxdownloadWriter.repairGap(maxdownloadPong.getMinAddress());
				System.out.println("Download from #"+maxdownloadWriter.getNodeid()+" ("+repair.getStart()+"-"+repair.getEnd()+")");
				currently_handled=new Pong(maxdownloadWriter.getNodeid(), repair.getStart(), repair.getEnd());
				comm.download(maxdownloadWriter.getNodeid(), repair.getStart(), repair.getEnd());
			} else if(!repairOnly){
				long minaddress;
				try {
					minaddress = (maxdownloadPong.getMinAddress()>maxdownloadWriter.getMaxAddress())?maxdownloadPong.getMinAddress():maxdownloadWriter.getMaxAddress()+1;
					System.out.println("Download from #"+maxdownloadWriter.getNodeid()+" ("+minaddress+"-"+maxdownloadPong.getMaxAddress()+")");

					comm.download(maxdownloadWriter.getNodeid(), minaddress, maxdownloadPong.getMaxAddress());
					currently_handled=new Pong(maxdownloadWriter.getNodeid(), minaddress, maxdownloadPong.getMaxAddress());
				}catch (IOException e) {
					System.err.println("Error: Can't read file "+DataWriter.nodeidToPath(maxdownloadPong.getNodeID(),".bin"));
				}
			}
		}
		if(currently_handled==null){
			if(repairOnly){
				System.out.println("Download complete");
				
			}
			if(currentMote==ALL&&!repairOnly){
				System.out.println("No new data on motes");
			} else if(currentMote==ALL){
				comm.getAddresses();
				return;
			}else{
				System.out.println("No answer from mote #"+currentMote);
			}
			waitForCommands();
		}
		
	}


	public void downloadComplete(int error, long min_address, long max_address) {
		if(error==Communication.E_SUCCESS){
			int current=currently_handled.getNodeID();
			DataWriter writer=getWriter(current, writers);
			if(writer!=null&&writer.getGapCount()==0)
				System.out.println("Download complete");
			else {
				ArrayList<Pong> pongs=new ArrayList<Pong>();
				pongs.add(new Pong(current, min_address, max_address));
				getAddressesComplete(pongs, true);
				return;
			}
		}else if(error==Communication.E_TIMEOUT){
			System.out.println("Download timeout");
		}
		if(currentMote!=ALL)
			waitForCommands();
		else
			comm.getAddresses();
	}
	
	
	
	private void waitForCommands() {
		boolean shutdown=false;
		if(!welcomePrinted){
			welcomePrinted=true;
			console.printWelcome();
		}
		boolean exitCommandLoop=false;
		while(!exitCommandLoop){
			String command=console.readCommand();
			if(command.equals("motelist")){
				HashSet<Integer> motes=comm.getMotes();
				System.out.println("Known motes (downloaded data): ");
				for(Integer i:motes){
					try {
						long data=getWriter(i, writers).getMaxAddress()+1;
						System.out.print(i+" ("+data+");");
					} catch (IOException e) {
						System.out.print(i+" (N/A);");
					}
				}
				System.out.println();
			}else if(command.equals("discover")){
				for(DataWriter wr:writers){
					wr.close();
				}
				writers.clear();
				comm.discover(null);
				exitCommandLoop=true;
			}else if(command.equals("rediscover")){
				comm.discover(comm.getMotes());
				exitCommandLoop=true;
			}else if(command.startsWith("erase")){
				String[] splitted=command.split(" ");
				if(splitted.length!=2|| !splitted[1].toLowerCase().matches("all|[0-9]*")){
					console.printHelp("erase");
				} else {
					System.out.println("Sending erase command to mote. This could take a long time (30s).");
					if(splitted[1].toLowerCase().equals("all")){
						currentMote=-1*ALL;
						comm.sendErase();
					} else {
						currentMote=-1*Integer.parseInt(splitted[1]);
						comm.sendErase(Integer.parseInt(splitted[1]));
					}
					exitCommandLoop=true;
				}
			}else if(command.startsWith("download")){
				String[] splitted=command.split(" ");
				if(splitted.length!=2|| !splitted[1].toLowerCase().matches("all|[0-9]*")){
					console.printHelp("download");
				} else {
					if(splitted[1].toLowerCase().equals("all")){
						currentMote=ALL;
					} else {
						currentMote=Integer.parseInt(splitted[1]);						
					}
					comm.getAddresses();
					exitCommandLoop=true;
				}
			}else if(command.startsWith("command")){
				String[] splitted=command.split(" ");
				if(splitted.length<3|| !splitted[1].toLowerCase().matches("all|[0-9]*")|| !splitted[2].toLowerCase().matches("0x[0-9]*|[0-9]*")){
					console.printHelp("command");
				} else if((splitted.length==4)&& !splitted[3].toLowerCase().matches("0x[0-9]*|[0-9]*")){
					console.printHelp("command");
				}else {
					if(splitted[1].toLowerCase().equals("all")){
						currentMote=ALL;
					} else {
						currentMote=Integer.parseInt(splitted[1]);						
					}
					short cmd;
					if(splitted[2].toLowerCase().startsWith("0x"))
						cmd=Short.parseShort(splitted[2].substring(2),16);
					else
						cmd=Short.parseShort(splitted[2]);
					int argument=0;
					if(splitted.length==4){
						if(splitted[3].toLowerCase().startsWith("0x"))
							argument=Short.parseShort(splitted[3].substring(2),16);
						else
							argument=Short.parseShort(splitted[3]);
					}
					comm.sendUser(currentMote, cmd, argument);
					exitCommandLoop=true;
				}
			}else if(command.equals("quit")){
				if(timeSync.getLineNumber()==0){
					System.out.println("No timesync reference received yet! For correct timesync you need at least one!");
				} 
				System.out.println("Are you sure you want to quit?");
				String chr=console.readChar(new String[]{"y", "n"});
				if(chr.equals("y")){
					for(DataWriter writer:writers)
						writer.close();
					comm.stop();
					exitCommandLoop=true;
					shutdown=true;
				}

			} else {
				System.out.println("Unimplemented command.");
			}
		}
		if(shutdown)
			System.exit(0);//ugly, but it's a tinyos.jar bug
	}

	private static DataWriter getWriter(int nodeid, ArrayList<DataWriter> datawriters ){
		for(int i=0;i<datawriters.size();i++){
			if(datawriters.get(i).getNodeid()==nodeid){
				return datawriters.get(i);
			}
		}
		return null;	
	}
	
	public void newData(int nodeid, long address, byte[] data) {
		DataWriter writer=getWriter(nodeid, writers);
		if(writer==null){//create a new file
			writer=new DataWriter(nodeid);
			writers.add(writer);
		}
		
		try {//write
			long done=writer.writeData(address, data);
			done-=currently_handled.getMinAddress();
			//System.out.print(ProgressBar(currently_handled.getMaxAddress()-currently_handled.getMinAddress(),
			//							 done, writer.getMaxAddress()-writer.getGapCount(), writer.getGapPercent(), writer.getGapCount()));
			java.text.DecimalFormat floatformat = new java.text.DecimalFormat("####.##");
			String downloaded=floatformat.format((double)(writer.getMaxAddress()-writer.getGapCount())/1024);
			while(downloaded.length()<6)
				downloaded+=" ";
			console.setProgress(done, currently_handled.getMaxAddress()-currently_handled.getMinAddress()
					, ""+downloaded+" kiB"
					,"Gaps: "+writer.getGapPercent()+"% ("+writer.getGapCount()+")");
		} catch (IOException e) {
			System.err.println("Error: Can't write file "+DataWriter.nodeidToPath(writer.getNodeid(),".bin"));
		}
	}
	
	public void newTimeSync(Long moteTime, Integer bootCount, Long pcTime, Integer nodeId) {
		if(timeSync.isEmpty()){
			String[] header={"nodeId","local","localBootCount","remote","remoteBootCount","rssi","lqi"};
			timeSync.setHeader(header);
		}
		String line[]={nodeId.toString(), pcTime.toString(), "0", moteTime.toString(),
				bootCount.toString(),"0","0"};
		timeSync.addLine(line);
		try {
			timeSync.flush();
		} catch (IOException e) {
			System.err.println("Warning: Can't write timeSync file");
		}
	}	
	
	public static void main(String[] args){
		if(args.length==0)
			new StreamDownloader("sf@localhost:9002");
		else
			new StreamDownloader(args[0]);

			
	}


	
}
