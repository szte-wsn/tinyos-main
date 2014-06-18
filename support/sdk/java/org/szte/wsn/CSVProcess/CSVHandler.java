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

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;

import org.szte.wsn.TimeSyncPoint.LinearEquations;
import org.szte.wsn.TimeSyncPoint.LinearFunction;
/**
 * CSV table file processor for data(time) functions.
 * Every table has a time column and columns with data
 * Column and line numbering starts with 1
 * @author Andras Biro
 *
 */
public class CSVHandler {
	private File csvfile;
	private String separator;


	private ArrayList<String> header;
	private ArrayList<String[]> data;
	private int timeColumn;
	private ArrayList<Integer> dataColumns;
	
	/**
	 * Changes the extension of a filename (the string after the last dot)
	 * @param fullname Original filename (or path) with extension
	 * @param newEx New extension of the filename (with dot; for example ".txt")
	 * @return filename with new extension
	 */
	public static String changeExtension(String fullname, String newEx){
		return fullname.substring(0, fullname.lastIndexOf('.'))+newEx;
	}
	
	private void initEmptyFile(){
		header=null;
		data=new ArrayList<String[]>();
	}
	/**
	 * opens and reads csv file into ArrayList<String[]> data
	 * @param hasheader
	 * @throws IOException
	 */
	private void openFile(boolean hasheader) throws IOException{
		if(!csvfile.exists()){
			initEmptyFile();
			return;
		}
		BufferedReader input=new BufferedReader(new FileReader(csvfile));
		String line=input.readLine();
		if(line==null){
			input.close();
			initEmptyFile();
			return;
		}
		if(hasheader){
			header=new ArrayList<String>();
			for(String column:line.split(separator)){
				header.add(column);
			}
			line=input.readLine();
		} else
			header=null;
		data=new ArrayList<String[]>();
		while(line!=null){
			data.add(line.split(separator));
			line=input.readLine();
		}
		input.close();
		
	}
	
	/**
	 * Constructor
	 * @param csvfile CSV file to open
	 * @param hasheader true, if the CSV file has header: the first line is the name of the columns
	 * @param separator CSV cell separator e.g. ";"
	 * @param timeColumn this column holds the time reference of the table
	 * @param dataColumns these columns holds data
	 * @throws IOException if can't open/read/close the file
	 */
	public CSVHandler(File csvfile, boolean hasheader, String separator, int timeColumn, ArrayList<Integer> dataColumns) throws IOException{
		this.separator=separator;
		this.csvfile=csvfile;
		this.timeColumn=timeColumn;
		this.dataColumns=new ArrayList<Integer>(dataColumns);
		openFile(hasheader);
	}
	
	/**
	 * Constructor
	 * @param csvfile CSV file to open
	 * @param hasheader true, if the CSV file has header: the first line is the name of the columns
	 * @param separator CSV cell separator e.g. ";"
	 * @param timeColumn this column holds the time reference of the table
	 * @param dataColumns these columns holds data
	 * @throws IOException if can't open/read/close the file
	 */
	public CSVHandler(File csvfile, boolean hasheader, String separator, int timeColumn, Integer dataColumns[]) throws IOException{
		this.dataColumns=new ArrayList<Integer>();
		for(Integer curr:dataColumns)
			this.dataColumns.add(curr);
		this.separator=separator;
		this.csvfile=csvfile;
		this.timeColumn=timeColumn;
		openFile(hasheader);
	}
	
	/**
	 * Rereads file from the disk. All unsaved changes will be lost
	 * @param hasheader true, if the CSV file has header: the first line is the name of the columns
	 * @throws IOException if can't open/read/close the file
	 */
	public void reReadFile(boolean hasheader) throws IOException{
		openFile(hasheader);
	}
	
	/**
	 * @return separator used in the file
	 */
	public String getSeparator() {
		return separator;
	}
	
	/**
	 * returns the header line for the file (if it hasn't got one, returns null)
	 * @return the header line for the file
	 */
	public ArrayList<String> getHeader(){
		return header;
	}
	
	/**
	 * Returns the name of a column, based on the header (if it hasn't got one, returns null)
	 * @param id column number
	 * @return name of the column
	 */
	public String getHeaderId(int id){
		if(header!=null&&header.size()>=id-1)
			return header.get(id-1);
		else if(header.size()>=id-1)
			return "";
		else
			return null;
	}
	
	/**
	 * Returns the number of the column with name, based on header.
	 * If there's no such name, returns -1
	 * @param name name of the column
	 * @return number of the column
	 */
	public int getColumnNum(String name){
		if(header==null)
			return -1;
		for(String column:header)
			if(column.equals(name))
				return header.indexOf(column)+1;
		return -1;
	}
	
	/**
	 * Sets the header of the file
	 * @param h new header
	 */
	public void setHeader(ArrayList<String> h) {
		header=h;
	}
	
	/**
	 * Sets the header of the file
	 * @param h new header
	 */
	public void setHeader(String[] h) {
		if(header!=null)
			header.clear();
		else
			header=new ArrayList<String>();
		for(String curr:h)
			header.add(curr);
	}
	
	/**
	 * Clears the header line (the first line will be data)
	 */
	public void clearHeader(){
		header=null;
	}
	
//these functions seems to be unused	
//	/**
//	 * Returns the whole header line (with separators)
//	 * @return header line
//	 */
//	public String getHeaderLine(){
//		String ret="";
//		for(int i=0;i<header.size()-1;i++)
//			ret+=header.get(i)+separator;
//		ret+=header.get(header.size()-1);
//		return ret;
//	}
//	
//	/**
//	 * Sets the whole header line
//	 * @param h new header line
//	 */
//	public void setHeaderLine(String h){
//		for(String column:h.split(separator)){
//			header.add(column);
//		}
//	}
	
	
	/**
	 * Writes the current changes to the disk (rewrites the whole file)
	 * @return false if can't overwrite earlier file, true otherwise
	 * @throws IOException if can't open/write/close the file
	 */
	public boolean flush() throws IOException{
		File csvFile=new File(csvfile.getName());
		BufferedWriter output=new BufferedWriter(new FileWriter(csvFile,false));
		if(header!=null){
			for(int i=0;i<header.size()-1;i++)
				output.append(header.get(i)+separator);
			output.append(header.get(header.size()-1));
			output.newLine();
		}
		for(String[] line:data){
			for(int i=0;i<line.length-1;i++)
				output.append(line[i]+separator);
			output.append(line[line.length-1]);
			output.newLine();
		}
		output.close();
		return true;
	}
	
	/**
	 * @param line number of the line
	 * @return the whole line, with separators
	 */
	private String getLine(int line){
		line--;
		String ret="";
		for(int i=0;i<data.get(line).length-1;i++)
			ret+=data.get(line)[i]+separator;
		ret+=data.get(line)[data.get(line).length-1];
		return ret;
	}
	
	/**
	 * Returns a cell at given coordinates
	 * @param column Column number
	 * @param line Line number
	 * @return cell
	 */
	public String getCell(int column, int line){
		column--;line--;
		if(line>=getLineNumber())
			return null;
		if(column>=data.get(line).length)
			return "";
		//System.out.println(data.get(line)[column]);
		return data.get(line)[column];
	}
	
	/**
	 * Sets a cell value at given coordinates.
	 * Creates new column(s) in the line if needed, but not creates new line(s) 
	 * @param column Column number
	 * @param line Line number
	 * @param value New value of the cell
	 * @return false if there's no such line, true otherwise
	 */
	public boolean setCell(int column, int line, String value){
		column--;line--;
		if(line>=getLineNumber())
			return false;
		if(column>=data.get(line).length){
			String[] newstr=new String[column];
			for(int i=0;i<newstr.length;i++){
				if(i<data.get(line).length)
					newstr[i]=data.get(line)[i];
				else
					newstr[i]="";
			}
			data.set(line,newstr);
		}
		data.get(line)[column]=value;
		return true;
	}
	
	/**
	 * Inserts a column. The columns after the new one will be shifted right
	 * @param name Name of the column in the header. If there's no header, it has no effect
	 * @param column Number of the new column. 
	 */
	public void addColumn(String name, int column){
		column--;//start counting from 0 instead of 1
		if(header!=null)
			header.add(column, name);
		for(int i=0;i<getLineNumber();i++){
			String[] oldstr = data.get(i);
			String[] newstr;
			if(oldstr.length>=column)
				newstr=new String[oldstr.length+1];
			else
				newstr=new String[column];
			for(int j=0;j<newstr.length;j++){
				if(j<column&&j<oldstr.length)
					newstr[j]=oldstr[j];
				else if(j>column&&j<oldstr.length+1)
					newstr[j]=oldstr[j-1];
				else
					newstr[j]="";
			}
			data.set(i, newstr);
		}
	}
	
	/**
	 * Removes a column. The columns after the removed one will be shifted left.
	 * @param column Number of the column
	 */
	public void removeColumn(int column){
		column--;//start counting from 0 instead of 1
		if(header!=null)
			header.remove(column);
		for(int i=0;i<getLineNumber();i++){
			String[] oldstr = data.get(i);
			if(oldstr.length<column+1)
				continue;
			String[] newstr=new String[oldstr.length-1];
			for(int j=0;j<newstr.length;j++){
				if(j<column)
					newstr[j]=oldstr[j];
				else 
					newstr[j]=oldstr[j-1];
			}
			data.set(i, newstr);
		}
	}
	
	/**
	 * Adds a new line at given position with given values. Shifts the line after the new one down
	 * @param line Number of the line
	 * @param values Values in the line
	 */
	public void addLine(int line, String[] values){
		line--;
		data.add(line, values);
	}
	
	/**
	 * Adds a new line at the end of the table with given values.
	 * @param values Values in the line
	 */
	public void addLine(String[] values){
		data.add(values);
	}
	
	/**
	 * Adds a new line at the end of the table with given values.
	 * @param values Values in the line
	 */
	public void addLine(ArrayList<String> values){
		String[] arrayvalues=new String[values.size()];
		for(int i=0;i<values.size();i++)
			arrayvalues[i]=values.get(i);
		addLine(arrayvalues);
	}
	
	/**
	 * Removes a line from the table. The lines after the removed one will be shifted up
	 * @param line Number of the line
	 */
	public void removeLine(int line){
		line--;
		data.remove(line);
	}
	
	/**
	 * Returns the number of the lines.
	 * @return number of the lines
	 */
	public int getLineNumber(){
		return data.size();
	}
	
	/**
	 * Returns the file of the instance
	 * @return the file of the instance
	 */
	public File getFile(){
		return csvfile;
	}
	
	/**
	 * Returns the filename of the instance
	 * @return filename
	 */
	public String getName(){
		return csvfile.getName();
	}
	
	/**
	 * Sets the time reference column
	 * @param timeColumn number of the column
	 */
	public void setTimeColumn(int timeColumn) {
		this.timeColumn = timeColumn;
	}

	/**
	 * @return Column number of the time reference
	 */
	public int getTimeColumn() {
		return timeColumn;
	}

	/**
	 * Sets the data columns
	 * @param dataColumns
	 */
	public void setDataColumns(ArrayList<Integer> dataColumns) {
		this.dataColumns = dataColumns;
	}
	
	/**
	 * Adds a column to the data columns
	 * @param item Column number of the new data column
	 */
	private void addDataColumn(int item) {
		dataColumns.add(item);		
	}

	/**
	 * @return data columns
	 */
	public ArrayList<Integer> getDataColumns() {
		return dataColumns;
	}

	/**
	 * Try to write the file to the disk at exiting
	 * @throws IOException
	 */
	public void onDestroy() throws IOException{
		if(!flush())
			System.err.println("Can't overwrite file: "+csvfile.getName());
	}
	
	public boolean isEmpty(){
		if(getLineNumber()==0&&header==null)
			return true;
		else
			return false;
		
	}
	//global time calculation functions
	
	//TODO: this function, and the two tsfile constructor should be removed, and called from an other class (TimeSync packet); priority: high
	
	
	private ArrayList<Integer> GetBreaks(){

		ArrayList<Integer> ret=new ArrayList<Integer>();
		int currentline=1;
		Long lasttime=null;
		Long currenttime=null;
		while(currentline<=getLineNumber()){		
			try{
				currenttime=Long.parseLong(getCell(timeColumn, currentline));
			} catch(NumberFormatException e){
				System.err.println("Warning: Unparsable line in file: "+getFile().getName());
				System.err.println(getLine(currentline));
				continue;
			}
			if(lasttime==null||lasttime>currenttime){
				ret.add(currentline);
			}
			lasttime=currenttime;
			currentline++;
		}
		return ret;
		
	}
	
	/**
	 * Calculate global time with linear functions from the time reference column.  
	 * Replaces the reference time column, with the calculated one.
	 * It's possible that the time column isn't monotonically increasing, because the measuring
	 * device restarted. We call a monotonically increasing part of the table "running". First, we
	 * search for all the runnings in the table, then we calculate the global time for the last
	 * running with the last function, then the last before, and so on, until we run out of running
	 * or function.
	 * @param functions Linear functions for this file (increasing order in time)
	 * @param global Column number of the new "globaltime" column 
	 * @param insert If false, the global column will be rewritten, if true, it will be inserted
	 */
	public void calculateGlobal(ArrayList<LinearFunction> functions, int global, boolean insert){

		ArrayList<Integer> breaks=GetBreaks();
		
		int currentrun=0;
		if(insert)
			addColumn("globaltime", global);	
		for(int currentline=1;currentline<=getLineNumber();currentline++){
			if(breaks.contains(currentline))
				currentrun++;
			Long currenttime=null;
			try{
				currenttime=Long.parseLong(getCell(timeColumn, currentline));
			} catch(NumberFormatException e){
				System.err.println("Warning: Unparsable line in file: "+getFile().getName());
				System.err.println(getLine(currentline));
				continue;
			}
			int currentfunction=breaks.size()-currentrun;
			String currenttstring;
			if(currentfunction>=0){
				currenttime=(long) (functions.get(currentfunction).getOffset()+functions.get(currentfunction).getSkew()*currenttime);
				currenttstring=currenttime.toString();
			} else 
				currenttstring="";
			setCell(global, currentline, currenttstring);
		}
		addDataColumn(timeColumn);
		setTimeColumn(global);
	}
	
	public void calculateNewGlobal(LinearEquations.Solution solution, int global, boolean insert){
		
		int bootcount=0;
		if(insert)
			addColumn("globaltime", global);	
		for(int currentline=1;currentline<=getLineNumber();currentline++){
			Long currentTime=null;
			try{
				currentTime=Long.parseLong(getCell(timeColumn, currentline));
				bootcount=Integer.parseInt(getCell(timeColumn+1, currentline));
			} catch(NumberFormatException e){
				System.err.println("Warning: Unparsable line in file: "+getFile().getName());
				System.err.println(getLine(currentline));
				continue;
			}

			String skewString="s_"+getFile().getName().split("_")[0];
			String offsetString="o_"+getFile().getName().split("_")[0]+"_"+bootcount;
			double skew=solution.getValue(skewString);
			double offset=solution.getValue(offsetString);
			if((skew==Double.NaN)||(offset==Double.NaN))
				System.out.println("Missing variable from solutions");
			currentTime=(long)(skew*currentTime+offset);	
			String currentString=currentTime.toString();
		
			setCell(global, currentline, currentString);
		}
		if(insert)
			addDataColumn(timeColumn);
		setTimeColumn(global);
	}


	//TODO: these two method makes unparseble columns
	/*
	 * Possible solution is to hold back the real change until we write the data to disk.
	 * Also make the constructor smarter: add timeformat/decimal separator;
	 * After read the file, change the time/data columns to parseble format (if needed: decimal separator
	 * should be dot; time should be in long: milliseconds after epoch/instrument start).
	 * The epoch time format has no SimpleDateFormat string. Use null for it.
	 * After that, save the formats, and use it for file writing.
	 */
	/**
	 * Formats the time column with given SimpleDateFormat
	 * @param timeformat format of the time
	 */
	public void formatTime(String timeformat){
		if(timeformat==null)
			return;
		SimpleDateFormat format=new SimpleDateFormat(timeformat);
		for(int line=1;line<=getLineNumber();line++){
			try{
				long time=Long.parseLong(getCell(timeColumn, line));
				setCell(timeColumn, line, format.format(new Date(time)));
			}catch(NumberFormatException e){
				System.err.println("W: Can't parse time");
			}
			
		}
	}
	
	/**
	 * Changes the default decimal separator in the data columns 
	 * @param decSep New decimal separator
	 */
	public void formatDecimalSeparator(String decSep){
		for(int line=1;line<=getLineNumber();line++){
			for(int column:dataColumns){
				setCell(column,line,getCell(column,line).replace(".", decSep));
			}
		}
	}


	//averageing functions
	private Double getValueAt(long time, int column, int afterLine) throws NumberFormatException{
		while(Long.parseLong(getCell(timeColumn, afterLine))<time){
			afterLine++;
		}
		if(Long.parseLong(getCell(timeColumn, afterLine))==time&&getCell(column,afterLine)!="")
				return Double.parseDouble(getCell(column,afterLine));
		else {
			afterLine++;
			int beforeLine=afterLine-1;
			try{
				String cell=getCell(column,beforeLine);
				while("".equals(cell)){
					cell=getCell(column,--beforeLine);
				}
				cell=getCell(column,afterLine);
				while("".equals(cell)){
					cell=getCell(column,++afterLine);
				}
			} catch (ArrayIndexOutOfBoundsException e){
				return null;
			}
			if(beforeLine<1||afterLine>getLineNumber())
				return null;
			long beforeTime=Long.parseLong(getCell(timeColumn, beforeLine));
			long timeDiff=Long.parseLong(getCell(timeColumn, afterLine))-beforeTime;

			double beforeValue=Double.parseDouble(getCell(column,beforeLine));
			double afterValue=Double.parseDouble(getCell(column,afterLine));
			
			double spine=(afterValue-beforeValue)/timeDiff;
			
			return beforeValue+spine*(time-beforeTime);
		}
	}
	
	public void fillGaps(){
		for(int column:dataColumns){
			for(int line=1;line<=getLineNumber();line++){
				if("".equals(getCell(column, line))){
					long time=Long.parseLong(getCell(1, line));
					Double value=getValueAt(time, column, line);
					if(value!=null)
						setCell(column, line, value.toString());
				}
			}
		}
	}
	
	private class Integral{
		private Double integral[]=new Double[dataColumns.size()];
		private int lastLine;
		
		public Integral(Double integral2[],int lastLine2){
			setLastLine(lastLine2);
			setIntegral(integral2);
		}

		private void setLastLine(int lastLine2) {
			lastLine=lastLine2;
			
		}

		private void setIntegral(Double integral2[]) {
			integral=integral2;
		}

		public int getLastLine() {
			return lastLine;
		}
		
		public String[] createLine(long time){
			String ret[]=new String[header.size()];
			int maxColumn=timeColumn>dataColumns.get(dataColumns.size()-1)?timeColumn:dataColumns.get(dataColumns.size()-1);
			int dataIndex=-1;
			for(int i=0;i<maxColumn;i++){
				if(i+1==timeColumn)
					ret[i]=String.valueOf(time);
				else if(dataColumns.contains(i+1)){
					dataIndex++;
					if(integral[dataIndex]!=null)
						ret[i]=String.valueOf(integral[dataIndex]);
					else
						ret[i]="";
				}else
					ret[i]="";
			}
			return ret;
		}
	}
	/**calculates the integral between from and to
	 * 
	 * @param from
	 * @param to
	 * @param afterLine
	 * @return
	 * @throws NumberFormatException
	 */
	private Integral getIntegral(long from, long to, int afterLine) throws NumberFormatException{
		while(Long.parseLong(getCell(timeColumn, afterLine))<from){
			afterLine++;
		}
		Double ret[]=new Double[dataColumns.size()];
		int line=afterLine;
		for(int j=0;j<dataColumns.size();j++){
			line=afterLine;
			double prevValue,returnElement;
			double currValue;
			try{
				currValue=Double.parseDouble(getCell(dataColumns.get(j),line));
			} catch(NumberFormatException e){
				ret[j]=null;
				continue;
			}
			long prevTime=from,currTime=Long.parseLong(getCell(timeColumn, line));
			if(Long.parseLong(getCell(timeColumn, line))!=from){
				returnElement=((getValueAt(from, dataColumns.get(j), line)+currValue)/2)*(currTime-prevTime);
			} else{
				returnElement=0;
			}
			
			prevValue=currValue;
			prevTime=currTime;
			currTime=Long.parseLong(getCell(timeColumn, ++line));
			boolean outOfData=false;
			while(currTime<to){
				try{
					currValue=Double.parseDouble(getCell(dataColumns.get(j),line));
					returnElement+=((prevValue+currValue)/2)*(currTime-prevTime);
					prevValue=currValue;
					prevTime=currTime;
					currTime=Long.parseLong(getCell(timeColumn, ++line));
				} catch(NumberFormatException e){
					outOfData=true;
					break;
				} catch(IndexOutOfBoundsException e){
					outOfData=true;
					break;
				}
			}
			if(outOfData)
				continue;
			
			if(currTime==to){
				currValue=Double.parseDouble(getCell(dataColumns.get(j),line));
			} else if(currTime<to){
				currValue=getValueAt(to, dataColumns.get(j), line);
			} 
			returnElement+=((prevValue+currValue)/2)*(currTime-prevTime);
			ret[j]=returnElement/(to-from);
		}
		return new Integral(ret,line);
	}
	
	
	public static final byte TIMETYPE_START=0;
	public static final byte TIMETYPE_END=1;
	public static final byte TIMETYPE_MIDDLE=2;
	
	/**
	 * Calculates the averages of the data columns in given lengths 
	 * @param timeWindow Length of each averaging.
	 * @param newFile File for the averaged data (other attributes, like separator will be the same as this instance) 
	 * @param timeType sets the time to use in the averaged time column:
	 * TIME_START: The start of the window; TIME_END: The end of the window; TIME_MIDDLE:The middle of the window
	 * @return a new CSVHandler calculated from this instance
	 * @throws IOException if can't create a new file
	 */
	public CSVHandler averageInTime(long timeWindow, File newFile, byte timeType, long startTime) throws IOException{
		newFile.delete();
		CSVHandler ret=new CSVHandler(newFile, header==null?false:true , separator, getTimeColumn(), getDataColumns());
		ret.setHeader(getHeader());
		int currentLine=0;
		long currentTime=-1;
		while(currentTime<startTime){
			try{
				currentLine++;
				currentTime=Long.parseLong(getCell(timeColumn,currentLine));
				
			}catch(NumberFormatException e){
				//currentLine++;	//search for the first line which is greater than startTime
			}
		}
		while(currentLine<getLineNumber()){
			try{
				Integral avg=getIntegral(startTime, startTime+timeWindow, currentLine);
				if(timeType==TIMETYPE_END)
					ret.addLine(avg.createLine(startTime+timeWindow));
				else if(timeType==TIMETYPE_MIDDLE)
					ret.addLine(avg.createLine(startTime+timeWindow/2));
				else
					ret.addLine(avg.createLine(startTime));
				
				currentLine=avg.getLastLine();
				startTime=startTime+timeWindow;
			}catch(NumberFormatException e){
				currentTime=Long.parseLong(getCell(timeColumn,++currentLine)); //don't care these lines, probably no globaltime
			}
		}
		
		return ret;
	}
	
	//TODO: transpose method. This creates unparseble data. Possible solution: see the previous TODO; priority: medium
	//TODO: main method. Open file, make one change (selected in arg), save;  priority: medium
	
	
	

}
