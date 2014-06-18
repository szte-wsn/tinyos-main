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

import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;


import org.szte.wsn.dataprocess.parser.ArrayParser;
import org.szte.wsn.dataprocess.parser.ConstParser;
import org.szte.wsn.dataprocess.parser.IntegerParser;
import org.szte.wsn.dataprocess.parser.Sht11HumidityParser;
import org.szte.wsn.dataprocess.parser.Sht11TempParser;
import org.szte.wsn.dataprocess.parser.StructParser;
import org.szte.wsn.dataprocess.parser.Taos2550LuxParser;
import org.szte.wsn.dataprocess.parser.Taos2550Parser;


public class PacketParserFactory {	
	PacketParser[] packetParsers;

	/**
	 * 
	 * @param fileName location of configuration file
	 */
	public PacketParserFactory(String fileName){			
		loadConfig(fileName);		
	}
	/**
	 * 
	 * @param fileName loads configuration from the fileName
	 * to packetParsers array
	 */
	void loadConfig(String fileName){

		ArrayList<PacketParser> returnArray=new ArrayList<PacketParser>();
		ArrayList<String[]> ids=new ArrayList<String[]>();

		FileInputStream file;
		byte[] bArray=null; 

		try {
			file = new FileInputStream(fileName);
			bArray = new byte[file.available ()];
			file.read(bArray);
			file.close ();
		} 
		catch (IOException e) {

			System.out.println("IO ERROR while opening: "+fileName);
			e.printStackTrace();
			System.exit(1);			
		}

		String strLine = new String (bArray);
		String[] words;

		words=strLine.split(";");					//separates the input into commands
		int wc=0; 									// word counter	
		while(wc<words.length-1){
			words[wc]=words[wc].trim();				//removes the white spaces from the beginning and the end of the phrase
			if(!words[wc].contains("struct")){			//simple variable

				String[] parts=words[wc].split(" ");	
				String parserName=parts[parts.length-1];
				String parserType=words[wc].substring(0, (words[wc].length()-parserName.length())).trim();
				PacketParser pp=getPacketParser(returnArray.toArray(new PacketParser[returnArray.size()]), parserName, parserType);
				if(pp!=null){	
					checkName(pp,returnArray, fileName);
					checkSize(pp,returnArray, fileName);
					returnArray.add(pp);
				}
				else{
					System.err.println("Error: not existing type: \""+parserType+"\" in "+ fileName);
					System.exit(1);
				}
			}
			else{
				ArrayList<PacketParser> variableArray=new ArrayList<PacketParser>();
				String[] parts=words[wc].split("\\{");

				parts=parts[0].split(" ");
				String parserName=parts[parts.length-1].replaceAll("[^\\w]", "");				

				words[wc]=words[wc].split("\\{")[1];
				while((wc<words.length)&&(!words[wc].contains("}"))){

					words[wc]=words[wc].trim();
					parts=words[wc].split(" ");
					String variableName=parts[parts.length-1];
					String variableType=words[wc].substring(0, (words[wc].length()-variableName.length())).trim();

					PacketParser pp=getPacketParser(returnArray.toArray(new PacketParser[returnArray.size()]), variableName, variableType);
					if (variableName.contains("=")){
						String[] idNameAndValue=variableName.split("=");						
						ids.add(new String[]{parserName,idNameAndValue[0],idNameAndValue[1]});						
					}
					if(pp!=null){				
						checkName(pp, variableArray, fileName);
						variableArray.add(pp);
					}
					else{
						System.out.println("Error: not existing type: \""+variableType+"\" in "+ fileName);
						System.exit(1);
					}

					wc++;

				}				
				PacketParser sp=new StructParser(parserName,"struct", variableArray.toArray(new PacketParser[variableArray.size()]));
				checkName(sp, returnArray,fileName);
				checkSizeAndId(sp, returnArray, ids, fileName);
				returnArray.add(sp);						

			}
			wc++;


		}//while ends here


		packetParsers=returnArray.toArray(new PacketParser[returnArray.size()]);
	}

	/**
	 * Checks whether the name already exist in parsers, 
	 * @param cp PacketParser
	 * @param parsers ArrayList of existing parsers
	 * @param fileName name of parsed file
	 */
	private void checkName(PacketParser cp, ArrayList<PacketParser> parsers, String fileName) {
		for(PacketParser pp:parsers){
			if (pp.getName().equals(cp.getName())){
				System.err.println("Error: during parse of "+fileName+". Duplicate parser name on same level: "+pp.getName()+ " ! Would indicate unpredictable running. Program will exit.");
				System.exit(1);
			}	
		}
	}
	/**
	 * Checks whether there is a parser with the same size without id
	 * @param cp PacketParser
	 * @param parsers ArrayList of existing parsers
	 * @param fileName name of parsed file
	 */
	private void checkSize(PacketParser cp, ArrayList<PacketParser> parsers, String fileName) {
		for(PacketParser pp:parsers){			
			if(cp.getPacketLength()==pp.getPacketLength()){
				System.err.println("Error: during parse of "+fileName+". Simple parser: "+cp.getName()+ " has the same length an existing parser: "+pp.getName()+ " ! Would indicate unpredictable running. Program will exit.");
				System.exit(1);
			}				
		}
	}
	/**
	 * Checks whether there is a parser with the same size and id
	 * @param cp PacketParser
	 * @param parsers ArrayList of existing parsers
	 * @param fileName name of parsed file
	 * @param ids ArrayList of used [StructName, IdName, IdValue]
	 */
	private void checkSizeAndId(PacketParser cp, ArrayList<PacketParser> parsers, ArrayList<String[]> ids, String fileName) {
		if(ids.size()>0){
			String[] idAct=ids.get(ids.size()-1);				
			for(String[] id:ids){
				PacketParser parser=getParser(id[0],parsers.toArray(new PacketParser[parsers.size()]));
				if((parser!=null)&&(parser.getPacketLength()==cp.getPacketLength())&&(idAct[2].equals(id[2]))){							
					System.err.println("Error: during parse of "+fileName+". Struct parser: "+cp.getName()+ " has the same length and id as an existing parser: "+parser.getName()+ " ! Would indicate unpredictable running. Program will exit.");
					System.exit(1);
				}
			}
		}
	}




	/**
	 * 
	 * @return returns the PacketParsers which are available 
	 */
	public PacketParser[] getParsers(){				
		return packetParsers;
	}

	/**
	 * 
	 * @param name returns the PacketParser from the parsers array
	 *  which has the same name
	 * @return PacketParser
	 */
	public static PacketParser getParser(String name, PacketParser[] parsers ){
		for(int i=0;i<parsers.length;i++){
			if(parsers[i].getName().equals(name))
				return parsers[i];
		}			
		return null;
	}


	/**
	 * 
	 * @param packetArray existing PacketParsers
	 * @param name param of the new PacketParser
	 * @param type param of the new PacketParser
	 * @return new PacketParser according to the parameters,
	 *  null if the type doesn't fit on any available PacketParser
	 */
	public static PacketParser getPacketParser(PacketParser[] packetArray, String name, String type){
		int pos=contains(packetArray,type);
		if((name.contains("="))&&(type.contains("int"))){
			String[] parts=name.split("=");
			return new ConstParser(parts[0], type, parts[1]);
		}
		else if(pos>-1){
			return packetArray[pos];
		}	
		else if(name.contains("[")){
			//size of the array
			int size=Integer.parseInt(name.substring(name.indexOf("[")+1,name.indexOf("]")));

			return new ArrayParser(getPacketParser(packetArray, name.substring(0,name.indexOf("[")), type), size);  //deletes the [n] tag to avoid recursion 
		}
		else if(type.contains("int"))
		{ 		
			return new IntegerParser(name, type);
		}
		else if(type.contains("sht11humidity"))
		{
			return new Sht11HumidityParser(name, type);
		}
		else if(type.contains("sht11temp"))
		{
			return new Sht11TempParser(name, type);
		}
		else if(type.contains("taos2550lux"))
		{
			return new Taos2550LuxParser(name, type);
		}
		else if(type.contains("taos2550"))
		{
			return new Taos2550Parser(name, type);
		}
		else
			return null;
	}

	/**
	 * 
	 * @param packetArray already existing PacketParsers
	 * @param type searched type
	 * @return the position of this type in the PacketArray, 
	 * or -1 if it isn't in it
	 */
	public static int contains(PacketParser[] packetArray,String type) {
		String parts[]=type.split(" ");
		for(int i=0;i<packetArray.length;i++)
			if(packetArray[i].getName().equals(parts[parts.length-1]))
				return i;
		return -1;
	}

}