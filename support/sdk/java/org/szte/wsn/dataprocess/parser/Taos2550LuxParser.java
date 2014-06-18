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
 * Author: Andras Biro
 */
package org.szte.wsn.dataprocess.parser;


public class Taos2550LuxParser extends Taos2550Parser{

	public Taos2550LuxParser(String name, String type) {
		super(name, type);
		signed=false;
		size=2;
	}
	
	@Override
	/**
	 * @return the brightness (in Lux) at the first place of the String array
	 */
	public String[] parse(byte[] packet)
	{
		int visibleAndInfra=super.byteToCount(packet[0]);
		int infra=super.byteToCount(packet[1]);
		double lux;
		if(infra!=visibleAndInfra){
			double r=infra/(visibleAndInfra-infra);
			lux=(visibleAndInfra-infra)*0.39*Math.exp(-0.181*r*r);
		}else{
			lux=(visibleAndInfra-infra)/2;
		}
		
		return new String[]{Double.toString(lux)};
	}
	
	/**
	 * constructs byte[] from a brightness represented in String (in lux)
	 * @param stringValue constructs byte[] from it 
	 * @return byte[]
	 */
	public byte[] construct(String[] stringValue)
	{
		//TODO
		return null;	
	}

}
