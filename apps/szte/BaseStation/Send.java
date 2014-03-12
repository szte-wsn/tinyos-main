// $Id: Send.java,v 1.5 2010-06-29 22:07:42 scipio Exp $

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

import net.tinyos.util.*;
import net.tinyos.packet.*;
import java.io.*;

	class Message{
	//data
	public int sender_wait, receiver_wait, sender_send;
	public byte channel_mode;
	public byte trim1_trim2;
	public short sender1ID,sender2ID;
	
	public Message(){
		sender_wait = receiver_wait = sender_send = 0;
		channel_mode = trim1_trim2 = 0;
		sender1ID = sender2ID = 0;
	}

	public void set(long sender_wait_l, long receiver_wait_l, long sender_send_l,int 			channel_l, int mode_l, int trim1_l, int trim2_l, int sender1ID_l, int sender2ID_l)
	{
		this.sender_wait = (int)sender_wait_l;
		this.receiver_wait = (int)receiver_wait_l;
		this.sender_send = (int)sender_send_l;
		this.channel_mode = (byte)(channel_l<<3 & 0xF8); //5bit
		this.channel_mode |= (byte)((mode_l<<2)&0x04); //1bit
		this.trim1_trim2 = (byte)(trim2_l&0x000F);
		this.trim1_trim2 |= (byte)((trim1_l&0x000F)<<4);
		this.sender1ID = (short)sender1ID_l;
		this.sender2ID = (short)sender2ID_l;
	}

}

public class Send {
	static final int TRadioFreq = 625; /* *10^2 */
	static final int number_of_messages = 3;
	static final int header_length = 8;
	static final int config_length = 18;
	static final int data_length = number_of_messages*config_length; //54B
		//header
		static final byte AM_type_h = 0x00; 
		static final int Dest_address_h = 65535; //Broadcast 0xFFFF
		static final int Link_src_address_h = 256; //0x0100
		static final byte Data_length_h = data_length;
		static final int Group_ID_h = 0x22;
		static final int AM_handler_type_h = 0x06;
		//header
    public static void main(String[] argv) throws IOException
    {

	PacketSource sfw = BuildSource.makePacketSource();
	sfw.open(PrintStreamMessenger.err);
	byte[] packet = new byte[header_length+data_length]; //[header][data]
	Message[] msg = new Message[number_of_messages];
	for(int i=0;i<number_of_messages;i++){
		msg[i] = new Message();
	}
	if(argv.length % 9 == 0){
		for(int i=0;i<argv.length/9;i++){
		msg[i].set(		(Long.parseLong(argv[i*9+6])*TRadioFreq/10000),
						(Long.parseLong(argv[i*9+8])*TRadioFreq/10000),
						(Long.parseLong(argv[i*9+7])*TRadioFreq/10000),
						Integer.parseInt(argv[i*9+2]),
						(argv[i*9+3].equals("+"))?1:0,
						Integer.parseInt(argv[i*9+4]),
						Integer.parseInt(argv[i*9+5]),
						Integer.parseInt(argv[i*9+0]),
						Integer.parseInt(argv[i*9+1]));
		}
		/*if(argv.length >= 9){	
			msg[0].set(	Long.parseLong(argv[6]),
						Long.parseLong(argv[8]),
						Long.parseLong(argv[7]),
						Integer.parseInt(argv[2]),
						(argv[3].equals("+"))?1:0,
						Integer.parseInt(argv[4]),
						Integer.parseInt(argv[5]),
						Integer.parseInt(argv[0]),
						Integer.parseInt(argv[1]));
		}
		if(argv.length >= 18){	
			msg[1].set(	Long.parseLong(argv[15]),
						Long.parseLong(argv[17]),
						Long.parseLong(argv[16]),
						Integer.parseInt(argv[11]),
						(argv[12]=="+")?1:0,
						Integer.parseInt(argv[13]),
						Integer.parseInt(argv[14]),
						Integer.parseInt(argv[9]),
						Integer.parseInt(argv[10]));
		}
		if(argv.length >= 27){	
			msg[2].set(	Long.parseLong(argv[24]),
						Long.parseLong(argv[26]),
						Long.parseLong(argv[25]),
						Integer.parseInt(argv[20]),
						(argv[21]=="+")?1:0,
						Integer.parseInt(argv[22]),
						Integer.parseInt(argv[23]),
						Integer.parseInt(argv[18]),
						Integer.parseInt(argv[19]));
		}*/
		//Filling the packet:
		packet[0] = AM_type_h;
		packet[1] = (byte)Dest_address_h; 
		packet[2] = (byte)(Dest_address_h>>8);
		packet[3] = (byte)Link_src_address_h;
		packet[4] = (byte)(Link_src_address_h>>8);
		packet[5] = Data_length_h;
		packet[6] = Group_ID_h;
		packet[7] = AM_handler_type_h;
		//msg[i]
		int j=8;
		for(int i=0;i<number_of_messages;i++){
		packet[j++] = (byte)(msg[i].sender1ID>>8);
		packet[j++] = (byte)msg[i].sender1ID;
		packet[j++] = (byte)(msg[i].sender2ID>>8);
		packet[j++] = (byte)msg[i].sender2ID;
		packet[j++] = (byte)msg[i].channel_mode;
		packet[j++] = (byte)msg[i].trim1_trim2;
		packet[j++] = (byte)(msg[i].sender_wait>>24);
		packet[j++] = (byte)(msg[i].sender_wait>>16);
		packet[j++] = (byte)(msg[i].sender_wait>>8);
		packet[j++] = (byte)msg[i].sender_wait;
		packet[j++] = (byte)(msg[i].sender_send>>24);
		packet[j++] = (byte)(msg[i].sender_send>>16);
		packet[j++] = (byte)(msg[i].sender_send>>8);
		packet[j++] = (byte)msg[i].sender_send;
		packet[j++] = (byte)(msg[i].receiver_wait>>24);
		packet[j++] = (byte)(msg[i].receiver_wait>>16);
		packet[j++] = (byte)(msg[i].receiver_wait>>8);
		packet[j++] = (byte)msg[i].receiver_wait;
		}
		
		   

		try {
	    	sfw.writePacket(packet);
		}
		catch (IOException e) {
	    	System.exit(2);
		}
		Dump.printPacket(System.out, packet);
		System.out.println();
		System.exit(0);
		}else{
			System.out.println("java Send [T1sender1ID] [T1sender2ID] [T1channel] [T1+/-] [T1trim1] [T1trim2] [T1sender_wait] [T1sending_time] [T1receiver_wait] [T2sender1] [T2sender2] .... [T3receiver_wait]");
			System.exit(1);
		}
	}	
	
}    
