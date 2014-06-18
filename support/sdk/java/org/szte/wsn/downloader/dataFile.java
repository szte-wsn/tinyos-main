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

import java.io.*;
import java.util.*;

public class dataFile {
	RandomAccessFile dataFile;
	long maxaddress;
	int nodeid;
	private ArrayList<Gap> gaps = new ArrayList<Gap>();
	private File gapFile, timestamps; 

	public Byte[] readNextFrame(byte[] buffer, int i, byte frame, byte escape, byte xorescaped){
		if(i>=buffer.length)
			return null;
		while(buffer[i]!=frame||i>=buffer.length){//find the first framing byte
			i++;
			while(gaps.contains(i)){
				i++;
			}
		}
		while(buffer[i]==frame||i>=buffer.length){//if there's more than one framing byte next to each other, find the last
			i++;
			while(gaps.contains(i)){
				i++;
			}
		}
		//now in the buffer[i] we've got the fist byte of the real data (after the frame)
		ArrayList<Byte> onemeas=new ArrayList<Byte>();
		while(buffer[i]!=frame){
			if(gaps.contains(i)||i>=buffer.length)//if there is a gap in the middle of the frame, than drop it, try, the next frame
				return readNextFrame(buffer, i, frame, escape, xorescaped);
			if(buffer[i]==escape){
				i++;
				buffer[i]=(byte) (buffer[i]^xorescaped);
			}
			onemeas.add(buffer [i]);
			i++;
		}
		return (Byte[])(onemeas.toArray());
	}
	
	public ArrayList<Byte[]> getFrames(byte frame, byte escape, byte xorescaped) throws IOException{
		byte[] buffer=new byte[(int) dataFile.length()];//TODO: 2GB limit: is it a problem?
		synchronized (dataFile) {
			dataFile.seek(0);
			dataFile.readFully(buffer);
		}
		int pointer=0;
		ArrayList<Byte[]>ret=new ArrayList<Byte[]>();
		while(pointer<=dataFile.length()){
			Byte[] nextframe=readNextFrame(buffer, pointer, frame, escape, xorescaped);
			if(nextframe!=null)
				ret.add(nextframe);
		}
		return ret;
	}
	
	
	public File getTimestamps() {
		return timestamps;
	}
	
	public dataFile(String path) throws IOException{
		if(path.endsWith(".bin")){
			int nodeid=Integer.parseInt(path.substring(path.lastIndexOf('/')+1, path.lastIndexOf('.')));
			String dir=path.substring(0, path.lastIndexOf('/')+1);
			File file=new File(dir+dataWriter.nodeidToPath(nodeid, ".bin"));
			gapFile = new File(dir+dataWriter.nodeidToPath(nodeid, ".gap"));
			timestamps = new File(dir+dataWriter.nodeidToPath(nodeid, ".ts"));
			initDataFile(file, gapFile, timestamps, nodeid);
		} else
			throw new FileNotFoundException();
	}
	
	public dataFile(int nodeid) throws IOException{
		File file=new File(dataWriter.nodeidToPath(nodeid, ".bin"));
		gapFile = new File(dataWriter.nodeidToPath(nodeid, ".gap"));
		timestamps = new File(dataWriter.nodeidToPath(nodeid, ".ts"));
		initDataFile(file, gapFile, timestamps, nodeid);
	}
	

	private void initDataFile(File file, File gapfile, File timestamps, int nodeid) throws IOException{
		if(file.exists()){
			try {
				this.dataFile=new RandomAccessFile(file,"rwd");
			} catch (FileNotFoundException e) {
				// we just checked it, it exists
				e.printStackTrace();
			}
			this.nodeid=nodeid;
			System.out.print("Found datafile from #"+nodeid+". opening file:");
			maxaddress=dataFile.length()-1;
			System.out.print("maxaddress="+maxaddress);
			if(gapFile.exists()){
				BufferedReader input =  new BufferedReader(new FileReader(this.gapFile));
				String line=null;
				while (( line = input.readLine()) != null){
					System.out.print("\n New gap:"+line);
					String[] vars=line.split(" ");
					if(vars.length!=3){
						//TODO error handling
					}
					if(vars[2]=="T")
						addGap(Long.parseLong(vars[0]), Long.parseLong(vars[1]),true);
					else
						addGap(Long.parseLong(vars[0]), Long.parseLong(vars[1]),false);
				}
			}else {
				System.out.print("\nGapfile doesn't exist");
			if(!timestamps.exists())
				System.out.print("\nTimestamp file doesn't exist");
			}
			System.out.println("\nFile opened");
		}else {
			maxaddress = -1;
			this.nodeid = nodeid;
			try {
				dataFile = new RandomAccessFile(new File(String.valueOf(nodeid)+"data.bin"),"rwd");
			} catch (FileNotFoundException e) {
				// couldn't happen
				e.printStackTrace();
			}
			gapFile = new File(String.valueOf(nodeid)+"gaps.txt");
			timestamps = new File(String.valueOf(nodeid)+"timestamps.txt");
		}
	}
	
	public void addGap(long start, long end) {
		Gap newGap = new Gap();
		newGap.start = start;
		newGap.end = end;
		newGap.unrepairable = false;
		gaps.add(newGap);
		writeGapFile();
	}
	
	private void addGap(long start, long end, boolean unrepairable) {
		Gap newGap = new Gap();
		newGap.start = start;
		newGap.end = end;
		newGap.unrepairable = unrepairable;
		gaps.add(newGap);
		//writeGapFile();
	}

	public void removeGap(int index) {
		gaps.remove(gaps.get(index));
		writeGapFile();
	}
	
	
	public Long[] repairGap(long minaddr){
		Long[] ret=new Long[2];
		ret[0]=new Long(0);
		ret[1]=new Long(0);
		for(Gap repairGap:gaps){
			if(!repairGap.unrepairable){
				if(repairGap.end<minaddr){
					repairGap.unrepairable=true;
					writeGapFile();
				} else{
					ret[1]=repairGap.end;
					if(repairGap.start>=minaddr)
						ret[0]=repairGap.start;
					else
						ret[0]=minaddr;
					break;
				}
			}
		}
		return ret;
	}

	public Gap getGap(int index) {
		return gaps.get(index);
	}
	
	public int getGapNumber(){
		return gaps.size();
	}
	
	public HashSet<Long> getAllGap() {
		HashSet<Long> ret=new HashSet<Long>();
		for(Gap g:gaps){
			for(long i=g.start;i<=g.end;i++)
				ret.add(i);				
		}
		return ret;
	}
	
	private void writeGapFile(){
		try {
			Writer output = new BufferedWriter(new FileWriter(gapFile));
			for(Gap g:gaps){
				output.write(g.start + " " + g.end);
				if(g.unrepairable)
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
	
	public void close() throws IOException{
		writeGapFile();
		dataFile.close();
	}
	
	public static class Gap {
		long start, end;
		boolean unrepairable;
	}
}
