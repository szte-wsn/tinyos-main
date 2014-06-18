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

import org.szte.wsn.dataprocess.PacketParser;

public class IntegerParser extends PacketParser{
	int size;
	boolean isLittleEndian=false;
	boolean signed; 
	
	/**
	 * sets the flags according to the type
	 * sets the size according to the type
	 * @param name integer variable name
	 * @param type integer variable type
	 */
	public IntegerParser(String name, String type){
		this.name=name;
		this.type=type;
		isLittleEndian=type.startsWith("nx_le");
		signed=!type.contains("uint");
		if(this.type.contains("int8_t")){
			size=1;
		}
		else if(this.type.contains("int16_t")){
			size=2;
		}
		else
			size=4;
		
	}
	
	/**
	 * @return the value of the integer
	 */
	protected long byteToLong(byte[] packet)
	{						//TODO check size
		long ret = 0;
		
		for(int i = 0; i < packet.length; ++i)
		{
			long a = packet[isLittleEndian ? i : packet.length-1-i];

			if( !signed || i < packet.length - 1 )
					a &= 0xFF;

			a <<= (i<<3);
			ret |= a;
		}
		
		return ret;
	}
	
	@Override
	/**
	 * @return the value of the integer at the first place of the String array
	 */
	public String[] parse(byte[] packet)
	{	
		return new String[] { Long.toString(byteToLong(packet)) };
	}
	
	
	/**
	 * constructs byte[] from a number
	 * @param longValue constructs byte[] from it 
	 * @return byte[]
	 */
	protected byte[] longToByte(long longValue)
	{
		byte [] b = new byte[size];
		
		for(int i= 0; i < size; i++)
		{
			b[isLittleEndian ? i : size-1-i] = (byte)((longValue >> (i * 8))& 0xFF);
		}
		return b;
	}
	
	/**
	 * constructs byte[] from a number represented in String
	 * @param stringValue constructs byte[] from it 
	 * @return byte[]
	 */
	public byte[] construct(String[] stringValue)
	{
		long longValue=Long.decode(stringValue[0]);
		
		return longToByte(longValue);
			
	}
	
	
	@Override
	/**
	 * @return the size of the integer
	 */
	public int getPacketLength() {
		
		return size; 
	}

	@Override
	/**
	 * @return name
	 */
	public String[] getFields() {
		return new String[] {name};
	}
	
}