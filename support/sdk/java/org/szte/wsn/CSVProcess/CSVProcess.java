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
 * Author:Andras Biro, Miklos Toth
 */
package org.szte.wsn.CSVProcess;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.TreeMap;

import org.szte.wsn.TimeSyncPoint.LinearEquations;

/**
 * The CSVProcess class 
 */
public class CSVProcess{

	private static String separator=";";
	private static String nodeIdSeparator=":";
	private static String timeFormat="yyyy.MM.dd/HH:mm:ss.SSS";	
	private static String confFile="structs.ini";	
	private static String csvExt=".csv";		
	private static long startTime=Long.MIN_VALUE;
	private static long endTime=Long.MAX_VALUE;	
	private static long timeWindow=900000;	
	private static byte timeType=CSVHandler.TIMETYPE_START;

	private ArrayList<StructParams> structures;

	private int runningConversions;
	public ArrayList<CSVHandler> filesPerNode[];	


	public CSVProcess(ArrayList<String> inputFiles, ArrayList<StructParams> structs){
		this.structures=structs;
		/*
		for(int i=0;i<structures.size();i++){
			try {			
				structures.get(i).getOutputFile().createNewFile();
			} catch (IOException e) {
				System.err.println("Can't acces outputfile: "+structures.get(i).getOutputFile().getAbsolutePath()+", exiting");
				System.exit(1);
			}
		}
		*/
		runningConversions=inputFiles.size();
		for(String file:inputFiles)
			new Converter(file, confFile, csvExt, separator, new PerConversion());
	}


	private static ArrayList<StructParams> initParams(String fileName){

		ArrayList<StructParams> structs=new ArrayList<StructParams>();
		try {
			BufferedReader input =  new BufferedReader(new FileReader(fileName));
			try {

				int localColumn =-1;
				int globalColumn =-1;
				int[] dataColumns=null;
				String outputName="global";
				String avgName="avg";
				boolean insertGlobal = true; 
				String name=null;

				String line = null; 
				String keyWord=null;
				String value=null;
				boolean global=true;

				while (( line = input.readLine()) != null){
					if (line.contains("=")){
						keyWord=line.split("=")[0];
						keyWord=keyWord.trim();      //removing whitespace from the keyword
						value=line.split("=")[1];
						value=value.trim();
						if (value.startsWith("\""))
							value=value.substring(1, value.length());  
						if (value.endsWith("\""))            //removing " characters separately in case someone misses the end 
							value=value.substring(0, value.length()-1); 						
						if(global){
							if(keyWord.equalsIgnoreCase("separator")) 
								separator=value;
							if(keyWord.equalsIgnoreCase("nodeIdSeparator"))
								nodeIdSeparator=value;
							if(keyWord.equalsIgnoreCase("timeFormat")) 
								timeFormat=value;						
							if(keyWord.equalsIgnoreCase("confFile")) 
								confFile=value;
							if(keyWord.equalsIgnoreCase("csvExt")) 
								csvExt=value;						
							if(keyWord.equalsIgnoreCase("startTime")) {
								if (value.equalsIgnoreCase("min"))
									startTime=Long.MIN_VALUE;
								else
									startTime=Long.parseLong(value);
							}
							if(keyWord.equalsIgnoreCase("endTime")) {
								if (value.equalsIgnoreCase("max"))
									endTime=Long.MAX_VALUE;
								else
									endTime=Long.parseLong(value);
							}			

							if(keyWord.equalsIgnoreCase("timeWindow")) 
								timeWindow=Long.parseLong(value);

							if(keyWord.equalsIgnoreCase("timeType")){ 
								if (value.equalsIgnoreCase("middle"))
									timeType=CSVHandler.TIMETYPE_MIDDLE;
								else if (value.equalsIgnoreCase("end"))
									timeType=CSVHandler.TIMETYPE_END;
								else if (value.equalsIgnoreCase("start"))
									timeType=CSVHandler.TIMETYPE_START;
								else
									System.out.println("WARNING: Could not identify timeType during the parsing of "+fileName +"CSVProcess config file. ");
							}
						}//end of global parameter parsing branch
						else{
							if(keyWord.equalsIgnoreCase("avgOutputFileName")) 
								avgName=value;
							if(keyWord.equalsIgnoreCase("insertGlobal")) 
								insertGlobal=value.equalsIgnoreCase("true");
							if(keyWord.equalsIgnoreCase("outputFileName"))
								outputName=value;

							try {
								if(keyWord.equalsIgnoreCase("localColumn"))
									localColumn=Integer.parseInt(value);
								if(keyWord.equalsIgnoreCase("globalColumn"))
									globalColumn=Integer.parseInt(value);
								if(keyWord.equalsIgnoreCase("dataColumns")){
									String[] values=value.split(",");
									dataColumns=new int[values.length];
									for(int i=0; i<values.length;i++)
										dataColumns[i]=Integer.parseInt(values[i]);									
								}

							} catch (NumberFormatException e) {
								System.out.println("WARNING: Could not parse columns indicators during the parsing of "+fileName +" CSVProcess config file. ");
								e.printStackTrace();
							}
						}
					}
					else if(line.contains("structure")){
						if(global)
							global=false;
						else
						{							
							localColumn=-1;
							globalColumn=-1;
							dataColumns=null;
						}
						if (line.contains(" ")){
							value=line.split(" ")[1];
							name=value;
						}
						else
							name=null;


					}	
					else if(line.contains("endofstruct")){
						if((localColumn<0)||(globalColumn<0)||(dataColumns==null)||(name==null)){
							System.err.println("ERROR: Missing parameters while parsing "+fileName +" CSVProcess config file, "+name+" struct.");
							System.err.println("LocalColumn, globalColumn, datacolumns and name are mandatory for every structure");
							System.exit(1);
						}
						structs.add(new StructParams(localColumn, globalColumn, dataColumns, outputName, avgName, insertGlobal, name));
					}
				}//end of while 

			}
			finally {
				input.close();
			}
		}
		catch(NumberFormatException e){
			System.out.println("ERROR, could not parse every parameters of "+fileName +" CSVProcess config file. ");
		}
		catch (IOException e) {			
			System.out.println("IO ERROR while working with: "+fileName);
			e.printStackTrace();
			System.exit(1);			
		}
		return structs;
	}
	/**
	 * calculates offset and skew values for every mote
	 * detects and repairs timeStamp overflows
	 * @param timeFiles time csv files to process
	 */
	@SuppressWarnings("unused")
	private LinearEquations.Solution calculateTime(ArrayList<CSVHandler> timeFiles){
		//setting column identifiers of time file
		final boolean DEBUG=false;
		final int NODE_ID=1;
		final int LOCAL_TIME=2;
		final int LOCAL_BOOT_COUNT=3;
		final int REMOTE_TIME=4;
		final int REMOTE_BOOT_COUNT=5;
		//overflow detection and handling
		for(CSVHandler time:timeFiles){
			long timeMAX=4294967296L;
			TreeMap<String, Integer> overflowCount= new TreeMap<String, Integer>();
			overflowCount.put("local", 0);
			TreeMap<String, Long> previousTime= new TreeMap<String, Long>();
			previousTime.put("local", new Long(-1));
			TreeMap<String, Integer> previousLine= new TreeMap<String, Integer>();
			previousLine.put("local", 1);
			for(int cLine=1;cLine<=time.getLineNumber();cLine++){
				//check local time overflow				
				Long currentTime=Long.parseLong(time.getCell(LOCAL_TIME, cLine)); 
				if(((currentTime+10000)<previousTime.get("local"))&&   //10 s gap
						(time.getCell(LOCAL_BOOT_COUNT, cLine).equals(time.getCell(LOCAL_BOOT_COUNT, previousLine.get("local"))))){ //same bootCounter
					overflowCount.put("local", overflowCount.get("local")+1);
					previousTime.put("local", new Long(-1));
					previousLine.put("local", cLine);
					time.setCell(LOCAL_TIME, cLine, ""+(currentTime+overflowCount.get("local")*timeMAX));

					System.out.println("Time counter in "+time.getFile().getName()+" at: "+cLine+ " overflow, time line repaired." );

				}
				else{
					time.setCell(LOCAL_TIME, cLine, ""+(currentTime+overflowCount.get("local")*timeMAX));
					previousTime.put("local",currentTime);
					previousLine.put("local",cLine);					
				}
				//check remote time overflow
				currentTime=Long.parseLong(time.getCell(REMOTE_TIME, cLine)); 
				String remoteId=time.getCell(NODE_ID, cLine);
				if(previousTime.get(remoteId)==null){

					previousTime.put(remoteId, new Long(-1));
					overflowCount.put(remoteId,0);
					previousLine.put(remoteId, 1);
				}
				if((currentTime<previousTime.get(remoteId))&&
						(time.getCell(REMOTE_BOOT_COUNT, cLine).equals(time.getCell(REMOTE_BOOT_COUNT, previousLine.get(remoteId))))){ //same bootCounter
					overflowCount.put(remoteId, overflowCount.get(remoteId)+1);
					previousTime.put(remoteId, new Long(-1));
					previousLine.put(remoteId, cLine);
					time.setCell(REMOTE_TIME, cLine, ""+(currentTime+overflowCount.get(remoteId)*timeMAX));
					System.out.println("Time counter in "+time.getFile().getName()+ " file at "+cLine+". line  "+remoteId+" remoteId overflow, time line repaired." );
				}
				else{
					time.setCell(REMOTE_TIME, cLine, ""+(currentTime+overflowCount.get(remoteId)*timeMAX));
					previousTime.put(remoteId,currentTime);
					previousLine.put(remoteId,cLine);					
				}
			}			
		}
		//building up the equation system
		LinearEquations equations=new LinearEquations();
		HashSet<String> skews=new HashSet<String>();
		String skew;
		for(CSVHandler time:timeFiles){
			String fileId=getFileId(time.getFile().getName());
			for(int cLine=1;cLine<=time.getLineNumber();cLine++){
				LinearEquations.Equation eq=equations.createEquation();
				eq.setCoefficient("o_"+fileId+"_"+time.getCell(LOCAL_BOOT_COUNT, cLine),(double)1);  //coe of offset local
				eq.setCoefficient("o_"+expId(time.getCell(NODE_ID, cLine))+"_"+time.getCell(REMOTE_BOOT_COUNT, cLine),(double)-1);  //coe of offset remote
				skew="s_"+fileId;
				eq.setCoefficient(skew,Double.parseDouble(time.getCell(LOCAL_TIME, cLine))); //coe of skew local
				skews.add(skew);				

				skew="s_"+expId(time.getCell(NODE_ID, cLine));
				eq.setCoefficient(skew,-Double.parseDouble(time.getCell(REMOTE_TIME, cLine))); //coe of skew remote
				skews.add(skew);

				eq.setConstant(0);				
				equations.addEquation(eq);
			}
		}

		//adding summa skew
		LinearEquations.Equation ske=equations.createEquation();
		for(String sk:skews)
			ske.setCoefficient(sk, 1);
		ske.setConstant(skews.size()*0.9765625);
		ske.multiply(equations.getEquations().size()*6);
		equations.addEquation(ske);

		try {
			File refTimeFile=new File("99999_time.csv").exists()?new File("99999_time.csv"):new File("00000time.csv");
			if(!refTimeFile.exists()){
				System.err.println("Missing PC reference time file: 99999_time.csv. Could not reconstruct time. Program will exit.");
				System.exit(1);
			}
			CSVHandler reference=new CSVHandler(refTimeFile, true, ";", 1, new ArrayList<Integer>());

			//for(int cLine=1;cLine<=reference.getLineNumber();cLine++){
			for(int cLine=reference.getLineNumber();cLine<=reference.getLineNumber();cLine++){
				LinearEquations.Equation eq=equations.createEquation();

				eq.setCoefficient("o_"+expId(reference.getCell(NODE_ID, cLine))+"_"+reference.getCell(REMOTE_BOOT_COUNT, cLine),(double)1);  //coe of offset remote

				eq.setCoefficient("s_"+expId(reference.getCell(NODE_ID, cLine)),Double.parseDouble(reference.getCell(REMOTE_TIME, cLine))); //coe of skew remote

				eq.setConstant(Double.parseDouble(reference.getCell(LOCAL_TIME, cLine)));
				eq.multiply(1);
				equations.addEquation(eq);
			}
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}		
		//equations.printEquations();
		try{
			LinearEquations.Solution solution=equations.solveLeastSquares();
			if(DEBUG)
				solution.print();
			double sum=0;			

			//Error of reference mote and calculated mote time
			CSVHandler reference=new CSVHandler(new File("99999_time.csv"), true, ";", 1, new ArrayList<Integer>());
			for(int cLine=1;cLine<=reference.getLineNumber();cLine++){
				double res=solution.getValue("s_"+expId(reference.getCell(1, cLine)))*Double.parseDouble(reference.getCell(4, cLine));
				res+=solution.getValue("o_"+expId(reference.getCell(1, cLine))+"_"+reference.getCell(5, cLine));
				res-=Double.parseDouble(reference.getCell(2, cLine));
				if ((Math.abs(res)>1000)&&(DEBUG))
					System.out.println(cLine+" error of "+reference.getCell(1, cLine)+": "+res);
				sum+=Math.abs(res);
			}			
			System.out.print("Avarege error to UTC in ms: ");
			System.out.format("%.3f%n",sum/+reference.getLineNumber());

			sum=0;
			int countEquations=0;
			for(CSVHandler time:timeFiles){
				String fileId=getFileId(time.getFile().getName());
				for(int cLine=1;cLine<=time.getLineNumber();cLine++){
					double res=solution.getValue("s_"+expId(time.getCell(1, cLine)))*Double.parseDouble(time.getCell(4, cLine));
					res+=solution.getValue("o_"+expId(time.getCell(1, cLine))+"_"+time.getCell(5, cLine));
					res-=solution.getValue("s_"+fileId)*Double.parseDouble(time.getCell(2, cLine));
					res-=solution.getValue("o_"+fileId+"_"+time.getCell(3, cLine));

					if ((Math.abs(res)>600)&&(DEBUG))
						System.out.println("Error between "+time.getCell(1, cLine)+" and "+fileId+" at "+cLine+": "+res);
					sum+=Math.abs(res);
					countEquations++;
				}
			}
			if(sum/+countEquations<100){
				System.out.print("Timesyncronisation finished successfully. ");
				System.out.print("Avarege error between motes in ms: ");
				System.out.format("%.3f%n",sum/+countEquations);
			}
			else{
				System.out.print("Timesyncronisation finished with high error: ");
				System.out.print("Avarege error between motes in ms: ");
				System.out.format("%.3f%n",sum/+countEquations);
			}
			if (DEBUG)
				equations.printStatistics();

			return solution;
		}
		catch(Exception e){
			System.err.println("Could not reconstruct time. The number of equations is insufficient.  Possibly too short dataset, or two or more distinct datasets. Program will exit.");
			System.exit(1);
		}
		return null;
	}


	/**
	 * return the 5 character long id for fileNames
	 * @param fileName
	 * @return
	 */
	private String getFileId(String fileName){
		return fileName.split("_")[0];
	}

	/**
	 * returns the id in expanded with zeros
	 * @return 5 char long String
	 */
	private String expId(String id){
		String ret="";
		for(int i=0;i<5-id.length();i++)
			ret+="0";
		return ret+id;
	}

	/**
	 * Searches the name of the structure in the structs ArrayList and returns the id of it
	 * @param name 
	 * @param structs
	 * @return
	 */
	static int findIdForName(String name, ArrayList<StructParams> structs){		
		int ret=-1;	

		for(int j=0;j<structs.size();j++){
			if(name.contains(structs.get(j).getName()))
				ret=j;
		}
		if(ret<0){
			System.out.println("ERROR. Could not match files to structure names during CSVProcess.findIdForName()." );

			System.exit(1);
		}
		return ret; 
	}

	/**
	 * 
	 * @param fileGroup
	 */
	private void mergeConversion(ArrayList<CSVHandler> fileGroup) {
		CSVMerger merger=null;
		CSVHandler avgFile=null;
		merger=new CSVMerger(fileGroup);
		String fileName=fileGroup.get(0).getFile().getName();

		int count=findIdForName(fileName,structures);
		try {
			avgFile=merger.createAverageFile(structures.get(count).getAvgOutputFile(), nodeIdSeparator, startTime, endTime, timeWindow, timeType);

		} catch (IOException e) {
			System.err.println("E: Can't create average file");
		}
		avgFile.formatTime(timeFormat);
		avgFile.formatDecimalSeparator(",");
		try {
			avgFile.flush();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}



	public class PerConversion implements ParsingReady {

		/**
		 * runs when the conversion finished 
		 */
		@SuppressWarnings("unchecked")
		@Override		
		public void Ready(Converter output) {
			CSVHandler[] ready=null;
			try {
				ready = output.toCSVHandlers(structures);
			} catch (IOException e) {
				System.out.println("Can't open parsed file");
			} 
			if(ready!=null){
				if(filesPerNode==null){
					filesPerNode=new ArrayList[ready.length];
					for(int i=0;i<filesPerNode.length;i++)
						filesPerNode[i]=new ArrayList<CSVHandler>();
				}
				//TODO
				/*
				File tsFile=TSParser.searchTSFile(ready[0].getFile());
				TSParser parser=new TSParser(tsFile, maxError);
				ArrayList<LinearFunction> func=parser.parseTimeSyncFile();
				 */

				for(int i=0;i<ready.length;i++){
					//String fileName=ready[i].getFile().getName();
					//int count=findIdForName(fileName,structures);
					//ready[i].calculateGlobal (func, structures.get(count).getGlobalColumn(), structures.get(count).isInsertGlobal()) ; //for every struct
					filesPerNode[i].add(ready[i]);
				}
			}
			runningConversions--;
			if(runningConversions==0){
				int timeIndex=0;
				for(int i=0;i<filesPerNode.length;i++)
					if(filesPerNode[i].get(0).getName().endsWith("_time.csv"))
						timeIndex=i;
				LinearEquations.Solution solution=calculateTime(filesPerNode[timeIndex]);

				for(int i=0;i<filesPerNode.length;i++)
					if(i!=timeIndex)
						for(CSVHandler handler:filesPerNode[i]){
							String fileName=ready[i].getFile().getName();
							int count=findIdForName(fileName,structures);
							handler.calculateNewGlobal(solution,structures.get(count).getGlobalColumn(),structures.get(count).isInsertGlobal());

						}

				for(int i=0;i<filesPerNode.length;i++){
					if(i!=timeIndex)
						mergeConversion(filesPerNode[i]);
						for(CSVHandler handler:filesPerNode[i]){
							handler.formatTime(timeFormat);
							try {								
								if(!handler.flush())									
									System.out.println("Could not write: "+handler.getFile().getName());
							} catch (IOException e) {
								// TODO Auto-generated catch block
								e.printStackTrace();
							}
						}
				}


			}

		}

	}

	/**
	 * 
	 * @param args path of configuration file
	 */
	public static void main(String[] args){
		String[] fileNames=new File(".").list();
		ArrayList<String> inputfiles=new ArrayList<String>();
		for(String file:fileNames){
			if(file.endsWith(".bin")){
				inputfiles.add(file);
			}
		}
		String initFileName=(args.length>0)?args[0]:"csv.ini";
		ArrayList<StructParams> structs= initParams(initFileName);		



		new CSVProcess(inputfiles,structs);

	}


}
