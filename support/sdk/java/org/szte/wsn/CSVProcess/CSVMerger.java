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

/**
 * Merge CSVHandlers into one CSVHandler
 * @author Andras Biro
 *
 */
public class CSVMerger {
	String separator;
	int globalColumn;
	ArrayList<CSVHandler> csvfiles;
	ArrayList<Integer> dataColumns=new ArrayList<Integer>();

	/**
	 * Default constructor
	 * @param inputFiles CSVHandlers to merge
	 */
	public CSVMerger(ArrayList<CSVHandler> inputFiles){
		csvfiles=inputFiles;
		globalColumn=csvfiles.get(0).getTimeColumn();
		this.dataColumns=csvfiles.get(0).getDataColumns();
		this.separator=csvfiles.get(0).getSeparator();
	}

	private ArrayList<String> createHeader(ArrayList<CSVHandler> csvfiles,	ArrayList<Integer> datacolumns, String nodeIdSeparator) {
		ArrayList<String> ret = new ArrayList<String>();
		ret.add(csvfiles.get(0).getHeaderId(globalColumn));
		for(int id:datacolumns){
			String stringid=csvfiles.get(0).getHeaderId(id);
			for(CSVHandler file:csvfiles){
				String filename=file.getName().substring(file.getName().indexOf('0'), file.getName().lastIndexOf('_'));
				ret.add(stringid+nodeIdSeparator+filename);
			}
		}

		return ret;		
	}

	/**
	 * Creates global file.
	 * @param outfile File to create
	 * @param nodeIdSepString separates header id from nodeid in header (eg @: temp@12)
	 * @param startTime Merge the files from this time
	 * @param endTime Merge the files to this time
	 * @return Merged file
	 * @throws IOException if can't create output file
	 */
	public CSVHandler createGlobalFile(File outfile, String nodeIdSepString, long startTime, long endTime) throws IOException {
		ArrayList<String> newHeader=createHeader(csvfiles, dataColumns, nodeIdSepString);
		ArrayList<Integer> newDC=new ArrayList<Integer>(); //new DataColumnSet
		for(int i=1;i<newHeader.size();i++)
			newDC.add(i+1);
		outfile.delete();
		CSVHandler globalFile=new CSVHandler(outfile, true, separator, 1, newDC);
		globalFile.setHeader(newHeader);

		long currenttime=startTime;
		int[] currentline= new int[csvfiles.size()];
		long[] currenttimes= new long[csvfiles.size()];
		for(int i=0;i<currentline.length;i++) currentline[i]=1;
		//get the next timestamp from all files
		for(int i=0;i<csvfiles.size();i++){
			for(;currentline[i]<=csvfiles.get(i).getLineNumber();currentline[i]++){
				currenttimes[i]=Long.parseLong(csvfiles.get(i).getCell(globalColumn, currentline[i]));
				if(currenttimes[i]>currenttime){
					break;
				}
			}
		}
		do{
			//search the minimum
			currenttime=Long.MAX_VALUE;
			int mintimefile=-1;
			for(int i=0;i<currenttimes.length;i++){
				if(currenttime>currenttimes[i]){
					currenttime=currenttimes[i];
					mintimefile=i;
				}
			}
			if(currenttime==Long.MAX_VALUE)
				break;//we run out of data
			//add the minimum to the file 
			ArrayList<String> newline=new ArrayList<String>();
			CSVHandler thisfile=csvfiles.get(mintimefile);
			newline.add(thisfile.getCell(globalColumn, currentline[mintimefile]));
			for(int column:dataColumns){
				for(int i=0;i<mintimefile;i++)
					newline.add("");
				newline.add(thisfile.getCell(column, currentline[mintimefile]));
				for(int i=mintimefile+1;i<csvfiles.size();i++)
					newline.add("");
			}
			globalFile.addLine(newline);
			//reread the used line
			String time=csvfiles.get(mintimefile).getCell(globalColumn, ++currentline[mintimefile]);
			if(time!=null)
				currenttimes[mintimefile]=Long.parseLong(time);
			else
				currenttimes[mintimefile]=Long.MAX_VALUE;

		}while(currenttime<endTime);		
		return globalFile;
	}

	//TODO main method; priority: low

	/**
	 * Creates average file.
	 * @param outfile File to create
	 * @param nodeIdSepString separates header id from nodeid in header (eg @: temp@12)
	 * @param startTime Merge the files from this time
	 * @param endTime Merge the files to this time
	 * @return Averaged file
	 * @throws IOException if can't create output file
	 */
	public CSVHandler createAverageFile(File outfile, String nodeIdSepString, long startTime, long endTime, long timeWindow, byte timeType) throws IOException {

		ArrayList<CSVHandler> avgFiles=new ArrayList<CSVHandler>();

		if(startTime==Long.MIN_VALUE){
			long currentTime;
			for(int i=0;i<csvfiles.size();i++){				
				currentTime=Long.parseLong(csvfiles.get(i).getCell(globalColumn, 1));
				if(currentTime>startTime)
					startTime=currentTime;
			}
		}				
		for(CSVHandler csvFile:csvfiles){
			//System.out.println("Calculating average of:"+csvFile.getName());
			CSVHandler avg=csvFile.averageInTime(timeWindow, new File("avg"+csvFile.getName()), timeType,startTime);
			avgFiles.add(avg);
			//avg.formatTime(timeformat);
			//avg.flush();
		}
		System.out.println("Calculating average of files finished");
		ArrayList<String> newHeader=createHeader(avgFiles, dataColumns, nodeIdSepString);
		ArrayList<Integer> newDC=new ArrayList<Integer>(); //new DataColumnSet
		for(int i=1;i<newHeader.size();i++)
			newDC.add(i+1);
		outfile.delete();
		CSVHandler averageFile=new CSVHandler(outfile, true, separator, 1, newDC);
		averageFile.setHeader(newHeader);

		long currentTime=startTime;
		if(timeType==CSVHandler.TIMETYPE_END)
			currentTime+=timeWindow;
		else if(timeType==CSVHandler.TIMETYPE_MIDDLE)
			currentTime+=timeWindow/2;
		int[] currentline= new int[avgFiles.size()];
		for(int i=0;i<currentline.length;i++)
			currentline[i]=1;
		//get the next timestamp from all files
		
		boolean finished;
		do{
			finished=true;
			ArrayList<String> newline=new ArrayList<String>();
			newline.add(""+currentTime);
			Long actTime;

			for(int column:dataColumns){
				for(int i=0;i<avgFiles.size();i++){
					CSVHandler thisFile=avgFiles.get(i);
					if(thisFile.getLineNumber()>=currentline[i])
						actTime=Long.parseLong(thisFile.getCell(globalColumn, currentline[i]));
					else
						actTime=new Long(-1);
					if(actTime.equals(currentTime)){
						newline.add(thisFile.getCell(column, currentline[i]));
						if(column==dataColumns.get(dataColumns.size()-1))
							currentline[i]++;
						finished=false;
					}
					else
						newline.add("");
				}
			}	

			if(!finished){
				averageFile.addLine(newline);
				currentTime+=timeWindow;
			}
		}while((currentTime<endTime)&&(!finished));	
		System.out.println("Merging finished.");
		return averageFile;
	}
}
