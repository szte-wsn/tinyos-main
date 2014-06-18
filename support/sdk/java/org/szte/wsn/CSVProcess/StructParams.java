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
package org.szte.wsn.CSVProcess;

import java.io.File;
import java.util.ArrayList;

/**
 * 
 * Bean class for handling the different parameters of structures during the CSVProcess
 *
 */
public class StructParams{
	private int localColumn; //time *
	private int globalColumn; //time *
	private ArrayList<Integer> dataColumns;  // *
	private File outputFile; //*
	private File avgOutputFile;	
	private boolean insertGlobal;	
	private String name;

	public StructParams(int localColumn, int globalColumn, int[] dataColumns, String outputName, String avgName, boolean insertGlobal, String name){
		this.localColumn=localColumn;
		this.globalColumn=globalColumn;
		this.dataColumns=new ArrayList<Integer>();
		for(int i=0;i<dataColumns.length;i++)
			this.dataColumns.add(dataColumns[i]);
		this.outputFile = new File(outputName);
		this.avgOutputFile = new File(avgName);
		this.insertGlobal=insertGlobal;
		this.name=name;
	}

	public File getOutputFile() {
		return outputFile;
	}
	public boolean isInsertGlobal() {
		return insertGlobal;
	}
	public File getAvgOutputFile() {
		return avgOutputFile;
	}
	public int getGlobalColumn() {
		return globalColumn;
	}
	public int getLocalColumn() {
		return localColumn;
	}
	public String getName(){
		return name;
	}

	public ArrayList<Integer> getDataColumns() {
		return dataColumns;
	}
}
