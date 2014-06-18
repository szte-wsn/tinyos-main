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
 * Author:Miklos Toth
 */
package org.szte.wsn.dataprocess.parser;

import java.util.ArrayList;
import java.util.Arrays;
import org.szte.wsn.dataprocess.PacketParser;


/**
 * 
 * PacketParser implementation of PacketParser arrays
 * @author Miklos Toth
 *
 */
public class ArrayParser extends PacketParser{
	int size;
	PacketParser packetType;		//the type of PacketParser array
	
	/**
	 * sets the size of the new PacketParser array, and creates a sample PacketParser
	 * @param packetType the type of PacketParser array
	 * @param size of the array
	 */
	public ArrayParser(PacketParser packetType,  int size){		
		this.size=size;
		this.packetType= packetType;
		this.name=packetType.getName();
		this.type=packetType.getType();
	}
	
	@Override
	/**
	 * parses the byte[] into String[] calls the parser of the packetType
	 * for every byte package
	 * @param byte[]
	 * @return String[]
	 */
	public String[] parse(byte[] packet) {
		String[] ret=new String[size];

		for(int i=0;i<size;i++){
			byte[] packetPart =new byte[packetType.getPacketLength()];
			System.arraycopy(packet, i*packetType.getPacketLength(), packetPart, 0, packetType.getPacketLength());						
			ret[i]=packetType.parse(packetPart)[0];
			}
		
		return ret;
	}

	@Override
	/**
	 * @return the size of this Packet in bytes
	 */
	public int getPacketLength() {
			return packetType.getPacketLength()*size;
	}

	@Override
	/**
	 * returns the type of the fields "size" times, instead of the names,
	 * array elements don't have unique names
	 */
	public String[] getFields() {
		ArrayList<String> ret=new ArrayList<String>(); 		//temporary String[] to return;
		
		for(int i=0;i<size;i++){
			ret.addAll(Arrays.asList(packetType.getFields()));		
			ret.set(ret.size()-1,ret.get(ret.size()-1)+"["+i+"]");  //adds [i] tag to the end of the String
		}
		
		return ret.toArray(new String[ret.size()]);
	}

	@Override
	/**
	 * Calls construct for every PacketParser in the array
	 * @return the values of the String[] in byte[] format
	 */
	public byte[] construct(String[] stringValue) {
		byte[] ret = new byte[packetType.getPacketLength()*size];
		int pointer=0;
		int length=packetType.getFields().length;
		for(int i=0;i<size;i++){ 			 //every PacketParser			
			String[] packetPart=new String[length];				//String of one PacketParser			
			System.arraycopy(stringValue ,pointer,packetPart,0,length);
			for(int j=0; j<packetType.construct(packetPart).length;j++)
				ret[i*size+j]=packetType.construct(packetPart)[j]; 	
			pointer+=length;
		}		    
		return ret;
	}


}