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
public class StructParser extends PacketParser {

	private PacketParser[] packetStruct;

	/**
	 * sets the name and packetStruct
	 * @param name of the PacketParser struct
	 * @param packetStruct array of PacketParsers
	 */
	public StructParser(String name, String type, PacketParser[] packetStruct){
		this.name=name;
		this.type=type;
		ArrayList<PacketParser> al=new ArrayList<PacketParser>();
		for(int i=0;i<packetStruct.length;i++){
			al.add(packetStruct[i]);
		}
		this.packetStruct=al.toArray(new PacketParser[al.size()]);
	}

	/**
	 * Calls parse for every PacketParser in the struct
	 */
	@Override
	public String[] parse(byte[] packet) {
		if((packet==null)||(packet.length!=getPacketLength()))
			return null;
		else{
			ArrayList<String> ret=new ArrayList<String>();		//temporary String[] to return;
			int pointer=0; 						//shows which is the first unprocessed byte
			for(PacketParser pp:packetStruct){  		
				byte[] packetPart=new byte[pp.getPacketLength()];				//bytes of one PacketParser			
				System.arraycopy(packet,pointer,packetPart,0,pp.getPacketLength());
				pointer+=pp.getPacketLength();

				if(!pp.getType().contains("omit")){			
					String[] temp=pp.parse(packetPart);
					if(temp!=null)
					ret.addAll(Arrays.asList(temp)); 	
					else
						return null;
					
				}

				if (pp.parse(packetPart)==null)
					return null;
			}
			return ret.toArray(new String[ret.size()]);
		}
	}
	@Override
	/**
	 * Calls getPacketLength for every PacketParser in the struct
	 */
	public int getPacketLength() {
		int ret=0;
		for(PacketParser pp:packetStruct)			//every PacketParser		
			ret+=pp.getPacketLength(); 	//omit takes no effect here

		return ret;
	}

	@Override
	/**
	 * Calls getFields for every PacketParser in the struct
	 * @return the names of the fields in String format
	 */
	public String[] getFields() {
		ArrayList<String> ret=new ArrayList<String>(); 

		for(PacketParser pp:packetStruct){  //every PacketParser
			if(!pp.getType().contains("omit"))
				ret.addAll(Arrays.asList(pp.getFields()));		//omitted fields won't be displayed
		}
		return ret.toArray(new String[ret.size()]);
	}

	@Override
	/**
	 * Calls construct for every PacketParser in the struct
	 * @return the values of the String[] in byte[] format
	 */
	public byte[] construct(String[] stringValue) {
		ArrayList<Byte> ret=new ArrayList<Byte>(); 
		int pointer=0;
		for(PacketParser pp:packetStruct){ 	 //every PacketParser	
			if(!pp.getType().contains("omit"))  		//omitted 
			{
				String[] packetPart=new String[pp.getFields().length];				//String of one PacketParser			
				System.arraycopy(stringValue ,pointer,packetPart,0,pp.getFields().length);
				pointer+=pp.getFields().length;
				if(pp.construct(packetPart)!=null)
					for(byte b:pp.construct(packetPart))
						ret.add(b); 
			}
			else 
				if(pp instanceof ConstParser ){
					for(byte b:pp.construct(pp.parse(((ConstParser) pp).getValue())))
						ret.add(b); 
				} 
		}

		byte[] byteArray = new byte[ret.size()];
		for(int i = 0; i<ret.size(); i++){
			byteArray[i] = ret.get(i);
		}

		return byteArray;
	}

}
