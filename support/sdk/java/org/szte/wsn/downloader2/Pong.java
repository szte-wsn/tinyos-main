package org.szte.wsn.downloader2;

public final class Pong{
	private long minaddress, maxaddress;
	private int nodeid;
	
	public Pong(int nodeid,long minaddress,long maxaddress) {
		this.minaddress=minaddress;
		this.maxaddress=maxaddress;
		this.nodeid=nodeid;
	}
	
	public long getMinAddress(){
		return minaddress;
	}
	
	public long getMaxAddress(){
		return maxaddress;
	}
	
	public int getNodeID(){
		return nodeid;
	}
}
