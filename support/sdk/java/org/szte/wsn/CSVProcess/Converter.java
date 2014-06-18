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
package org.szte.wsn.CSVProcess;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Timer;
import java.util.TimerTask;

import org.szte.wsn.dataprocess.BinaryInterfaceFactory;
import org.szte.wsn.dataprocess.PacketParser;
import org.szte.wsn.dataprocess.PacketParserFactory;
import org.szte.wsn.dataprocess.Transfer;
import org.szte.wsn.dataprocess.file.StringInterfaceFile;

public class Converter implements ParsingReady{
	
	private Timer timer=new Timer();
	private Transfer parser;
	private String separator;
	private StringInterfaceFile sif;
	
	private static String switchExtension(String fullname, String newEx){
		return fullname.substring(0, fullname.lastIndexOf('.'))+newEx;
	}
	
	public Converter(String file, String confFile, String csvext, String separator, ParsingReady parent){
		this.separator=separator;
		
		PacketParser[] pp=new PacketParserFactory(confFile).getParsers();
		String outputfile=switchExtension(file, csvext);
		sif=new StringInterfaceFile(separator,outputfile , pp, false,Transfer.REWRITE, true, false);
		Transfer fp=new Transfer(pp,
				BinaryInterfaceFactory.getBinaryInterface("binfile", file),
				sif,
				true);
		fp.start();
		parser=fp;
		if(parent==null)
			parent=this;
		waitForParsing(parent);
	}
	
	/**
	 * returns the CSVHandlers for one .bin file
	 * @param structs the parameters of the structures
	 * @return array of CSVHandlers
	 * @throws IOException
	 */
	public CSVHandler[] toCSVHandlers(ArrayList<StructParams> structs) throws IOException{
		String[] filenames=sif.getFiles();
		CSVHandler[] files=new CSVHandler[filenames.length];
		if(files.length!=structs.size()){
			System.out.println("ERROR. Different number of structures in configuration files during toCSVHandlers.");
			System.exit(1);
			return null;			
		}
		for(int i=0;i<files.length;i++){
			int count=CSVProcess.findIdForName(filenames[i],structs);
				
			files[i]=new CSVHandler(new File(filenames[i]), true, separator, structs.get(count).getLocalColumn(), structs.get(count).getDataColumns());
		}
		return files;
	}
	
	public File[] getFiles(){
		String[] filenames=sif.getFiles();
		File[] files=new File[filenames.length];
		for(int i=0;i<files.length;i++){
			files[i]=new File(filenames[i]);
		}
		return files;
	}
	
	public class ParsersRunning extends TimerTask{

		private ParsingReady report;
		private Converter parent;
		
		@Override
		public void run() {
			if(!parser.isAlive()){
				timer.cancel();
				report.Ready(parent);
			}
		}
		
		public ParsersRunning(ParsingReady report, Converter parent){
			this.report=report;
			this.parent=parent;
		}
		
	}
	
	public void waitForParsing(ParsingReady report) {
		timer.scheduleAtFixedRate(new ParsersRunning(report, this),100,100);	
	}
	
	
	
	public static void main(String[] args){
		String[] fileNames=new File(".").list();
		for(String file:fileNames){
			if(file.endsWith(".bin")){
				new Converter(file,"convert.conf", ".csv", ",", null);
			}
		}
		
	}

	@Override
	public void Ready(Converter output) {
		// nobody want to know		
	}

	public CSVHandler getCSVHandler() {
		// TODO Auto-generated method stub
		return null;
	}

}
