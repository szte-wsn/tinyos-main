package org.szte.wsn.echoranger;

//import org.szte.wsn.downloader.*;
import org.szte.wsn.dataprocess.file.*;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;

public class ERParser {
	
	public static class EchoStruct{
		long seqno, timestamp, temp, avg;
		long range[]=new long[3];
		long score[]=new long[3];
		
		public String toString(){
			String ret=seqno+","+timestamp+","+temp+","+avg;
			for(int i=0;i<3;i++){
				ret+=","+range[i];
				ret+=","+score[i];
			}
			return ret+"\n";
		}
		
		public static String header(){
			return "seqno,timestamp,temperature,average,range1,score1,range2,score2,range3,score3\n";			
		}
	}
	
	public static class Waveform{
		int sample[]=new int[1024];
		
		public String toString(){
			String ret=String.valueOf(sample[0]);
			for(int i=1;i<1024;i++)
				ret+=","+sample[i];
			return ret+"\n";
		}
		
		public static String header(){
			String ret="0";
			for(int i=1;i<1024;i++)
				ret+=","+i;
			return ret+"\n";
		}
	}
	
	ArrayList<byte[]> frames;
	
	public static long toLong(byte data[],boolean is2complement, boolean isLittleEndian){
		long ret=0;
		//the mask is needed to cut the leading sign bits the java added
		for(int i=0;i<data.length;i++){
			if(isLittleEndian)
				ret|=(data[i] << i*8)&(0xff<<(i*8));
			else
				ret|=data[i] << ((data.length-i-1)*8)&((0xff<<(data.length-i-1)*8));
		}
		boolean negative=false;
		if(is2complement){
			if(isLittleEndian){
				if(data[data.length-1]<0)
					negative=true;
			} else {
				if(data[0]<0)
					negative=true;
			}
		}
		if(negative)
			ret=(-1&~((1<<data.length*8)-1))|ret;//add the missing leading sign bits
		return ret;
	}
	
	public static int toInt(byte data[],boolean is2complement, boolean isLittleEndian){
		int ret=0;
		//the mask is needed to cut the leading sign bits the java added
		for(int i=0;i<data.length;i++){
			if(isLittleEndian)
				ret|=(data[i] << i*8)&(0xff<<(i*8));
			else
				ret|=data[i] << ((data.length-i-1)*8)&((0xff<<(data.length-i-1)*8));
		}
		boolean negative=false;
		if(is2complement){
			if(isLittleEndian){
				if(data[data.length-1]<0)
					negative=true;
			} else {
				if(data[0]<0)
					negative=true;
			}
		}
		if(negative)
			ret=(-1&~((1<<data.length*8)-1))|ret;//add the missing leading sign bits
		return ret;
	}
	
	public static int toInt(byte data[],boolean is2complement, boolean isLittleEndian, int offset, int length){
		byte cutdata[]=new byte[length];
		for(int i=0;i<length;i++){
			cutdata[i]=data[offset+i];
		}
		return  toInt(cutdata, is2complement, isLittleEndian);
	}
	
	public static long toLong(byte data[],boolean is2complement, boolean isLittleEndian, int offset, int length){
		byte cutdata[]=new byte[length];
		for(int i=0;i<length;i++){
			cutdata[i]=data[offset+i];
		}
		return  toLong(cutdata, is2complement, isLittleEndian);
	}
	
	public String nodeidToPath(Integer nodeid,String postfix){
		String path=nodeid.toString();
		while (path.length()<5) {
			path='0'+path;
		}
		return path+postfix;
	}
	
	public ERParser(int nodeid, File esFile, File wfFile){
		try {
			int badframes=0;
			ArrayList<Gap> gaps=(new GapConsumer(nodeidToPath(nodeid, ".gap"))).getGaps();
			//RawPacketConsumer rpc=new RawPacketConsumer(nodeidToPath(nodeid, ".bin"),gaps,(byte)0x5e,(byte)0x5d,(byte)0x20);
			BinaryInterfaceFile bf=new BinaryInterfaceFile(nodeidToPath(nodeid, ".bin"), gaps);
			frames = new ArrayList<byte[]>();
			byte[] frame=bf.readPacket();
			while(frame!=null){
				frames.add(frame);
				frame=bf.readPacket();
			}
			//frames=rpc.getFrames();
			BufferedWriter esWriter=new BufferedWriter(new FileWriter(esFile));
			BufferedWriter wfWriter=new BufferedWriter(new FileWriter(wfFile));
			esWriter.write(EchoStruct.header());
			wfWriter.write(Waveform.header());
			for(byte[] currentFrame:frames){
				if((currentFrame[0]==0x00)&&(currentFrame.length==23)){
					EchoStruct es=new EchoStruct();
					es.seqno=toInt(currentFrame, false, true, 1, 2);
					es.timestamp=toLong(currentFrame, false, true, 3, 4);
					es.temp=toInt(currentFrame, false, true, 7, 2);
					es.avg=toInt(currentFrame, false, true, 9, 2);
					for(int i=0;i<3;i++){
						es.range[i]=toInt(currentFrame, false, true, 11+4*i, 2);
						es.score[i]=toInt(currentFrame, true, true, 13+4*i, 2);
					}
					esWriter.write(es.toString());
				}else if((currentFrame[0]==0x11)&&(currentFrame.length==2049)){
					Waveform wf=new Waveform();
					for(int i=0;i<1024;i++){
						wf.sample[i]=toInt(currentFrame, false, true, 1+2*i, 2);
					}
					wfWriter.write(wf.toString());
				} else
				{
					String s = "";
					for(int i = 0; i < currentFrame.length; ++i)
						s += " " + Integer.toString(currentFrame[i] & 0xFF);
					System.out.println("badframe of length " + currentFrame.length + ":" + s);
					badframes++;
				}
			}
			System.out.println("Bad frames: "+badframes);
			wfWriter.close();
			esWriter.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	
	
	public static void main(String[] args) {
		if(args.length==3){
			int nodeid=Integer.parseInt(args[0]);
			File esFile=new File(args[1]);
			File wfFile=new File(args[2]);
			new ERParser(nodeid,esFile,wfFile);
		} else
			System.err.println("Usage: ERParser <nodeid> <EchoRangerFileName> <WaveFormFileName>");
	}
}
