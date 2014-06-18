import net.tinyos.util.*;
import net.tinyos.packet.*;

import java.io.*;

class MessageElement {
	private static final int HEADER_LENGTH = 8;
	private static final int PAYLOAD_LENGTH = 15;

	private long wait;
	private int sender1ID, sender2ID, measureID;
	private short channel, power1, power2;
	private byte finetune1, finetune2;

	public MessageElement(int sender1ID, int sender2ID, short channel, byte finetune1, byte finetune2,
			short power1, short power2,	long wait, int measureID) {
		this.wait = wait;
		this.channel = channel;
		this.finetune1 = finetune1;
		this.finetune2 = finetune2;
		this.power1 = power1;
		this.power2 = power2;
		this.sender1ID = sender1ID;
		this.sender2ID = sender2ID;
		this.measureID = measureID;
	}

	public byte[] getByteArray() {
		// This is the actual message
		// typedef nx_struct config_msg_t {
		// nx_uint16_t Tsender1ID;
		// nx_uint16_t Tsender2ID;
		// nx_uint8_t Tchannel;
		// nx_int8_t Tfinetune1;
		// nx_int8_t Tfinetune2;
		// nx_uint8_t Tpower1;
		// nx_uint8_t Tpower2;
		// nx_uint32_t Tsender_wait;
		// nx_uint16_t measureId;
		// } config_msg_t;
		ByteArrayOutputStream bos = new ByteArrayOutputStream();
		DataOutputStream dos = new DataOutputStream(bos);
		try {
			dos.writeShort((short) sender1ID);
			dos.writeShort((short) sender2ID);
			dos.writeByte((byte) channel);
			dos.writeByte(finetune1);
			dos.writeByte(finetune2);
			dos.writeByte((byte) power1);
			dos.writeByte((byte) power2);
			dos.writeInt((int) wait);
			dos.writeShort((short) measureID);
			dos.close();
		} catch (IOException e) {
			System.err.println("Couldn't write outputstream, exiting");
			e.printStackTrace();
			System.exit(1);
		}
		return bos.toByteArray();
	}
	
	private static byte[] generateHeader(int length){
		byte[] packet = new byte[8];
		packet[0] = 0; //AM 
		packet[1] = (byte) 0xff; //destination: broadcast
		packet[2] = (byte) 0xff; //destination: broadcast
		packet[3] = 0; //source: 0 (doesn't matter)
		packet[4] = 0; //source: 0 (doesn't matter)
		packet[5] = (byte)length;
		packet[6] = 0x22; //group id
		packet[7] = 20; //am type
		return packet;
	}
	
	
	public static byte[] generateMessage(MessageElement elements[]){
		byte[] packet = new byte[HEADER_LENGTH+PAYLOAD_LENGTH*elements.length];
		int offset = 0;
		byte[] nextElement = generateHeader(PAYLOAD_LENGTH*elements.length);
		for(int i=0;i<nextElement.length;i++){
			packet[i+offset] = nextElement[i];
		}
		offset+=nextElement.length;
		for(MessageElement element: elements){
			nextElement = element.getByteArray();
			for(int i=0;i<nextElement.length;i++){
				packet[i+offset] = nextElement[i];
			}
			offset+=nextElement.length;
		}
		return packet;
	}

}

public class Send {
	static final int DATA_PER_MESSAGE = 9;
	static final int TRadioFreq = 625; /* *10^2 */
	
	public static void usageAndExit(int exitCode){
		System.err.println("usage: SendMessage [T1sender1ID] [T1sender2ID] [T1channel] [T1finetune1] [T1finetune2] [T1power1] [T1power2] [T1wait] [T1measureId] [T2sender1] [T2sender2] .... [TNwait]");
		System.exit(exitCode);
	}

	// header
	public static void main(String[] argv) {
		if( argv.length == 0 || argv.length % DATA_PER_MESSAGE != 0 ){
			usageAndExit(1);
		}
		MessageElement[] messages = new MessageElement[argv.length/9];
		for (int i = 0; i < argv.length / DATA_PER_MESSAGE; i++) {
			try{
				messages[i] = new MessageElement(Integer.parseInt(argv[i * DATA_PER_MESSAGE + 0]),
												 Integer.parseInt(argv[i * DATA_PER_MESSAGE + 1]),
												 Short.parseShort(argv[i * DATA_PER_MESSAGE + 2]),
												 Byte.parseByte(argv[i * DATA_PER_MESSAGE + 3]),
												 Byte.parseByte(argv[i * DATA_PER_MESSAGE + 4]),
												 Short.parseShort(argv[i * DATA_PER_MESSAGE + 5]),
												 Short.parseShort(argv[i * DATA_PER_MESSAGE + 6]),
												 Long.parseLong(argv[i * DATA_PER_MESSAGE + 7]) * TRadioFreq / 10000,
												 Integer.parseInt(argv[i * DATA_PER_MESSAGE + 8]));
			} catch(NumberFormatException e){
				usageAndExit(1);
			}
		}
		byte[] packet = MessageElement.generateMessage(messages);
// 		Dump.printPacket(System.out, packet);System.out.println();
		PacketSource sfw = BuildSource.makePacketSource();
		try {
			sfw.open(PrintStreamMessenger.err);
			sfw.writePacket(packet);
			sfw.close();
		} catch (IOException e) {
			System.err.println("Couldn't send message");
			e.printStackTrace();
			System.exit(2);
		}
	}

}
