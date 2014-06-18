/** Copyright (c) 2010, University of Szeged
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
* Author: Miklos Maroti
*/

package org.szte.wsn.echoranger;

import java.io.*;
import java.util.*;

public class Transpose
{
	static List<List<String>> lines = new ArrayList<List<String>>();
	static int maxLength;
	static String separator=",";
	
	static void readLine(String line)
	{
		List<String> values = new ArrayList<String>();
		
		StringTokenizer tokenizer = new StringTokenizer(line, separator);
		while( tokenizer.hasMoreTokens() )
			values.add(tokenizer.nextToken());
		
		lines.add(values);
		
		if( maxLength < values.size() )
			maxLength = values.size();
	}
	
	static void printLines()
	{
		for(int i = 0; i < maxLength; ++i)
		{
			for(int j = 0; j < lines.size(); ++j)
			{
				if( j != 0 )
					System.out.print(separator);
				
				if( lines.get(j).size() > i )
					System.out.print(lines.get(j).get(i));
			}
			System.out.println();
		}
	}
	
	public static void main(String[] args) throws FileNotFoundException
	{
		if( args.length > 2 || args.length <1 )
		{
			System.err.println("usage: java Transpose [separator char] input.csv");
			System.exit(1);
		}
		if(args.length==2)
			separator=args[0];
		Scanner scanner = new Scanner(new File(args[args.length-1]));
		try {
			while ( scanner.hasNextLine() ) 
				readLine(scanner.nextLine());
			
			printLines();
		}
		finally {
			scanner.close();
		}
	}
}
