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

import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.util.ArrayList;

import argparser.ArgParser;
import argparser.BooleanHolder;
import argparser.IntHolder;
import argparser.StringHolder;

/**
 * 
 * @author Miklos Toth
 * Thread that controls communication
 *  between binary and string interfaces
 * 
 */
public class Transfer extends Thread  {
	public final static byte REWRITE=0;
	public final static byte NOREWRITE=1;
	public final static byte APPEND=2;
	final static String INPUTFILEH="determines the input parameters"+
	"if the input type is [binfile, textfile, shimmer] it must be followed by the filename(s) seperated by space,"+
	" or it can be followed by a wild card, which specifies the ending of the files we want to process"+
	"  e.g: -if *.bin if the input type is [serial], than the location of the source must be provided followed by the bandwith"+
	"  e.g.: -if serial@/dev/ttyUSB1:57600 if the input type is [console], than this option makes no effect, no default value";
	final static String OUTPUTFILE="Must be followed by the output file name, can't be used for multiple file names"+
	"by default the output file(s) will be the same as the input file(s). Only the extension will be replaced with the output extension.";
	final static String OUTPUTMODE="determines the way of output file handling "
		+" -rewrite: new output file will be created -append: the output will be added to the end of the existing file,"
		+" instead of creating a new file-norewrite: throws error, if the output file exists default is norewrite";
	final static String VERBOSE="determines the level of information printed out during processing,"
		+"-0: no additional information except IO error -1: prints out warning, when finds an unprocessable frame, which doesn't apply to any of the structs"
		+" also prints out the length of that frame -2: prints out the whole unmatching frame, default is level 1 ";
	private PacketParser[] packetParsers;
	private BinaryInterface binary;
	private StringInterface string;
	private String binarySourceName;
	private String stringSourceName;
	boolean toString;
	static ArgParser parser;


	/**
	 * Sets the interfaces from simple parameters
	 * @param binaryType [binfile, serial, shimmer]
	 * @param binaryPath path of binary media
	 * @param stringType [textfile, console]
	 * @param stringPath path of string media
	 * @param structPath path of the struct file
	 * @param toString if true writes from binary to string, else writes from string to binary 
	 * @param separator the string that separates the data in the output
	 * @param showName controls whether the name of the PacketParser should be written in the file
	 * @param outputMode determines the way of output file handling
	 * @param monoStruct if true different structures have to be written into different files
	 * @param noheader the fields name won't be displayed in the output
	 */
	public Transfer(String binaryType, String binaryPath, String stringType, String stringPath, String structPath,
			boolean toString, String separator,boolean showName, byte outputMode, boolean monoStruct, boolean noheader){
		packetParsers=new PacketParserFactory(structPath).getParsers();
		binary=BinaryInterfaceFactory.getBinaryInterface(binaryType, binaryPath);	
		binarySourceName=binaryPath;
		stringSourceName=stringPath;
		string=StringInterfaceFactory.getStringInterface(stringType, stringPath, packetParsers, separator, showName, outputMode, monoStruct, noheader);
		this.toString=toString;
		if((binary==null)||(string==null))
			usageThanExit();
	}



	/**
	 * Sets the interfaces from complex parameters
	 * @param packetParsers
	 * @param binary
	 * @param string
	 * @param toString
	 */
	public Transfer(PacketParser[] packetParsers, BinaryInterface binary, StringInterface string, boolean toString){
		this.packetParsers=packetParsers;
		this.binary=binary;
		this.string=string;
		binarySourceName="unknown binary source";
		stringSourceName="unknown String source";
		this.toString=toString;
	}

	@Override
	/**
	 * implements the communication in both directions
	 * only one direction one time
	 */
	public void run(){
		if(toString){
			byte data[]=binary.readPacket();
			boolean successful=true; 
			ArrayList<Integer> unmatched=new ArrayList<Integer>();
			while(data!=null){
				boolean match=false;
				int parserCounter=0;
				while ((!match)&&(parserCounter<packetParsers.length)){
					PacketParser pp=packetParsers[parserCounter];
					if((pp.getPacketLength()==data.length)&&(pp.parse(data)!=null)){
						match=true;
						string.writePacket(new StringPacket(pp.getName(),pp.getFields(),pp.parse(data)));
						//if the second parameter is different from pp.getFields than it will control the order of writing	
					}
					parserCounter++;
				}
				if(!match){					
					unmatched.add(data.length);
					successful=false;
				} 
				data=binary.readPacket();
			}
			if (successful)
				System.out.println("Parsing finished successfully: "+binarySourceName);
			else{
				System.out.println("Warning! There were unmatched frames during the parsing of: "+binarySourceName);
				while(unmatched.size()>0){
					int node=unmatched.get(0);
					int count=0;	
					while(unmatched.remove((Integer)node))
						count++;					
					System.out.println("Unmatched frame size: "+node+" occurrence: "+count);					
				}

			}
		}
		else{			//from string to binary  direction
			StringPacket sp=string.readPacket();
			boolean successful=true; 
			while(sp!=null){
				PacketParser pp=PacketParserFactory.getParser(sp.getName(), packetParsers);

				try {
					if(pp.construct(sp.getData())!=null){
						binary.writePacket(pp.construct(sp.getData()));
					}
					else
					{
						System.out.print("Warning! Input doesn't match to structure definition.");
						System.out.println(" Name of structure is: "+sp.getName()+".");
						successful=false;
					}
				} catch (IOException e) {

					e.printStackTrace();
					usageThanExit();
				}		

				sp=string.readPacket();
			}

			if (successful)
				System.out.println("Parsing finished successfully: "+stringSourceName);
			else
				System.out.println("Warning! There were unmatched frames during the parsing of: "+stringSourceName);
		}	

	}
	
	/**
	 * Main function read parameters from args[] parse them using argparser, 
	 * start Transfer threads for every input source according to the parameters
	 * @param args
	 */
	public static void main(String[] args) {	

		StringHolder structFileh=new StringHolder("structs.ini");
		StringHolder inputh=new StringHolder("binfile");
		StringHolder inputFileh=new StringHolder("");
		StringHolder outputh=new StringHolder("console");
		StringHolder outputFileh=new StringHolder("");
		StringHolder outputExth=new StringHolder("csv");
		StringHolder outputModeh=new StringHolder("norewrite");
		StringHolder separatorh=new StringHolder(";");
		BooleanHolder noheaderh=new BooleanHolder(false);
		BooleanHolder nostructNameh=new BooleanHolder(false);
		IntHolder verboseh = new IntHolder(1);
		BooleanHolder versionh=new BooleanHolder(false);
		BooleanHolder monoStructh=new BooleanHolder(false);

		parser = new ArgParser("java Transfer");	    

		parser.addOption("-s,-structfile %s#The location of the structrures's definition file. Default is structs.ini",structFileh); 
		parser.addOption("-i,-input %s{binfile,textfile,serial,shimmer,console}#Determines the type of input, default is binfile",inputh); 
		parser.addOption("-if,-inputfile %s#"+INPUTFILEH,inputFileh);
		parser.addOption("-o,-output %s{binfile,textfile,serial,console}#Determines the type of output, default is console",outputh);
		parser.addOption("-of,-outputfile %s#"+OUTPUTFILE,outputFileh);
		parser.addOption("-ox,-outputext %s#Determines the extension of output files, if there are more files, default is .csv",outputExth);
		parser.addOption("-ms, -monostruct %v# The outputfiles consist only one struct, the name of the struct showed in the filename", monoStructh);
		parser.addOption("-om,-outputmode %s{rewrite,append,norewrite}#"+OUTPUTMODE+"",outputModeh);
		parser.addOption("-nh,-noheader %v#the fields name won't be displayed in the output, by default the field's names are displayed at the beginning of every new struct",noheaderh);
		parser.addOption("-ns,-nostruct %v#the name of the struct won't be displayed in every line of the output, by default every line of the output starts with the name of the actual struct",nostructNameh);
		parser.addOption("-sr,-separator %s#must be followed by the desired separator, default value is: ';'",separatorh);
		parser.addOption ("-vb, -verbose %d {[0,2]}#"+VERBOSE, verboseh);
		parser.addOption("-v,-version %v# writes the version",versionh);


		String[] unMatched =
			parser.matchAllArgs (args,0,1);
		if(versionh.value)
			versionThanExit();
		String[] inputFiles;
		if(inputFileh.value.contains("*")){
			final String pattern=inputFileh.value.substring(inputFileh.value.lastIndexOf("*")+1);
			File path = new File(".");
			FilenameFilter filter = new FilenameFilter() 
			{ 
				@Override
				public boolean accept(File path, String name) 
				{
					return name.endsWith(pattern);
				}
			}; 
			inputFiles = path.list(filter);
		}
		else{
			int unMatchedSize=unMatched==null?0:unMatched.length;
			inputFiles=new String[unMatchedSize+1];
			inputFiles[0]=inputFileh.value;
			if (unMatched!=null)
				System.arraycopy(unMatched, 0, inputFiles, 1, unMatchedSize);
		}
		byte outputMode;
		if(outputModeh.value.equals("append"))
			outputMode=APPEND;
		else 
			if(outputModeh.value.equals("rewrite"))
				outputMode=REWRITE;
			else
				outputMode=NOREWRITE;

		String[] outputFiles=new String[inputFiles.length];
		if(inputFiles.length>0){
			int endOfInputFile;			
			for(int i=0;i<inputFiles.length;i++){
				endOfInputFile=inputFiles[i].contains(".")?inputFiles[i].lastIndexOf("."):inputFiles[i].length();
				outputFiles[i]=inputFiles[i].substring(0,endOfInputFile)+"."+outputExth.value;
			}
		}
		if(!outputFileh.value.equals("")) 
			outputFiles[0]=outputFileh.value;

		if(inputFileh.value.equals("")&&(!inputh.value.equals("console"))){ 
			System.out.println("Error! No input file provided.\n");			
			Transfer.usageThanExit();
		}

		if((inputh.value.equals("textfile"))||(inputh.value.equals("binfile"))||(inputh.value.equals("shimmer")))
			for(String path:inputFiles){

				File file=new File(path);
				if(!file.exists()){
					System.out.println("Not existing input file: "+path+" Use -help option for more information!");
					System.exit(1);
				}	
			}
		File file=new File(structFileh.value);
		if(!file.exists()){
			System.out.println("Not existing structure file: "+structFileh.value+" Use -help option for more information!");
			System.exit(1);
		}	


		if(inputh.value.equals("textfile")||inputh.value.equals("console"))
			for(int i=0;i<inputFiles.length;i++){

				Transfer fp=new Transfer(outputh.value, outputFiles[i], inputh.value, inputFiles[i], structFileh.value, false, 
						separatorh.value,!nostructNameh.value, outputMode, monoStructh.value, noheaderh.value);
				fp.start();

			}

		else
			for(int i=0;i<inputFiles.length;i++){

				Transfer fp=new Transfer(inputh.value, inputFiles[i], outputh.value, outputFiles[i], structFileh.value, true, 
						separatorh.value,!nostructNameh.value, outputMode, monoStructh.value, noheaderh.value);
				fp.start();

			}

	}
	
	public static void usageThanExit(){
		System.out.println(parser.getHelpMessage());
		System.exit(0);
	}
	public static void versionThanExit(){
		System.out.println("Transfer version:1.28");
		System.exit(0);
	}
}
