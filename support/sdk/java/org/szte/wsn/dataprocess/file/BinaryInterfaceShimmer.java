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
 * Author: Miklos Toth
 */
package org.szte.wsn.dataprocess.file;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;

import org.szte.wsn.dataprocess.BinaryInterface;

public class BinaryInterfaceShimmer implements BinaryInterface{
	private File dataFile;
	private ArrayList<byte[]>frames=new ArrayList<byte[]>();
	private FileInputStream filereader;
	private int actualFrame;
	private byte[] formatId;
	byte[] header;
	

	public BinaryInterfaceShimmer(String path){
		this.dataFile=new File(path);
		try {
			this.filereader=new FileInputStream(dataFile);
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		frames=	makeFrames();
		formatId=new byte[2];
		System.arraycopy(header, 0, formatId, 0, 2);
		actualFrame=0;		
	}

	public ArrayList<byte[]> makeFrames(){
		byte[] buffer=new byte[512];  
		
		try {
			if (filereader.read(buffer)<512)
				return null;
			
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}	
		
		final int headerLength=6;
		header=new byte[headerLength];
		System.arraycopy(buffer,0,header,0,headerLength);
		int offset=headerLength;
		ArrayList<byte[]>ret=new ArrayList<byte[]>();
		for(int i=0;i<23;i++){
			byte[] nextFrame = new byte[22+headerLength];
			System.arraycopy(header, 0, nextFrame, 0, headerLength);
			System.arraycopy(buffer, offset, nextFrame, headerLength, 22);
			offset+=22;
			
			ret.add(nextFrame);
		}
		return ret;
	}

	@Override
	public byte[] readPacket() {
		if (actualFrame<frames.size())			
			return frames.get(actualFrame++);	
		else
		{
			frames=makeFrames();
			actualFrame=0;
			if(!Arrays.equals(formatId,new byte[]{header[0],header[1]}))
				return null;
			if (frames!=null)
				return frames.get(actualFrame++);
			else
				return null;
		}
			
	}

	@Override
	public void writePacket(byte[] frames) {
		// TODO Auto-generated method stub

	}


}
