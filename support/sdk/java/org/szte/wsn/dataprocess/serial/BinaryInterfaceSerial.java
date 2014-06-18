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
* Author: Andras Biro
*/
package org.szte.wsn.dataprocess.serial;

import java.io.IOException;
import java.util.ArrayList;

import org.szte.wsn.dataprocess.BinaryInterface;

import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PacketListenerIF;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;

/**
 * 
 * @author Andras Biro
 * BinaryInterface implementation for serial port communication
 */
public class BinaryInterfaceSerial implements BinaryInterface{
	
	private PhoenixSource phoenix;
	private ArrayList<byte[]> readbuffer=new ArrayList<byte[]>();
	
	public class Listener implements PacketListenerIF{
		@Override
		public void packetReceived(byte[] packet) {
			synchronized (readbuffer) {
				readbuffer.add(packet);
				readbuffer.notify();
			}
		}		
	}
	
	public BinaryInterfaceSerial(String source){
		//TODO: Maybe we should process the error messages
		if (source == null) {
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		} else {
			phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
		}
		phoenix.registerPacketListener(new Listener());		
		phoenix.setResurrection();
		phoenix.start();
	}
	
	
	public BinaryInterfaceSerial(){
		new BinaryInterfaceSerial(null);
	}

	@Override
	public byte[] readPacket() {
		synchronized (readbuffer) {
			while(readbuffer.isEmpty()){
				try {
					readbuffer.wait();
				} catch (InterruptedException e) {
					return null;
				}
			}
			return readbuffer.remove(0);
		}
	}

	@Override
	public void writePacket(byte[] frame) throws IOException {
		phoenix.writePacket(frame);
		
	}
	
}
