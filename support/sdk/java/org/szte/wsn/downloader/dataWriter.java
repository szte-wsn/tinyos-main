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

public class dataWriter {
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
	
	public dataWriter(int nodeid, byte frame, byte escape, byte xorescaped) throws IOException{
		GapConsumer gapc;
		try {
			gapc = new GapConsumer(nodeidToPath(nodeid,".gap"));
			gaps=gapc.getGaps();
			gapFile=gapc.getGapFile();
			dataFile=new RandomAccessFile(nodeidToPath(nodeid,".bin"),"rws");
		} catch (FileNotFoundException e) {
			gaps=new ArrayList<Gap>();
			gapFile=new File(nodeidToPath(nodeid,".gap"));
			dataFile=new RandomAccessFile(new File(nodeidToPath(nodeid,".bin")),"rws");
		}
		this.nodeid=nodeid;
		timestamps=new File(gapFile.getName().substring(0,gapFile.getName().lastIndexOf('.'))+".ts");
	}
	
	public void writeData(long offset, int length, byte[] data) throws IOException{
		dataFile.seek(offset);
		dataFile.write(data, 0, length);//TODO: 2GB limit
		lastModified=new Date().getTime();
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
	
	public void addGap(long start, long end) {
		gaps.add(new Gap(start,end,false));
		writeGapFile();
	}
 
	public void removeGap(Gap remove) {
		gaps.remove(remove);
		writeGapFile();
	}
	
	
	public Long[] repairGap(long minaddr){
		Long[] ret=new Long[2];
		ret[0]=new Long(0);
		ret[1]=new Long(0);
		for(Gap repairGap:gaps){
			if(!repairGap.isUnrepairable()){
				if(repairGap.getEnd()<minaddr){
					repairGap.setUnrepairable(true);
					writeGapFile();
				} else{
					ret[1]=repairGap.getEnd();
					if(repairGap.getStart()>=minaddr)
						ret[0]=repairGap.getStart();
					else
						ret[0]=minaddr;
					break;
				}
			}
		}
		return ret;
	}
	
	public void close() throws IOException{
		dataFile.close();
	}
	
	public void finalize(){
		try {
			close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public int getNodeid() {
		return nodeid;
	}
	
	public long getMaxAddress() throws IOException {
		return dataFile.length()-1;
	}
	
	public ArrayList<Gap> getGaps() {
		return gaps;
	}
	
	public long getLastModified() {
		return lastModified;
	}
	
	public void setLastModified(long lastModified) {
		this.lastModified=lastModified;
	}

}
