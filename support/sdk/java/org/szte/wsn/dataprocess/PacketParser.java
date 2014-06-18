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
package org.szte.wsn.dataprocess;

/**
 * abstract class, with necessary methods and fields
 * for the packet parsing
 */
public abstract class PacketParser{
	protected String name;
	protected String type;
	
	/**
	 * 
	 * @return the type of the PacketParser 
	 */
	public String getType() {
		return type;
	}

	/**
	 * 
	 * @return the name of the PacketParser
	 */
	public String getName() {
		return name;
	}
	
	/**
	 * 
	 * @param packet parses the pocket byte array into String array
	 * @return the data in String form
	 */
	public abstract String[] parse(byte[] packet);
	
	/**
	 * constructs byte[] from String values
	 * @param stringValue String[]
	 * @return the data in byte form
	 */
	public abstract byte[] construct(String[] stringValue);
	
	/**
	 * 
	 * @return the length of the packet in bytes 
	 */
	public abstract int getPacketLength();
	
	
	/**
	 * 
	 * @return the names of the fields in String format
	 */
	public abstract String[] getFields();

}