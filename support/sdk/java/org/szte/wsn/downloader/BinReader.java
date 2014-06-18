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
* Author:Andras Biro
*/

package org.szte.wsn.downloader;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashSet;

public class BinReader {
	ArrayList<DataElement> data=new ArrayList<DataElement>();
	private final byte FRAME=0x5e;
	private final byte ESCAPE=0x5d;
	private final byte XORESCAPE=0x20;
	private dataFile datas;
	private HashSet<Long> gaps;
	private ArrayList<TimeFunctions> functions=new ArrayList<TimeFunctions>(); 
	
	private ArrayList<Integer> readNextFrame(RandomAccessFile file_input) throws IOException{
		if(file_input.getFilePointer()>=file_input.length())
			return new ArrayList<Integer>();
		int buffer=0;
		while(buffer!=FRAME){//find the first framing byte
			while(gaps.contains(file_input.getFilePointer())){
				file_input.skipBytes(1);
			}
			buffer=file_input.read();
		}
		while(buffer==FRAME){//if there's more than one framing byte next to each other, find the last
			while(gaps.contains(file_input.getFilePointer())){
				file_input.skipBytes(1);
			}
			buffer=file_input.read();
		}
		//now in the buffer we've got the fist byte of the real data
		ArrayList<Integer> onemeas=new ArrayList<Integer>();
		while(buffer!=FRAME){
			if(gaps.contains(file_input.getFilePointer()-1)||file_input.getFilePointer()>=file_input.length())//if there is a gap in the middle of the frame, than drop it, try the next frame
				return readNextFrame(file_input);
			if(buffer==ESCAPE)
				buffer=file_input.read()^XORESCAPE;
			onemeas.add(buffer);
			buffer=file_input.read();
		}
		return onemeas;
	}
	
	private TimeFunctions regression(ArrayList<Long> MoteTime,ArrayList<Long> PCTime){
		double skew,offset;
		if(MoteTime.size()!=PCTime.size()||MoteTime.size()<0)
			return null;
		if(MoteTime.size()>=2){//linear regression
			double av_mote=0, av_pc=0;
			for(int i=0;i<MoteTime.size();i++){
				av_mote+=MoteTime.get(i);
				av_pc+=PCTime.get(i);
			}
			av_mote/=MoteTime.size();
			av_pc/=PCTime.size();
			double denom=0,numer=0;
			for(int i=0;i<MoteTime.size();i++){
				numer+=(MoteTime.get(i)-av_mote)*(PCTime.get(i)-av_pc);
				denom+=(MoteTime.get(i)-av_mote)*(MoteTime.get(i)-av_mote);
			}
			skew=numer/denom;
			offset=av_pc-skew*av_mote;							
		} else{
			skew=1;
			offset=PCTime.get(0)-MoteTime.get(0);
		}
		return new TimeFunctions(offset, skew);
	}
	
	private double checkerror(TimeFunctions func, long pc, long mote){
		double ret=pc-func.offset-func.skew*mote;
		if(ret<0)
			return -1*ret;
		else	
			return ret;
	}
	
	public BinReader(String datafile, String outputfile, boolean convert, boolean converttime, boolean rewrite, long errorlimit){
		int badframes=0;
		if(!new File(datafile).exists()){
			System.err.println("Data file doesn't exist");
			System.exit(1);
		}
		if(new File(outputfile).exists()&&!rewrite){
			System.err.println("Output file exists, use --rewrite option to rewrite it");
			System.exit(1);
		} 
		try {
			datas=new dataFile(datafile);
			
			if(datas.getTimestamps().exists()){
				BufferedReader input =  new BufferedReader(new FileReader(datas.getTimestamps()));
				String line;
				TimeFunctions tempfunc=null;
				ArrayList<Long> MoteTime=new ArrayList<Long>();
				ArrayList<Long> PCTime=new ArrayList<Long>();
				while (( line = input.readLine()) != null){
					String[] dates = line.split(":");
					if(tempfunc!=null&&checkerror(tempfunc,Long.parseLong(dates[0]),Long.parseLong(dates[1]))>errorlimit){//end of running: calculate the function, then read the next running
						functions.add(tempfunc);
						System.out.println("pc="+tempfunc.offset+"+"+tempfunc.skew+"*mote; points:"+MoteTime.size());
						PCTime.clear();
						MoteTime.clear();
						tempfunc=null;
					}
					PCTime.add(Long.parseLong(dates[0]));
					MoteTime.add(Long.parseLong(dates[1]));
					tempfunc=regression(MoteTime, PCTime);
				}
				functions.add(tempfunc);
				System.out.println("pc="+tempfunc.offset+"+"+tempfunc.skew+"*mote; points:"+MoteTime.size());
			} else {
				System.out.println("Warning: Timestamp file doesn't exist");
			}
			
			gaps=datas.getAllGap();
			RandomAccessFile file_input = datas.dataFile;
			
			while(file_input.getFilePointer()<file_input.length()){
				//System.out.println(file_input.getFilePointer()+"|"+file_input.length());
				ArrayList<Integer> frame=readNextFrame(file_input);
				if(frame.size()==9){
					DataElement de=new DataElement();
					de.temp=frame.get(0)*256+frame.get(1);
					de.humi=frame.get(2)*256+frame.get(3);
					de.light=frame.get(4);
					if(de.light>127&&de.light<256){
						int s=0xf&de.light;
						int c=Integer.rotateRight(de.light-128-s,4);
						int twopowc=(int) Math.pow(2,c);
						de.light=(int) (Math.floor(16.5*(twopowc-1)))+s*twopowc;
					} else
						de.light=0xffff;
					
					de.localetime=frame.get(5)*16777216L+frame.get(6)*65536L+frame.get(7)*256L+frame.get(8);
					data.add(de);
					//System.out.println(frame);
				} else 
					badframes++;
			}
			int currentfunc=functions.size()-1;
			long prevtime=Long.MAX_VALUE;
			for(int i=data.size()-1;i>=0;i--){
				if(prevtime<=data.get(i).localetime)
					currentfunc--;
				if(currentfunc<0){
					data.get(i).globaltime=data.get(i).localetime;
				}else{
					prevtime=data.get(i).localetime;
					data.get(i).globaltime=(long) (functions.get(currentfunc).offset+functions.get(currentfunc).skew*data.get(i).localetime);
				}
			}
			BufferedWriter output = new BufferedWriter(new FileWriter(outputfile));
			output.write("LocalTime,GlobalTime,Temperature,Humidity,Brightness");
			output.newLine();
			for(DataElement de:data){
				String temp=Integer.toString(de.temp);
				String humi=Integer.toString(de.humi);
				String globaltime=Long.toString(de.globaltime);
				String localetime=Long.toString(de.localetime);
				if(converttime&&(de.globaltime!=de.localetime)){
					globaltime=new SimpleDateFormat("yyyy.MM.dd. HH:mm:ss.SSS").format(new Date(de.globaltime));
					//time=new Date(de.time).toString();
				}	
				if(convert){
					temp=Double.toString(0.01*de.temp-39.6);
					humi=Double.toString(-4+0.0405*de.humi+-2.8000E-6*de.humi*de.humi);
				}
				System.out.append(localetime + "," + globaltime +","+temp+","+humi+","+de.light+"\n");
				output.append(localetime + "," + globaltime +","+temp+","+humi+","+de.light);
				output.newLine();
			}
			output.flush();
			output.close();
		} catch (IOException e) {
			System.out.println("Error: Can't write output file");
		}
		System.out.println("Bad Frames: "+badframes);
	}
	
	public class DataElement{
		int temp, humi,light;
		long localetime;
		long globaltime;
	}
	
	public class TimeFunctions{
		double skew, offset;
		
		public TimeFunctions(double offset, double skew){
			this.offset=offset;
			this.skew=skew;
		}
	}
	
	public static void usageThanExit(){
		System.out.println("java BinReader [options]");
		System.out.println("options:");
		System.out.println("	-c; --convert: convert the temperature to celsius and the humidity to percent");
		System.out.println("	-t; --converttime: convert the time to human readable format");
		System.out.println("	-r; --rewrite: rewrite the output file if exists");
		System.out.println("	-i; --input <filename>: the filename of the binary file");
		System.out.println("				default: all the file in the directory");
		System.out.println("	-o; --output <filename>: the filename of the generated output");
		System.out.println("				default: The input filename with txt extension");
		System.out.println("				only working if the input file was set");
		System.out.println("	-e; --maxtimeerror <number>: The maximum of the enabled error during timesync in seconds");
		System.out.println("				default:120");
		System.exit(0);
	}
	
	public static String switchExtension(String fullname, String newEx){
		return fullname.substring(0, fullname.lastIndexOf('.'))+"."+newEx;
	}
	
	public static void main(String[] args) throws Exception {
		boolean convert=false;
		boolean converttime=false;
		boolean rewrite=false;
		String output="";
		String input="";
		long errorlimit=120000;
		for(int i=0;i<args.length;i++){
			if(args[i].startsWith("-")){
				if(args[i].startsWith("--")||args[i].length()<=2){
					if(args[i].equals("--convert")||args[i].equals("-c"))
						convert=true;
					else if(args[i].equals("--converttime")||args[i].equals("-t"))
						converttime=true;
					else if(args[i].equals("--rewrite")||args[i].equals("-r"))
						rewrite=true;
					else if(args[i].equals("--maxtimeerror")||args[i].equals("-e")){
						i++;
						try{
							errorlimit=1000*Long.parseLong(args[i]);
						} catch(NumberFormatException e){
							BinReader.usageThanExit();
						}
					} else if(args[i].equals("--output")||args[i].equals("-o")){
						i++;
						output=args[i];
					} else if(args[i].equals("--input")||args[i].equals("-i")){
						i++;
						input=args[i];
					}
				} else {
					for(int j=1;j<args[i].length();j++){
						switch(args[i].charAt(j)){
							case 'c':{
								convert=true;
							}break;
							case 't':{
								converttime=true;
							}break;
							case 'r':{
								rewrite=true;
							}break;
						}
					}
				}
			} else {
				BinReader.usageThanExit();
			}
				
		}
		if(output!=""&&input=="")
			BinReader.usageThanExit();
		else if(output==""&&input!="")
			output=BinReader.switchExtension(input, "txt");
		if(input!="")
			new BinReader(input, output, convert, converttime, rewrite, errorlimit);
		else{
			String[] fileNames=new File(".").list();
			for(String fileName:fileNames){
				if(fileName.endsWith(".bin")){
					File current=new File(fileName);
					if(current.isFile()&&current.exists()&&current.canRead()){
						new BinReader(fileName, BinReader.switchExtension(fileName, "txt"), convert, converttime, rewrite, errorlimit);
					}
				}
			}
		}
	}

}
