// $Id: Listen.java,v 1.5 2010-06-29 22:07:41 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


import java.io.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class Listen {

	public static void printByte(PrintStream p, int b) {
	String bs = Integer.toHexString(b & 0xff).toUpperCase();
	if (b >=0 && b < 16)
	    p.print("0");
	p.print(bs + " ");
    }

public static void printPacketTimeStamp(PrintStream p, byte[] packet){
		p.print("AM type: "+(int)(packet[0] & 0xFF)+" \n");
		p.print("Destination address:");
		int a1 = packet[1] & 0xFF;
		int a2 = packet[2] & 0xFF;
		a2<<=8;
		a1 = (a1 | a2) & 0x0000FFFF;
		p.print(a1+" \n");
		p.print("Link source address:");
		a1 = packet[3] & 0xFF;
		a2 = packet[4] & 0xFF;
		a2<<=8;
		a1 = (a1 | a2) & 0x0000FFFF;
		p.print(a1+" \n");
		int len = (int)(packet[5] & 0xFF);
		p.print("Message length "+len+" \n");
		p.print("Group ID: "+(int)(packet[6] & 0xFF)+" \n");
		p.print("AM handler type: "+(int)(packet[7] & 0xFF)+" \n");
		p.print("Data:");
		for(int i=8;i<8+len-4;i++){
			printByte(p, packet[i]);
		}
		p.print(" \n");
		long b1 = packet[8+len-4] & 0xFF;
		long b2 = packet[8+len-3] & 0xFF;
		b2 <<= 8;
		long b3 = packet[8+len-2] & 0xFF;
		b3 <<= 16;
		long b4 = packet[8+len-1] & 0xFF;
		b4 <<= 24;
		b1 = (((b1 | b2) | b3) | b4) & 0x00000000FFFFFFFF; 
		p.print("Timestamp: "+b1+" \n");
	}

    public static void main(String args[]) throws IOException {
        String source = null;
        PacketSource reader;
        if (args.length == 2 && args[0].equals("-comm")) {
          source = args[1];
        }
	else if (args.length > 0) {
	    System.err.println("usage: java net.tinyos.tools.Listen [-comm PACKETSOURCE]");
	    System.err.println("       (default packet source from MOTECOM environment variable)");
	    System.exit(2);
	}
        if (source == null) {	
  	  reader = BuildSource.makePacketSource();
        }
        else {
  	  reader = BuildSource.makePacketSource(source);
        }
	if (reader == null) {
	    System.err.println("Invalid packet source (check your MOTECOM environment variable)");
	    System.exit(2);
	}

	try {
	  reader.open(PrintStreamMessenger.err);
	  for (;;) {
	    byte[] packet = reader.readPacket();
	    printPacketTimeStamp(System.out, packet);
	    System.out.println();
	    System.out.flush();
	  }
	}
	catch (IOException e) {
	    System.err.println("Error on " + reader.getName() + ": " + e);
	}
    }
}

