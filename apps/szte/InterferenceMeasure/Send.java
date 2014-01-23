/*									tab:4
* Copyright (c) 2005 The Regents of the University  of California.  
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
* - Neither the name of the copyright holders nor the names of
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
*/

/**
* Java-side application for testing serial port communication.
* 
*
* @author Phil Levis <pal@cs.berkeley.edu>
* @date August 12 2005
*/

import java.io.IOException;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class Send {
	
	public static void main(String[] args) throws Exception {
		if (args.length != 7) {
			System.out.println("Usage:");
			System.out.println("Send <cw id 1> <cw id 2> <cw mode 1> <cw mode 2> <cw wait> <wait before cw> <wait before measure>");
			System.out.println("cw modes can be eighter + or -, wait times are in ms");
			System.exit(1);
		}
		
		PhoenixSource phoenix;
		
		phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);

		MoteIF mif = new MoteIF(phoenix);
		CommandMsg msg = new CommandMsg();
		msg.setElement_cw(0, Integer.parseInt(args[0]));
		msg.setElement_cw(1, Integer.parseInt(args[1]));
		if( args[2].equals("+") )
			msg.setElement_cwMode(0, (short)0xff);
		else
			msg.setElement_cwMode(0, (short)0);
		if( args[3].equals("+") )
			msg.setElement_cwMode(1, (short)0xff);
		else
			msg.setElement_cwMode(1, (short)0);
		msg.set_cwLength(Integer.parseInt(args[4]));
		msg.set_waitBeforeCw(Integer.parseInt(args[5]));
		msg.set_waitBeforeMeasure(Integer.parseInt(args[6]));
		try{
			mif.send(0xffff, msg);
		}	catch (IOException exception) {
			System.err.println("Exception thrown when sending packets. Exiting.");
			System.err.println(exception);
		}
		phoenix.shutdown();
	}


}
