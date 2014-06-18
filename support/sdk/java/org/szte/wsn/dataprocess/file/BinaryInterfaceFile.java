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
* Author:Andras Biro, Miklos Toth
*/
package org.szte.wsn.dataprocess.file;


import java.io.IOException;
import java.io.RandomAccessFile;
import java.util.ArrayList;

import org.szte.wsn.dataprocess.BinaryInterface;
import org.szte.wsn.dataprocess.Transfer;


public class BinaryInterfaceFile implements BinaryInterface{
	private RandomAccessFile dataFile;
	private ArrayList<Gap> gaps = new ArrayList<Gap>();    
	private int offset;
	private byte frame;
	private byte escape;
	private byte xorescaped;
	private byte[] buffer;
	
	/**
	 * 
	 * @param path binary file path
	 * @param gaps ArrayList of gaps
	 * @param frame byte code of the frame border
	 * @param escape byte code of the escaping
	 * @param xorescaped byte code of the xor
	 */
	public BinaryInterfaceFile(String path, ArrayList<Gap> gaps, byte frame, byte escape, byte xorescaped){
			this.gaps=gaps;			
			this.frame=frame;
			this.escape=escape;
			this.xorescaped=xorescaped;
			
			offset=0;
			initDataFile(path);		
	}
	
	/**
	 * 
	 * @param path binary file path
	 * @param gaps ArrayList of gaps
	 */
	public BinaryInterfaceFile(String path,ArrayList<Gap> gaps){
		this(path,gaps,(byte)0x5e,(byte)0x5d,(byte)0x20);		
	}
	
	@Override
	/**
	 * reads one frame from the binary file
	 */
	public byte[] readPacket(){		
		if(offset>=buffer.length)
			return null;
		try{
			while(buffer[offset]!=frame||offset>=buffer.length){//find the first framing byte
				offset++;
				while(gaps.contains(offset)){
					offset++;
				}
			}
			while(buffer[offset]==frame||offset>=buffer.length){//if there's more than one framing byte next to each other, find the last
				offset++;
				while(gaps.contains(offset)){
					offset++;
				}
			}
			//now in the buffer[offset] we've got the first byte of the real data (after the frame)
			ArrayList<Byte> onemeas=new ArrayList<Byte>();
			while(buffer[offset]!=frame){
				if(gaps.contains(offset)||offset>=buffer.length)//if there is a gap in the middle of the frame, than drop it, try, the next frame
					return readPacket();
				if(buffer[offset]==escape){
					offset++;
					buffer[offset]=(byte) (buffer[offset]^xorescaped);
				}
				onemeas.add(buffer [offset]);
				offset++;
			}
			byte[] ret=new byte[onemeas.size()];
			for(int j=0;j<ret.length;j++){
				ret[j]=onemeas.get(j);
			}
			return ret;
		} catch(IndexOutOfBoundsException e){
			return null;			
		}
		
	}

	/**
	 * 
	 * @param path binary file path
	 */
	private void initDataFile(String path){
		try {
			dataFile=new RandomAccessFile(path, "rw");
			buffer=new byte[(int) dataFile.length()];//TODO: 2GB limit: is it a problem?
			dataFile.readFully(buffer);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			System.out.println("Binary file could not open/create.");
			e.printStackTrace();
			Transfer.usageThanExit();
		}	;	
	}		

	@Override
	/**
	 * writes one frame to the binary file
	 */
	public void writePacket(byte[] frames) {
		try {
			dataFile.seek(dataFile.length());
			ArrayList<Byte> tmp=new ArrayList<Byte>();
			tmp.add(frame);
			for(byte part:frames)
				if((part==frame)||(part==escape)){
					tmp.add(escape);
					tmp.add((byte)(part ^ xorescaped));
					}
				else
					tmp.add(part);
			tmp.add(frame);
			Byte[] ret1= tmp.toArray(new Byte[tmp.size()]);
			byte[] ret2=new byte[ret1.length];
			for(int i=0;i<ret1.length;i++ )
				ret2[i]=ret1[i].byteValue();				
			dataFile.write(ret2);
			
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
	}

	public RandomAccessFile getDataFile() {
		return dataFile;
	}



}