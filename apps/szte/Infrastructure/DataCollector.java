import static java.lang.System.out;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.lang.Math.*;

import java.io.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

import javax.swing.JFrame;
import javax.swing.JPanel;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.KeyEvent;
import javax.swing.ImageIcon;
import javax.swing.JFrame;
import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;
import javax.swing.KeyStroke;
import javax.swing.SwingUtilities;
import javax.swing.AbstractAction;  

class PlotFunctionPanel extends JPanel { 
  
  int width,heigth;
  int posX;
  public int[][] data;  //first dim: mote index, second dim: rel phases
  public int whichSlot;
  int startX;
  int startY;
  int MAX = 500;    //last MAX measure plotted
  int frame_number;
  public int whichMote;
	public boolean pairs;
	static final int bufferLength = 500;
	Node[] nodes1;
	Node[] nodes2;
	
	public PlotFunctionPanel(int width,int heigth, int numberOfRx, int frame_number){
		this.width = width;
		this.heigth = heigth;
		this.frame_number = frame_number;
		//data = new int[node_number][][bufferLength];
		//whichMote = 0;
		setPreferredSize(new Dimension(width, heigth));
  }
  
  public void paintComponent(Graphics g){
    Font font = new Font("font",3,20);
		super.paintComponent(g); 
    Graphics2D g2d = (Graphics2D) g.create();
		g2d.setFont(font);
		g2d.setColor(Color.BLACK);
		System.out.println("\n\n\n slots.getAllNode().size(): " + DataCollector.slots.get(0).getAllNode().size() + " slots.size(): " + DataCollector.slots.size() + " frame_number: " + frame_number + "\n\n\n");
		int start = DataCollector.slots.size()-MAX*frame_number<0 ? 0 : DataCollector.slots.size()-MAX*frame_number;
		posX = 0;
	  if(pairs) {
      posX = 0;
      startX = 100;
      startY = 100;
      for(int i=start; i<DataCollector.slots.size()-2*frame_number; i++){
        //for(int j = 0; j<2; j++) {
          int k = 0;
          nodes1 = new Node[DataCollector.slots.get(i).NodesNumber()];
          nodes2 = new Node[DataCollector.slots.get(i+frame_number).NodesNumber()];
	        Iterator<Node> it1 = DataCollector.slots.get(i).getAllNode().iterator();
	        Iterator<Node> it2 = DataCollector.slots.get(i+frame_number).getAllNode().iterator();
	        while(it1.hasNext()) { 
//(Math.abs(n.getPhase() - nodes.get(0).getPhase())%nodes.get(0).getFreq())	        
	          nodes1[k] = it1.next();
	          nodes2[k++] = it2.next();
	        }
	        
	        for(int j=1; j<nodes1.length; j++) {
	          startY += (j-1)*100;
	        //Slot item = slots.get(data_writer_cnt);
	        //item.getNodedataStart(i);
	        //g2d.drawLine(startX+k,startY-DataCollector.slots.get(j).getNodedataStart(i),startX+(k+1),startY-DataCollector.slots.get(j+frame_number).getNodedataStart(i));
	          g2d.drawLine(startX+posX,startY+(Math.abs(nodes1[j].getPhase() - nodes1[0].getPhase())%nodes1[0].getFreq()),startX+posX+1,startY+(Math.abs(nodes2[j].getPhase() - nodes2[0].getPhase())%nodes2[0].getFreq()));
	          //startY += +(Math.abs(nodes1[j].getPhase() - nodes1[0].getPhase())%nodes1[0].getFreq()) + (Math.abs(nodes2[j].getPhase() - nodes2[0].getPhase())%nodes2[0].getFreq());
	        g2d.drawString("KK " + (startX+posX) + " " + (startY) + " " + (startX+posX+1) + " " + (startY) + " " + whichSlot + " " + i + " " + (DataCollector.slots.size()-2*frame_number) + " " + frame_number + " " + posX,startX+100,startY+100);
	        }
	      posX++;
	      /*if(posX<MAX)
	        posX++;
	      else
	        posX = 0;*/
	    } 
	  }
	  //g2d.drawString("Ready: ",startX-10, startY-10);
	  //g2d.drawString("Slots.size(): " +  " DataCollector.slots.get(0).getAllNode().size(): " + " : " + pairs,startX+20,startY+20);
		repaint();
	}
}

class SomeAction extends AbstractAction {  
	int control;
	PlotFunctionPanel panel;
	boolean pairs;
  public SomeAction(String text, int temp, PlotFunctionPanel pnl, boolean pair )  
  {  
    super( text );  
	  control = temp;
	  panel = pnl;
	  pairs = pair;
  }  
    
  public void actionPerformed( ActionEvent e )  
  {  
    if(pairs){
		  panel.pairs = true;
		  panel.whichSlot = control;
	  }else{
		  panel.pairs = false;
		  panel.whichMote = control;
	  }
  }
} 

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
    if(freq == 0)
      return "id: " + id + " invalid data! Frequency = 0\n";
    return String.format("id %2d dataStart: %3d min: %3d max: %3d period: %5d phase: %3d", id, dataStart, min, max, freq, phase);
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
    //System.out.println("Slot index; " + index);
    this.trans = new ArrayList<Integer>();
	  this.nodes = new ArrayList<Node>();
    for(int i=0; i<DataCollector.motesettings.length; i++)
      if(DataCollector.motesettings[i][index] == DataCollector.TX1 || DataCollector.motesettings[i][index] == DataCollector.TX2) 
        trans.add(i);
      else 
        nodes.add(new Node(i,-1,-1,-1,-1,-1));
    //System.out.println("TX:\n"+this.getTrans()+"\nRX:\n"+this.getAllNodeString() + "\n");
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
  
  public String getAllNodeString() {
    String str = "";
    Node relnode = nodes.get(0);
    for(Node n : nodes) {
      if(nodes.get(0).getFreq() == 0 || n.getFreq() == 0) 
        str += "RX: " + n;
      else
        str += "RX: " + n + "\t relphase: " + (Math.abs(n.getPhase() - nodes.get(0).getPhase())%nodes.get(0).getFreq()) + "\n";
    }
    return str;
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
  
  public int NodesNumber() {
    return nodes.size();
  }
}  

class DataCollector extends JFrame {
  
  static PlotFunctionPanel panel;
  static final int frame_window_length = 1000;
  static final int frame_window_height = 700;
  public static DataCollector app;
  int paintCounter = 0;
  
  public static final int TX1 = 0;
  public static final int TX2 = 1;
  public static final int RX = 2;
  public static final int SSYN = 3;
  public static final int RSYN = 4;
  public static final int DEB = 5;
  public static final int NTRX = 6;
  public static final int NDEB = 7;
  public static final int W1 = 8;
  public static final int W10 = 9;
  public static final int W100 = 10;
  public static final int W1k = 11;
//  public static int NUMBER_OF_INFRAST_NODES = 0;
  public static int NUMBER_OF_FRAMES = 0;
//  public static int NUMBER_OF_SLOT_IN_FRAME = 0;
  public static int NUMBER_OF_RX;
  public static int NUMBER_OF_SSYN;
//  public static int NUMBER_OF_SLOTS_IN_SF = 0;
//  public static final int[] SEQ = {3,4};
//  public static final int[][] SF_slots = { {3,4}, {3,4}};
  public static int[] node_slot_cnt; //the last slot index for each note
  
  public static final byte[][] motesettings = {
			//  0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17    18    19
			{RSYN,  TX1,  TX1,  TX1,  W10, SSYN,  TX1,  TX1,   RX,  W10, RSYN,   RX,  TX1,   RX,  W10, RSYN,   RX,   RX,   RX,  W10},
			{RSYN,   RX,   RX,   RX,  W10, RSYN,  TX2,  TX2,  TX1,  W10, SSYN,  TX1,   RX,  TX1,  W10, RSYN,   RX,  TX1,   RX,  W10},
			{RSYN,  TX2,   RX,   RX,  W10, RSYN,   RX,   RX,   RX,  W10, RSYN,  TX2,  TX2,  TX2,  W10, SSYN,  TX1,   RX,  TX1,  W10},
			{SSYN,   RX,  TX2,  TX2,  W10, RSYN,   RX,   RX,  TX2,  W10, RSYN,   RX,   RX,   RX,  W10, RSYN,  TX2,  TX2,  TX2,  W10}
  };
  

  public static ArrayList<Slot> slots;  //Store slots
  //int node_index;   //The actual node index in SEQ array
  int frame_prev;   //prev frame
  int sf_cnt;     //sf counter
  int data_writer_cnt;
  static int terminal_write_option;  //0 - incoming data, 1 - superframe

  public void initUI(){
        JMenuBar menubar = new JMenuBar();

        JMenu file = new JMenu("Options");
        file.setMnemonic(KeyEvent.VK_F);

        /*JMenu mote = new JMenu("Motes:");
		    JMenuItem motes[] = new JMenuItem[motesettings.length];
		    for(int i=0;i<motesettings.length;i++){
			    motes[i] = new JMenuItem(new SomeAction(i+". mote",i,panel,false));
			    mote.add(motes[i]);
		    }*/

        JMenu pairs = new JMenu("Slots");
		    JMenuItem submenus[] = new JMenuItem[DataCollector.motesettings[0].length];
		    int i=1;
		    while(i!=NUMBER_OF_FRAMES) {
			    submenus[i] = new JMenuItem(new SomeAction(i+". slot",i-1,panel,true));
			    pairs.add(submenus[i]);
			    i++;
		    }

        file.add(pairs);
        file.addSeparator();
        //file.add(mote);
        //file.addSeparator();

        menubar.add(file);

        setJMenuBar(menubar);

        setTitle("Relative phase");
        setSize(frame_window_length, frame_window_height);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
	}
  

  public void initalize() {
    slots = new ArrayList<Slot>(5);
    //node_index = 0;
    sf_cnt = 0;
    frame_prev = -1;
    data_writer_cnt = 0;
    node_slot_cnt = new int[motesettings.length];
    for(int i=0; i<motesettings.length; i++)
      node_slot_cnt[i] = 0;
    NUMBER_OF_RX = 0;
    for(int i=0; i<motesettings[0].length; i++) {
        if(motesettings[0][i] == RX) {
          NUMBER_OF_RX++;
        }
        if(motesettings[0][i] == RX || motesettings[0][i] == TX1 || motesettings[0][i] == TX2)
          NUMBER_OF_FRAMES++;
    }
    /*for(int i=0; i<motesettings.length; i++) {
      for(int j=0; j<motesettings[0].length; j++) {
        if(motesettings[i][j] == SSYN) {
          node_slot_cnt[i] = j+1;
        } 
      }
    }*/
    NUMBER_OF_SSYN = motesettings[0].length - NUMBER_OF_FRAMES;
    /*for(int i=0; i<motesettings[0].length; i++) {
      if(motesettings[0][i] == SSYN || motesettings[0][i] != RX)
        NUMBER_OF_SSYN++;
    }*/
    //System.out.println("row: " + motesettings.length + " column: " + motesettings[0].length);
    //System.out.println(" NUMBER_OF_SLOTS_IN_SF: " + NUMBER_OF_SLOTS_IN_SF);*/
  }



  public DataCollector(PacketSource reader){
		initalize(); 
	}

  public void printPacketTimeStamp(PrintStream p, byte[] packet) {
    int[] freq = new int[NUMBER_OF_RX];
    short[] phase = new short[NUMBER_OF_RX];
    short[] min = new short[NUMBER_OF_RX];
    short[] max = new short[NUMBER_OF_RX];
    short[] dataStart = new short[NUMBER_OF_RX];
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
    //node_index = Arrays.binarySearch(SEQ, a1);
    //if(terminal_write_option == 0) 
    //  p.print("node_index: " + node_index + "\n");
		int len = (int)(packet[5] & 0xFF);
    if(terminal_write_option == 0) {
	    p.print("Message length "+len+" \n");
	    p.print("Group ID: "+(int)(packet[6] & 0xFF)+" \n");
	    p.print("AM handler type: "+(int)(packet[7] & 0xFF)+" \n");
	    p.print("Data:\n");
    }
    frame_index = packet[8] & 0xFF;
    if(terminal_write_option == 0) 
      p.print("frame_index: " + frame_index + "\n");
    if(motesettings[0][frame_index+1] != NDEB || motesettings[0][frame_index+1] != DEB) {
      int tmp = 0;
      for(int i=9; i<9+(NUMBER_OF_RX); i++) {
        int b1 = packet[i] & 0xFF;
        if(terminal_write_option == 0) 
          p.print(tmp + ".dataStart: " + b1 + "\n");
        dataStart[tmp++] = (short)b1;
      }
      tmp = 0;
		  for(int i=9+(NUMBER_OF_RX); i<9+(NUMBER_OF_RX*3); i+=2) {    
		    int b1 = packet[i] & 0xFF;
        int b2 = packet[i+1] & 0xFF;
        b1 <<= 8;
        b1 = (b1 | b2) & 0x0000FFFF;
        if(terminal_write_option == 0) 
          p.print(tmp + ".freq: " + b1 + "\n");
        freq[tmp++] = b1;
      }
      tmp = 0;
      for(int i=9+(NUMBER_OF_RX*3); i<9+(NUMBER_OF_RX*4); i++) {
        int b1 = packet[i] & 0xFF;
        if(terminal_write_option == 0) 
          p.print(tmp + ".phase: " + b1 + "\n");
        phase[tmp++] = (short)b1;
      }
      tmp = 0;
      for(int i=9+(NUMBER_OF_RX*4); i<9+(NUMBER_OF_RX*5); i++) {
        int b1 = packet[i] & 0xFF;
        if(terminal_write_option == 0) 
          p.print(tmp + ".min: " + b1 + "\n");
        min[tmp++] = (short)b1;
      }
      tmp = 0;
      for(int i=9+(NUMBER_OF_RX*5); i<9+(NUMBER_OF_RX*6); i++) {
        int b1 = packet[i] & 0xFF;
        if(terminal_write_option == 0) 
          p.print(tmp + ".max: " + b1 + "\n");
        max[tmp++] = (short)b1;
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
      Upload(frame_index-1, freq, phase, min, max, dataStart);
	  }
  }
  
  //Upload frame with measures    frame numbers: 1,5,9,13
  public void Upload(int frame_mes, int[] freq, short[] phase, short[] min, short[] max, short[] dataStart) {
    int frame = 0;    //frame counter
    if(frame_mes == -1) {
      frame_mes = 0;
    }
    //System.out.println("frame_prev: " + frame_prev + " frame_mes: " + frame_mes); 
    if(frame_prev>=frame_mes) {    //superframe viewer
      //System.out.println("Call DataPrinter");
      DataPrinter();
      sf_cnt++;
      for(int i=0; i<motesettings.length; i++) {
        int k = 0;
        for(int j=0; j<motesettings[0].length; j++) {
          if(motesettings[i][j] == TX1 || motesettings[i][j] == TX2 || motesettings[i][j] == RX)
            k++;
          if(motesettings[i][j] == SSYN)
            break;
        }
        node_slot_cnt[i] = sf_cnt == 0 ? 0 : k+(sf_cnt-1)*(motesettings[0].length-NUMBER_OF_SSYN);
        //System.out.println("node_slot_cnt["+i+"]: " + node_slot_cnt[i] + " " + k);
      }
    }
    //frame = frame_mes-(NUMBER_OF_SLOT_IN_FRAME*node_index) + (sf_cnt*NUMBER_OF_INFRAST_NODES); //hogy a 5.dik frame-t ne 0-t adjon ki a slot_start
    frame_prev = frame_mes;
    //int slot_start = sf_cnt*NUMBER_OF_SLOTS_IN_SF + frame_mes;//(frame-NUMBER_OF_FRAMES) > 0 ? (frame-NUMBER_OF_FRAMES-1)*NUMBER_OF_SLOT_IN_FRAME : 0; //hanyadik slottol kezdjuk
    //int slot_end = slot_start + NUMBER_OF_SLOTS_IN_SF;
    //if(terminal_write_option == 0) 
//      System.out.println("frame_number: " + frame + " slot_start " + slot_start + " slot_end " + slot_end + " sf_cnt " + sf_cnt +  " slot_start: " + ((frame-NUMBER_OF_FRAMES-1)*NUMBER_OF_SLOT_IN_FRAME) + " a: " + (frame-NUMBER_OF_FRAMES) + " b " + NUMBER_OF_SLOT_IN_FRAME  + "\n-------------------\n");
//    System.out.println("frame_number: " + frame + "\n");
    int p_cnt = 0;  //which freq,phase pair processed
    int slot_cnt = sf_cnt == 0 ? 0 : frame_mes+1;
    int node_id = 0;
    //System.out.println("frame_mes: " + frame_mes + " sf_cnt: " + sf_cnt + " slot_cnt: " + slot_cnt + " NUMBER_OF_SSYN: " + NUMBER_OF_SSYN);
    for(int i=0; i<motesettings.length; i++) {
      if(motesettings[i][frame_mes] == SSYN) {
        //System.out.println("Node FOUND:" + i);
        node_id = i;
        break;
      }
    }
    //System.out.println("slot_cnt: " + slot_cnt + " node_id: " + node_id + " motesettings value: " + motesettings[node_id][frame_mes] + " node_slot_cnt: " + node_slot_cnt[node_id]); 
    while(frame_mes != slot_cnt) {
      //System.out.println("IN slot_cnt: " + slot_cnt + " slots.size: " + slots.size());
      if(motesettings[node_id][slot_cnt] == TX1 || motesettings[node_id][slot_cnt] == TX2 || motesettings[node_id][slot_cnt] == RX) {
        try{
          Slot s = slots.get(node_slot_cnt[node_id]); 
          //System.out.println("OLD BEGIN slot_cnt: " + slot_cnt + " node_slot_cnt: " + node_slot_cnt[node_id]); 
          if(motesettings[node_id][slot_cnt] == RX) {
            Node n = s.getNodeData(node_id);
            n.setDataStart(dataStart[p_cnt]);
            n.setFreq(freq[p_cnt]);
            if(freq[p_cnt] != 0)
              n.setPhase(phase[p_cnt]%freq[p_cnt]);
            else 
              n.setPhase(phase[p_cnt]);
            n.setMin(min[p_cnt]);
            n.setMax(max[p_cnt]);
            s.setNode(n, node_id);
            slots.set(node_slot_cnt[node_id],s);
            p_cnt++;
            //System.out.println("OLD END slot_cnt: " + slot_cnt + " node_slot_cnt: " + node_slot_cnt[node_id] + " slots.size: " + slots.size() + " p_cnt: " + p_cnt);
          }
        } catch (IndexOutOfBoundsException e) {
          //System.out.println("NEW BEGIN slot_cnt: " + slot_cnt + " node_slot_cnt: " + node_slot_cnt[node_id] + " slots.size: " + slots.size() + " p_cnt: " + p_cnt);
          Slot s = new Slot(slot_cnt);
          if(motesettings[node_id][slot_cnt] == RX) {  
            Node n = s.getNodeData(node_id);
            n.setDataStart(dataStart[p_cnt]);
            n.setFreq(freq[p_cnt]);
            if(freq[p_cnt] != 0)
              n.setPhase(phase[p_cnt]%freq[p_cnt]);
            else 
              n.setPhase(phase[p_cnt]);
            n.setMin(min[p_cnt]);
            n.setMax(max[p_cnt]);
            s.setNode(n, node_id);
            p_cnt++;
            //System.out.println("NEW END slot_cnt: " + slot_cnt + " node_slot_cnt: " + node_slot_cnt[node_id] + " slots.size: " + slots.size() + " p_cnt: " + p_cnt);
          } 
          slots.add(s);
          //System.out.println("slots.size(): " + slots.size());
        } //try end   
        node_slot_cnt[node_id]++;
      } //if end
      slot_cnt++;
      if(slot_cnt >= motesettings[0].length) 
        slot_cnt = 0;
    } //while end
    //System.out.println("\n\n");
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
    //System.out.println("Called DataPrinter");
    paintCounter++;
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
        FileWriter fw_sf = new FileWriter(pathprefix_sf + ".txt", false);	
     		BufferedWriter out_sf = new BufferedWriter(fw_sf);
        for(int i = (sf_cnt-1)*motesettings[0].length; i<sf_cnt*motesettings[0].length; i++) {
          if(motesettings[0][i%motesettings[0].length] == RX || motesettings[0][i%motesettings[0].length] == TX1 || motesettings[0][i%motesettings[0].length] == TX2) {
            //System.out.println("DataPrinter." + i + " " + ((sf_cnt-1)*motesettings[0].length) + " " +(sf_cnt*motesettings[0].length)+ " " + slots.size() + " data_writer_cnt: " + data_writer_cnt + " " + motesettings[0][i%motesettings[0].length]);
            Slot item = slots.get(data_writer_cnt);
         		String pathprefix = "measures/Slots/" + i + "_slot";	
            FileWriter fw = new FileWriter(pathprefix + ".txt", false);	
         		BufferedWriter out = new BufferedWriter(fw);
            out.write("TX: "+item.getTrans()+"\nRX:\n"+item.getAllNodeString());
            out_sf.write("TX: "+item.getTrans()+"\n"+item.getAllNodeString() + "\n\n");
            if(terminal_write_option == 1) 
              System.out.println((i%motesettings[0].length) + ". slot\n" + "TX: "+item.getTrans()+"\n"+item.getAllNodeString() + "\n");
            out.close();
				    fw.close();
				    data_writer_cnt++;
				  }
        }
        out_sf.close();
			  fw_sf.close();
      }
    } catch (IOException e) {
      e.printStackTrace();
    }
    if(terminal_write_option == 1) 
      System.out.println("--------------------------------------------");
    //if(paintCounter == 200) {
    //  System.out.println("PaintCounter = 100");
      /*paintCounter = 0;
      app.getContentPane().add(panel);
		  app.pack();
		  app.setVisible(true);*/
		//}
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
    
	  app = new DataCollector(reader); 	
	  /*panel = new PlotFunctionPanel(frame_window_length, frame_window_height, NUMBER_OF_RX, NUMBER_OF_FRAMES);
		app.initUI();
		app.setVisible(true);*/
    try {
      reader.open(PrintStreamMessenger.err);
      for (;;) {
        byte[] packet = reader.readPacket();
        if(packet[7] == (byte)0x3d) {
          app.printPacketTimeStamp(System.out, packet);
          //System.out.println();
          System.out.flush();
        }
      }
    }
    catch (IOException e) {
        System.err.println("Error on " + reader.getName() + ": " + e);
    }
  }

}
