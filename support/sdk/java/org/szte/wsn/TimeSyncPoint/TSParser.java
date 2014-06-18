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
package org.szte.wsn.TimeSyncPoint;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;

public class TSParser {
	private File tsFile;
	private long maxError;

	/**
	 * returns TimeSync file for given data file (search in the data files directory)
	 * @param dataFile
	 * @return TimeSync file
	 */
	public static File searchTSFile(File dataFile){
		File dir=new File(dataFile.getAbsolutePath().substring(0,dataFile.getAbsolutePath().lastIndexOf(File.separator)));
		String[] fileNames=dir.list();
		for(String name_ext:fileNames){
			String nameOnly=name_ext;
			if(nameOnly.contains("."))
				nameOnly=nameOnly.substring(0,nameOnly.lastIndexOf("."));
			if(dataFile.getName().startsWith(nameOnly)&&name_ext.endsWith(".ts"))
				return new File(name_ext);
		}
		return null;
	}
	
	/**
	 * Parses TimeSync file and calculates regression
	 * @return Linear function(s) calculated from the file
	 */
	public ArrayList<LinearFunction> parseTimeSyncFile(){
		ArrayList<LinearFunction> functions=new ArrayList<LinearFunction>();
		if(tsFile==null){
			System.err.println("Error: in TSParser, missing timestamp file . The thread will terminate");
			System.exit(1);
		}
		if(tsFile.exists()&&tsFile.isFile()&&tsFile.canRead()){
			BufferedReader input;
			try {
				input = new BufferedReader(new FileReader(tsFile));
			} catch (FileNotFoundException e1) {
				System.err.println("Error: Can't read timestamp file: "+tsFile.getName());
				return null;
			}
			String line;
			Regression regr=new Regression(maxError,(double)1000/1024);
			try {
				while (( line = input.readLine()) != null){
					String[] dates = line.split(":");
					if(dates.length<2){
						System.err.println("Warning: Too short line in file: "+tsFile.getName());
						System.err.println(line);
						continue;
					}
					Long pctime,motetime;
					try{
						pctime=Long.parseLong(dates[0]);
						motetime=Long.parseLong(dates[1]);
					} catch(NumberFormatException e){
						System.err.println("Warning: Unparsable line in file: "+tsFile.getName());
						System.err.println(line);
						continue;
					}
					if(!regr.addPoint(motetime, pctime)){//end of running: save the function, then read the next running
						functions.add(regr.getFunction());
						System.out.println("pc="+regr.getFunction().getOffset()+"+"+regr.getFunction().getSkew()+"*mote ("+tsFile.getName()+"); points:"+regr.getNumPoints());
					}
				}
			} catch (IOException e) {
				System.err.println("Error: Can't read timestamp file: "+tsFile.getName());
				return null;
			}
			functions.add(regr.getFunction());
			System.out.println("pc="+regr.getFunction().getOffset()+"+"+regr.getFunction().getSkew()+"*mote ("+tsFile.getName()+"); points:"+regr.getNumPoints());
			return functions;
		} else {
			System.err.println("Error: Can't read timestamp file: "+tsFile.getName());
			return null;
		}
	}
	
	/**
	 * 
	 * @param tsFile TimeSync file
	 * @param maxError maximum distance of any new point from the calculated line Regression.java
	 */
	public TSParser(File tsFile, long maxError){
		this.tsFile=tsFile;
		this.maxError=maxError;
	}

}
