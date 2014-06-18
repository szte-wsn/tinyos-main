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
package org.szte.wsn.dataprocess.file;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;

public class GapConsumer{
	private ArrayList<Gap> gaps = new ArrayList<Gap>();  
	private File gapFile; 	
	
	public GapConsumer(String path) {
		int endOfFileName=path.contains(".")?path.lastIndexOf("."):path.length();
			String gapPath=path.substring(0,endOfFileName)+".gap"; //TODO
			initGapFile(gapPath);		
	}
	
	private void initGapFile(String gapPath){			
			gapFile=new File(gapPath);
			if(gapFile.exists()){
				BufferedReader input;
				try {
					input = new BufferedReader(new FileReader(this.gapFile));
					String line=null;
					while (( line = input.readLine()) != null){
						System.out.print("\n New gap:"+line);
						String[] vars=line.split(" ");
						if(vars.length!=3){
							//TODO error handling
						}
						if(vars[2]=="T")
							addGap(Long.parseLong(vars[0]), Long.parseLong(vars[1]),true);
						else
							addGap(Long.parseLong(vars[0]), Long.parseLong(vars[1]),false);
					}
					System.out.println();
				} catch (FileNotFoundException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				} catch (NumberFormatException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}else {
				System.out.println("Gapfile doesn't exist: "+gapPath);
			}	
	}
	
	private void addGap(long start, long end, boolean unrepairable) {
		gaps.add(new Gap(start,end,unrepairable));		
	}	
	
	public ArrayList<Gap> getGaps() {
		return gaps;
	}
	public void setGaps(ArrayList<Gap> gaps) {
		this.gaps = gaps;
	}
	
	public File getGapFile() {
		return gapFile;
	}
	
}
