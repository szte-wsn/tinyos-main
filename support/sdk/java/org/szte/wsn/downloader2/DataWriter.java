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

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Date;

import org.szte.wsn.dataprocess.file.Gap;
import org.szte.wsn.dataprocess.file.GapConsumer;


public class DataWriter {
	private ArrayList<Gap> gaps = new ArrayList<Gap>();
	private RandomAccessFile dataFile;
	private File gapFile, timestamps; 
	private int nodeid;
	private long lastModified;

	public static String nodeidToPath(Integer nodeid,String postfix){
		String path=nodeid.toString();
		while (path.length()<5) {
			path='0'+path;
		}
		return path+postfix;
	}
	
	public DataWriter(int nodeid){
		GapConsumer gapc;
		try {
			gapc = new GapConsumer(nodeidToPath(nodeid,".gap"));
			gaps=gapc.getGaps();
			gapFile=gapc.getGapFile();
			dataFile=new RandomAccessFile(nodeidToPath(nodeid,".bin"),"rws");
		} catch (FileNotFoundException e) {
			gaps=new ArrayList<Gap>();
			gapFile=new File(nodeidToPath(nodeid,".gap"));
			try {
				dataFile=new RandomAccessFile(new File(nodeidToPath(nodeid,".bin")),"rws");
			} catch (FileNotFoundException e1) {
				//We just created that file, it should be there 
			}
		}
		this.nodeid=nodeid;
		timestamps=new File(gapFile.getName().substring(0,gapFile.getName().lastIndexOf('.'))+".ts");
	}
	
	public long writeData(long offset, byte[] data) throws IOException{
		long prevMaxAddress=getMaxAddress();
		dataFile.seek(offset);
		dataFile.write(data, 0, data.length);//TODO: 2GB limit
		setLastModified();
		
//		if(offset==prevMaxAddress+1){//the next bytes
//			System.out.println("Data OK");
//		} else 
		if(offset>prevMaxAddress+1){//we missed some data
			addGap(prevMaxAddress+1, offset-1);
		} else { //we fill a gap
			for(Gap currentGap:gaps){
				if(!currentGap.isUnrepairable()){
					if(((currentGap.getStart()<offset+data.length)&&(currentGap.getStart()>=offset))||
						((currentGap.getEnd()>=offset)&&(currentGap.getEnd()<offset+data.length))){
						long start_bef,end_bef,start_aft,end_aft;
						start_bef=currentGap.getStart();
						end_bef=offset-1;
						start_aft=offset+data.length;
						end_aft=currentGap.getEnd();
//						ret+=("Remove gap: " + currentGap.getStart()+"-"+currentGap.getEnd());
						removeGap(currentGap);
						if(end_bef>start_bef){//we didn't fill the whole gap
//							ret+="|New gap: " + start_bef + "-" + end_bef;
							addGap(start_bef, end_bef);
						}
						if(end_aft>start_aft){//we didn't fill the whole gap
//							ret+="|New gap: " + start_aft + "-" + end_aft;
							addGap(start_aft, end_aft);
						}
						break;
					}
				}
			}
		}
		return offset+data.length;
	}
	
	public long writeData(byte[] data) throws IOException{
		return writeData(dataFile.length()-1, data);
	}
	
	private void writeGapFile(){
		try {
			Writer output = new BufferedWriter(new FileWriter(gapFile));
			for(Gap g:gaps){
				output.write(g.getStart() + " " + g.getEnd());
				if(g.isUnrepairable())
					output.write(" T\n");
				else
					output.write(" F\n");
			}
			output.flush();
			output.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	public void addTimeStamp(long local, long remote){
		try {
			Writer output = new BufferedWriter(new FileWriter(timestamps,true));
			output.write(local+":"+remote+"\n");
			output.flush();
			output.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	private void addGap(long start, long end) {
		gaps.add(new Gap(start,end,false));
		writeGapFile();
	}
 
	private void removeGap(Gap remove) {
		gaps.remove(remove);
		writeGapFile();
	}
	
	
	public Gap repairGap(long minaddr){
		Gap ret=new Gap(0,0);
		for(Gap repairGap:gaps){
			if(!repairGap.isUnrepairable()){
				if(repairGap.getEnd()<minaddr){
					repairGap.setUnrepairable(true);
					writeGapFile();
				} else{
					ret.setEnd(repairGap.getEnd());
					if(repairGap.getStart()>=minaddr)
						ret.setStart(repairGap.getStart());
					else
						ret.setStart(minaddr);
					break;
				}
			}
		}
		if(ret.getEnd()==ret.getStart())
			return null;
		else
			return ret;
	}
	
	public float getGapPercent(){
		long gapbyte=0;
		for(Gap current:gaps){
			gapbyte+=current.getEnd()-current.getStart();
		}
		try {
			return 100*gapbyte/(getMaxAddress()+1);
		} catch (IOException e) {
			return -1;
		}
	}
	
	public long getGapCount(){
		long gapbyte=0;
		for(Gap current:gaps){
			gapbyte+=current.getEnd()-current.getStart();
		}
		return gapbyte;
	}
	
	public void close(){
		boolean delete=false;
		try{
			if(dataFile.length()==0)
				delete=true;
		}catch(IOException e){
			System.err.println("Can't write file: "+nodeidToPath(nodeid,".bin"));
		}
		try{
			dataFile.close();
		} catch(IOException e){
			System.err.println("Can't close file: "+nodeidToPath(nodeid,".bin"));
		}
		if(delete)
			if(!new File(nodeidToPath(nodeid,".bin")).delete())
				System.err.println("Can't delete file: "+nodeidToPath(nodeid,".bin"));
	}
	
	public void finalize(){
		close();
	}

	public int getNodeid() {
		return nodeid;
	}
	
	public long getMaxAddress() throws IOException {
		return dataFile.length()-1;
	}
	
	public long getLastModified() {
		return lastModified;
	}
	
	public void setLastModified() {
		this.lastModified=new Date().getTime();
	}

	public void erase() throws IOException{
		gapFile.delete();
		timestamps.delete();
		try {
			dataFile.setLength(0);
		} catch (IOException e) {
			throw e;
		}
	}

}
