import static java.lang.System.out;
import java.util.ArrayList;
import java.util.Arrays;

import java.io.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

class DataCollector{

  //for 1. and 2. Super frame structure
  //public static final int NUMBER_OF_INFRAST_NODES = 4;
  //public static final int NUMBER_OF_FRAMES = 4;          
  //public static final int NUMBER_OF_SLOT_IN_FRAME = 3;  //not 4 because one slot for sync

  //for 3. Super frame structure
  public static final int NUMBER_OF_INFRAST_NODES = 5;
  public static final int NUMBER_OF_FRAMES = 5;          
  public static final int NUMBER_OF_SLOT_IN_FRAME = 2;  //not 3 because one slot for sync
  public static final int NUMBER_OF_RX = 6;

  public static final int NUMBER_OF_SLOTS_IN_SF = NUMBER_OF_SLOT_IN_FRAME*NUMBER_OF_FRAMES;

  public static final int TX = 0;
  public static final int RX = 1;

  //SYNC receive sequence (node ids)
  public static final int[] SEQ = 
  {
      1,2,3,4,5
  };

  // 1. Super frame structure
  //public static final int[][] SF_slots = 
  //{ {TX, TX, RX, RX, RX, TX, TX, TX, RX, RX, RX, TX} ,
    //{TX, RX, TX, TX, RX, RX, TX, RX, TX, TX, RX, RX} ,
    //{RX, RX, RX, TX, TX, TX, RX, RX, RX, TX, TX, TX} ,
    //{RX, TX, TX, RX, TX, RX, RX, TX, TX, RX, TX, RX} };

  // 2. Super frame structure
  //public static final int[][] SF_slots = 
  //{ {TX, TX, RX, TX, TX, RX, TX, TX, RX, RX, RX, RX} ,
    //{RX, RX, RX, TX, RX, TX, TX, RX, TX, TX, TX, RX} ,
    //{TX, RX, TX, RX, RX, RX, RX, TX, TX, TX, RX, TX} ,
    //{RX, TX, TX, RX, TX, TX, RX, RX, RX, RX, TX, TX} };

  // 3. Super frame structure
  public static final int[][] SF_slots = 
  { {TX, RX, RX, RX, TX, TX, RX, RX, RX, TX} ,
    {TX, TX, RX, RX, RX, TX, TX, RX, RX, RX} ,
    {RX, TX, TX, RX, RX, RX, TX, TX, RX, RX} ,
    {RX, RX, TX, TX, RX, RX, RX, TX, TX, RX} ,
    {RX, RX, RX, TX, TX, RX, RX, RX, TX, TX} };


  ArrayList<Slot> slots;  //Store slots
  int node_index;   //The actual node index in SEQ array
  int frame_prev;   //prev frame
  int sf_cnt;     //sf counter
  static int terminal_write_option;  //0 - incoming data, 1 - superframe

  class Node {
	  int id;
	  int freq;
	  int phase;
    int min;
    int max;
    int dataStart;
	
	  public Node(int id, int freq, int phase, int min, int max, int dataStart) {
		  this.id = id;
		  this.freq = freq;
		  this.phase = phase;
      this.min = min;
      this.max = max;
      this.dataStart = dataStart; 
	  }
	
	  public int getID() {
		  return id;
	  }
	
	  public int getFreq() {
		  return freq;
	  }	
	
	  public int getPhase() {
		  return phase;
	  }
    
    public int getMin() {
      return min;
    }

    public int getMax() {
      return max;
    }

    public int getDataStart() {
      return dataStart;
    }

    public void setFreq(int freq) {
      this.freq = freq;
    }

    public void setPhase(int phase) {
      this.phase = phase;
    }

    public void setMin(int min) {
      this.min = min;
    }

    public void setMax(int max) {
      this.max = max;
    }

    public void setDataStart(int dataStart) {
      this.dataStart = dataStart;
    }

    public String toString() {
      return "id: " + id + " dataStart: " + dataStart + " freq: " + freq + " phase: " + phase + " min: " + min + " max: " + max;
    }
  }

  class Slot {
 	  ArrayList<Integer> trans;   //TX
	  ArrayList<Node> nodes;      //RX
	
	  public Slot() {
		  this.trans = new ArrayList<Integer>();
		  this.nodes = new ArrayList<Node>();
	  }

    public Slot(int index) {
      this.trans = new ArrayList<Integer>();
		  this.nodes = new ArrayList<Node>();
      for(int i=0; i<NUMBER_OF_INFRAST_NODES; i++)
        if(SF_slots[i][index] == TX) 
          trans.add(SEQ[i]);
        else 
          nodes.add(new Node(SEQ[i],-1,-1,-1,-1,-1));
	  }
	
	  public void addTrans(int t) {
		  trans.add(t);
	  }	
	
	  public  void addNode(Node node) {
		  nodes.add(node);
	  }

    public void setNode(Node n, int id) {
      for(int i=0; i<nodes.size(); i++) {
        if(nodes.get(i).getID() == id) {
          nodes.set(i,n);
          break;
        }
      }
    }
	
	  public ArrayList<Integer> getTrans() {
		  return this.trans;
	  }

    public boolean isTXNode(int index) {
      return trans.indexOf(index)!=-1;
    }
	
	  public Node getNodeData(int id) {
	    for(Node n : nodes) {
        if(n.getID() == id) {
          return n;
        }
      }
      return new Node(-1,-1,-1,-1,-1,-1);   //default
	  }
	
	  public ArrayList<Node> getAllNode() {
		  return nodes;
	  }
	
	  public int getNodeFreq(int id) {
		  return nodes.get(nodes.indexOf(id)).getFreq();
	  }
	
	  public int getNodePhase(int id) {
		  return nodes.get(nodes.indexOf(id)).getPhase();
	  }

    public int getNodeMin(int id) {
      return nodes.get(nodes.indexOf(id)).getMin();
    }

    public int getNodeMax(int id) {
      return nodes.get(nodes.indexOf(id)).getMax();
    }

    public int getNodedataStart(int id) {
      return nodes.get(nodes.indexOf(id)).getDataStart();
    }
  }

  public void initalize() {
    slots = new ArrayList<Slot>(5);
    node_index = 0;
    sf_cnt = 0;
    frame_prev = -1;
  }


  public DataCollector(PacketSource reader){
		initalize();
    try {
      reader.open(PrintStreamMessenger.err);
      for (;;) {
        byte[] packet = reader.readPacket();
        printPacketTimeStamp(System.out, packet);
        //System.out.println();
        System.out.flush();
      }
    }
    catch (IOException e) {
        System.err.println("Error on " + reader.getName() + ": " + e);
    }
	}

  public void printPacketTimeStamp(PrintStream p, byte[] packet) {
    short[] freq = new short[NUMBER_OF_RX];
    byte[] phase = new byte[NUMBER_OF_RX];
    byte[] min = new byte[NUMBER_OF_RX];
    byte[] max = new byte[NUMBER_OF_RX];
    byte[] dataStart = new byte[NUMBER_OF_RX];
    int frame_index = 0;
    if(terminal_write_option == 0) {
		  p.print("AM type: "+(int)(packet[0] & 0xFF)+ "\n");
		  p.print("Destination address:");
    }
		int a1 = packet[1] & 0xFF;
		int a2 = packet[2] & 0xFF;
		a2<<=8;
		a1 = (a1 | a2) & 0x0000FFFF;
    if(terminal_write_option == 0) {
		  p.print(a1 + "\n");
		  p.print("Link source address:");
    }
		a1 = packet[3] & 0xFF;
		a2 = packet[4] & 0xFF;
		a1<<=8;
		a1 = (a1 | a2) & 0x0000FFFF;
    if(terminal_write_option == 0) 
	    p.print(a1 + "\n");
    node_index = Arrays.binarySearch(SEQ, a1);
    //if(terminal_write_option == 0) 
      //p.print("node_index: " + node_index + "\n");
		int len = (int)(packet[5] & 0xFF);
    if(terminal_write_option == 0) {
	    p.print("Message length "+len+" \n");
	    p.print("Group ID: "+(int)(packet[6] & 0xFF)+" \n");
	    p.print("AM handler type: "+(int)(packet[7] & 0xFF)+" \n");
	    p.print("Data:\n");
    }
    frame_index = packet[8] & 0xFF;
    int tmp = 0;
    for(int i=9; i<9+(NUMBER_OF_RX); i++) {
      int b1 = packet[i] & 0xFF;
      if(terminal_write_option == 0) 
        p.print(tmp + ".dataStart: " + b1 + "\n");
      dataStart[tmp++] = (byte)b1;
    }
    tmp = 0;
		for(int i=9+(NUMBER_OF_RX); i<9+(NUMBER_OF_RX*3); i+=2) {    
		  int b1 = packet[i] & 0xFF;
      int b2 = packet[i+1] & 0xFF;
      b1 <<= 8;
      b1 = (b1 | b2) & 0x0000FFFF;
      if(terminal_write_option == 0) 
        p.print(tmp + ".freq: " + b1 + "\n");
      freq[tmp++] = (short)b1;
    }
    tmp = 0;
    for(int i=9+(NUMBER_OF_RX*3); i<9+(NUMBER_OF_RX*4); i++) {
      int b1 = packet[i] & 0xFF;
      if(terminal_write_option == 0) 
        p.print(tmp + ".phase: " + b1 + "\n");
      phase[tmp++] = (byte)b1;
    }
    tmp = 0;
    for(int i=9+(NUMBER_OF_RX*3); i<9+(NUMBER_OF_RX*4); i++) {
      int b1 = packet[i] & 0x0F;
      int b2 = packet[i] & 0xF0;
      b2 >>= 3;
      if(terminal_write_option == 0) 
        p.print(tmp + ".min: " + b1 + " max: " + b2 + "\n");
      min[tmp] = (byte)b1;
      max[tmp++] = (byte)b2;
    }
    if(terminal_write_option == 0) 
		  p.print(" \n");
		//long b1 = packet[8+len-4] & 0xFF;
		//long b2 = packet[8+len-3] & 0xFF;
		//b2 <<= 8;
		//long b3 = packet[8+len-2] & 0xFF;
		//b3 <<= 16;
		//long b4 = packet[8+len-1] & 0xFF;
		//b4 <<= 24;
    //p.print("b1: " + b1 + " b2: " + b2+ " b3: " + b3 + " b4: " + b4 + "\n");
		//b1 = (((b1 | b2) | b3) | b4) & 0x00000000FFFFFFFF; 
		//p.print("Timestamp: "+b1+" \n");
    Upload(frame_index, freq, phase, min, max, dataStart);
	}

  //Upload frame with measures    frame numbers: 1,5,9,13
  public void Upload(int frame_mes, short[] freq, byte[] phase, byte[] min, byte[] max, byte[] dataStart) {
    int frame = 0;    //frame counter
    if(frame_prev>=frame_mes) {    //superframe viewer
      DataPrinter();
      sf_cnt++;
    }
    frame = frame_mes-(NUMBER_OF_SLOT_IN_FRAME*node_index) + (sf_cnt*NUMBER_OF_INFRAST_NODES); //hogy a 5.dik frame-t ne 0-t adjon ki a slot_start
    frame_prev = frame_mes;
    int slot_start = (frame-NUMBER_OF_FRAMES) > 0 ? (frame-NUMBER_OF_FRAMES)*NUMBER_OF_SLOT_IN_FRAME : 0; //hanyadik slottol kezdjuk
    int slot_end = slot_start + NUMBER_OF_SLOTS_IN_SF;
    if(terminal_write_option == 0) 
      System.out.println("frame_number: " + frame + "\n-------------------\n");
    int p_cnt = 0;  //hanyadik freq,phase parosnal tartunk
    for(int i=slot_start; i<slot_end; i++) {
      try{    
        Slot s = slots.get(i);      
        if(SF_slots[node_index][i%NUMBER_OF_SLOTS_IN_SF] == RX) {
          Node n = s.getNodeData(SEQ[node_index]);
          n.setFreq(freq[p_cnt]);
          n.setPhase(phase[p_cnt]);
          n.setMin(min[p_cnt]);
          n.setMax(max[p_cnt]);
          n.setDataStart(dataStart[p_cnt]);
          s.setNode(n, SEQ[node_index]);
          slots.set(i,s);
          p_cnt++;
        }
      } catch (IndexOutOfBoundsException e) {
        Slot s = new Slot(i%NUMBER_OF_SLOTS_IN_SF);
        if(SF_slots[node_index][i%NUMBER_OF_SLOTS_IN_SF] == RX) {
          Node n = s.getNodeData(SEQ[node_index]);
          n.setFreq(freq[p_cnt]);
          n.setPhase(phase[p_cnt]);
          n.setMin(min[p_cnt]);
          n.setMax(max[p_cnt]);
          n.setDataStart(dataStart[p_cnt]);
          s.setNode(n,SEQ[node_index]);
          p_cnt++;
        } 
        slots.add(s);
      }
    }
  }


  //public ArrayList<Integer> RelativePhase(int index_1, int index_2) {
    //ArrayList<Integer> relPhase = new ArrayList<Integer>();
    //for(int i=0; i<slots.size(); i++) {
      //ArrayList<Node> nodes = slots.get(i).getAllNode();
      //relPhase.add();
    //}
    //return relPhase;
  //}  

  public void DataPrinter() {
    try {
      if(sf_cnt>0) {
        File dir = new File("measures/");
     		dir.mkdirs();
     		if (null != dir) 
     			dir.mkdirs();
        dir = new File("measures/SF");
     		dir.mkdirs();
     		if (null != dir) 
     			dir.mkdirs();
        dir = new File("measures/Slots");
     		dir.mkdirs();
     		if (null != dir) 
     			dir.mkdirs();
        String pathprefix_sf = "measures/SF/" + sf_cnt + "_SF";	
        FileWriter fw_sf = new FileWriter(pathprefix_sf + ".txt", true);	
     		BufferedWriter out_sf = new BufferedWriter(fw_sf);
        for(int i = (sf_cnt-1)*NUMBER_OF_SLOTS_IN_SF; i<sf_cnt*NUMBER_OF_SLOTS_IN_SF; i++) {
          Slot item = slots.get(i);
       		String pathprefix = "measures/Slots/" + i + "_slot";	
          FileWriter fw = new FileWriter(pathprefix + ".txt");	
       		BufferedWriter out = new BufferedWriter(fw);
          out.write("TX:\n"+item.getTrans()+"\nRX:\n"+item.getAllNode());
          out_sf.write("TX:\n"+item.getTrans()+"\nRX:\n"+item.getAllNode() + "\n\n");
          if(terminal_write_option == 1) 
            System.out.println("TX:\n"+item.getTrans()+"\nRX:\n"+item.getAllNode() + "\n");
          out.close();
				  fw.close();
        }
        out_sf.close();
			  fw_sf.close();
      }
    } catch (IOException e) {
      e.printStackTrace();
    }
    if(terminal_write_option == 1) 
      System.out.println("--------------------------------------------");
  }

  public static void main(String[] args) throws Exception 
  {
    String source = null;
    PacketSource reader;
    terminal_write_option = 0;
    if(args.length == 0 || args[0].equals("-comm")){
      System.err.println("usage: java BaseStationApp [--moteMes or --SF] [-comm <source>]");
      System.exit(1);
	  } else if(args.length == 1) {
	    if(args[0].equals("--SF"))
  	    terminal_write_option = 1;
      else if(args[0].equals("--moteMes"))
        terminal_write_option = 0;
        else {
          System.err.println("usage: java BaseStationApp [--moteMes or --SF] [-comm <source>]");
          System.exit(1);
        }
	  } else if(args.length >= 2 && args[1].equals("-comm")) {
	    if(args[0].equals("--SF"))
  	    terminal_write_option = 1;
	    source = args[2];
	  } else {
      System.err.println("usage: java BaseStationApp [--moteMes or --SF] [-comm <source>]");
		  System.exit(1);
	  }
    if (source == null) {	
      reader = BuildSource.makePacketSource();
    } else {
      reader = BuildSource.makePacketSource(source);
    }
    if (reader == null) {
      System.err.println("Invalid packet source (check your MOTECOM environment variable)");
      System.exit(2);
    }
	  DataCollector app = new DataCollector(reader); 	
  }

}
