/** Copyright (c) 2010, University of Szeged
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
* Author: Miklos Maroti
*/

package org.szte.wsn.echoranger;

import net.tinyos.packet.*;
import net.tinyos.util.PrintStreamMessenger;

public class EchoRanger implements PacketListenerIF
{
	protected java.text.SimpleDateFormat timestamp = new java.text.SimpleDateFormat("HH:mm:ss");

	static final int PACKET_LENGTH_FIELD = 5;
	static final int PACKET_TYPE_FIELD = 7;
	static final int PACKET_DATA_FIELD = 8;
	static final byte AM_ECHORANGER_MSG = (byte)0x77;
    
	protected PhoenixSource forwarder;
    
	public EchoRanger(PhoenixSource forwarder)
	{
		this.forwarder = forwarder;
			forwarder.registerPacketListener(this);
	}

	public void run()
	{
		forwarder.run();
	}

	public static void main(String[] args) throws Exception 
	{
		PhoenixSource phoenix = null;

		if( args.length == 0 )
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		else if( args.length == 2 && args[0].equals("-comm") )
			phoenix = BuildSource.makePhoenix(args[1], PrintStreamMessenger.err);
		else
		{
			System.err.println("usage: java TestFastSerial [-comm <source>]");
			System.exit(1);
		}

		EchoRanger listener = new EchoRanger(phoenix);
		listener.run();
	}

	boolean resync = false;
	int[] samples = new int[0];

	int getWord(byte[] packet, int index)
	{
		return (packet[index] & 0xFF) + ((packet[index+1] & 0xFF) << 8);
	}

	public void packetReceived(byte[] packet) 
	{
		if( packet[PACKET_TYPE_FIELD] != AM_ECHORANGER_MSG )
		{
			System.out.println("incorrect msg format");
			return;
		}
	
		int length = (getWord(packet, PACKET_LENGTH_FIELD) - 2) / 2;
		int start = getWord(packet, PACKET_DATA_FIELD);

		if( start != samples.length && resync == false )
		{
			System.out.println("missing samples");
			resync = true;
			samples = new int[0];
		}
		else if( start == samples.length )
			resync = false;

		int[] newSamples = new int[samples.length + length];
		System.arraycopy(samples, 0, newSamples, 0, samples.length);
		samples = newSamples;

		for(int i = 0; i < length; ++i)
			samples[start + i] = getWord(packet, PACKET_DATA_FIELD + 2 + 2*i);

		if( samples.length == 2000 )
		{
			report(samples);
			samples = new int[0];
		}
	}

	public void report(int[] samples)
	{
		System.out.print(timestamp.format(new java.util.Date()));
		for(int i = 0; i < samples.length; ++i)
			System.out.print("," + samples[i]);

		System.out.println();
	}
}
