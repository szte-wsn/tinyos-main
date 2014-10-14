/*
 * Copyright (c) 2003-2007, Vanderbilt University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * Author: Miklos Maroti
 */
import net.tinyos.packet.*;
import net.tinyos.util.PrintStreamMessenger;

public class PackageDispatcher implements PacketListenerIF {
	static final int PACKET_TYPE_FIELD = 7;
	static final int PACKET_TS_AM_FIELD = 5; // end-PACKET_TS_AM_FIELD
	static final int PACKET_LENGTH_FIELD = 5;
	static final int PACKET_DATA_FIELD = 8;
	static final int PACKET_CRC_SIZE = 0;
	static final byte AM_TIMESYNC_MSG = (byte) 0x3d;
	static final byte AM_SYNC_MSG = (byte) 0x06;
	static final byte AM_WAVE_MSG = (byte) 0x06;

	protected PhoenixSource forwarder;

	public PackageDispatcher(PhoenixSource forwarder) {
		this.forwarder = forwarder;
		forwarder.registerPacketListener(this);
	}

	public void run() {
		forwarder.run();
	}

	public static void main(String[] args) throws Exception {
		PhoenixSource phoenix = null;

		if (args.length == 0)
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		else if (args.length == 2 && args[0].equals("-comm"))
			phoenix = BuildSource.makePhoenix(args[1], PrintStreamMessenger.err);
		else {
			System.err.println("usage: PackageDispatcher [-comm <source>]");
			System.exit(1);
		}

		PackageDispatcher listener = new PackageDispatcher(phoenix);
		listener.run();
	}

	public void packetReceived(byte[] packet) {
		if (packet[PACKET_TYPE_FIELD] == AM_TIMESYNC_MSG) {
			int head = PACKET_DATA_FIELD;
			int end = PACKET_DATA_FIELD + packet[PACKET_LENGTH_FIELD];
			if (packet[end - PACKET_TS_AM_FIELD] == AM_SYNC_MSG) {
				//jött egy sync
			}
		} else if (packet[PACKET_TYPE_FIELD] == AM_WAVE_MSG) {
			//jött egy wavepart
		}
	}

}
