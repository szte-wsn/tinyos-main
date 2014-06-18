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

import java.util.ArrayList;

/**
 * Calculates linear regression from 2 dimensional points
 * @author Andras Biro
 *
 */
public class Regression {
	private ArrayList<Point> points=new ArrayList<Point>();
	private boolean functionNeedsUpdate=true;
	private LinearFunction function;
	private long maxerror;
	private double defaultslope;

	private final class Point{
		private long x,y;
		public long getX() {
			return x;
		}
		public long getY() {
			return y;
		}
		
		public Point(long x, long y){
			this.x=x;
			this.y=y;
		}
	}
	
	/**
	 * Default constructor
	 * @param maxerror Maximum distance of a new point from the already calculated line
	 * @param defaultslope Default slope of the function (if there's only one point)
	 */
	public Regression(long maxerror, double defaultslope){
		this.maxerror=maxerror;
		this.defaultslope=defaultslope;
	}	
	
	/**
	 * Returns maximum distance of a new point from the already calculated line
	 * @return Maximum distance
	 */
	public long getMaxerror() {
		return maxerror;
	}

	/**
	 * Sets the maximum distance of a new point from the already calculated line
	 * @param maxerror Maximum distance
	 */
	public void setMaxerror(long maxerror) {
		this.maxerror = maxerror;
	}
	
	/**
	 * Sets the default slope of the function
	 * @param defaultslope Default slope of the function (if there's only one point)
	 */
	public void setDefaultSlope(double defaultslope) {
		this.defaultslope = defaultslope;
	}

	/**
	 * Returns the default slope of the function
	 * @return Default slope of the function (if there's only one point)
	 */
	public double getDefaultslope() {
		return defaultslope;
	}
	
	/**
	 * @return Number of points in the regression
	 */
	public long getNumPoints() {
		return points.size();
	}
	
	private double calcError(Point pt){
		if(points.size()==0)
			return 0;
		else {
			if(functionNeedsUpdate){
				calculateFunction();
			}
			double ret=pt.getY()-function.getOffset()-function.getSkew()*pt.getX();
			if(ret<0)
				return -1*ret;
			else	
				return ret;
		}
	}
	
	/**
	 * Adds a point into the regression if it's not too far from the line
	 * @param x X coordinate
	 * @param y Y coordinate
	 * @return false if the point is farer from the line than maxerror, true otherwise
	 */
	public boolean addPoint(long x,long y){
		Point p=new Point(x,y);
		if(calcError(p)<maxerror){
			points.add(new Point(x,y));
			functionNeedsUpdate=true;
			return true;
		}else
			return false;
	}
	
	/**
	 * Adds a point into the regression
	 * @param x X coordinate
	 * @param y Y coordinate
	 */
	public void addPointNoVerify(long x,long y){
		points.add(new Point(x,y));
		functionNeedsUpdate=true;
	}
	
	/**
	 * @return The calculated functionSSS
	 */
	public LinearFunction getFunction(){
		if(functionNeedsUpdate){
			calculateFunction();
		}
		return function;
	}

	private LinearFunction calculateFunction() {
		double slope,offset;
		if(points.size()<=0)
			return null;
		if(points.size()>=2){//linear regression
			double avg_x=0, avg_y=0;
			for(Point pt:points){
				avg_x+=pt.getX();
				avg_y+=pt.getY();
			}
			avg_x/=points.size();
			avg_y/=points.size();
			double denom=0,numer=0;
			for(Point pt:points){
				numer+=(pt.getX()-avg_x)*(pt.getY()-avg_y);
				denom+=(pt.getX()-avg_x)*(pt.getX()-avg_x);
			}
			slope=numer/denom;
			offset=avg_y-slope*avg_x;							
		} else{//only one point => we suppose that slope==defaultslope
			slope=defaultslope;
			offset=points.get(0).getY()-points.get(0).getX();
		}
		function=new LinearFunction(offset, slope);
		functionNeedsUpdate=false;
		return function;
	}


	
	
}
