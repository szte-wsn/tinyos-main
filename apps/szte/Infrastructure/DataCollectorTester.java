import java.util.Arrays;
import static java.lang.System.out;
import java.util.ArrayList;

class DataCollectorTester {
 
  public static final int NUMBER_OF_INFRAST_NODES = 4;
  public static final int NUMBER_OF_FRAMES = 4;
  public static final int NUMBER_OF_SLOT_IN_FRAME = 12;
  public static final int SENDING_TIME = 50;
  public static final int BUFFER_LEN = 400;

  public static final int NUMBER_OF_SLOTS_IN_SF = NUMBER_OF_SLOT_IN_FRAME*NUMBER_OF_FRAMES;

  public static final int TX = 0;
  public static final int RX = 1;

  //SYNC receive sequence (node ids)
  public static final int[] SEQ = 
  {
      1,2,3,4
  };

  //Super frame structure
  public static final int[][] SF_slots = 
  { {TX, TX, RX, TX, TX, RX, TX, TX, RX, RX, RX, RX, TX, TX, RX, TX, TX, RX, TX, TX, RX, RX, RX, RX, TX, TX, RX, TX, TX, RX, TX, TX, RX, RX, RX, RX, TX, TX, RX, TX, TX, RX, TX, TX, RX, RX, RX, RX} ,
    {RX, RX, RX, TX, RX, TX, TX, RX, TX, TX, TX, RX, RX, RX, RX, TX, RX, TX, TX, RX, TX, TX, TX, RX, RX, RX, RX, TX, RX, TX, TX, RX, TX, TX, TX, RX, RX, RX, RX, TX, RX, TX, TX, RX, TX, TX, TX, RX},
    {TX, RX, TX, RX, RX, RX, RX, TX, TX, TX, RX, TX, TX, RX, TX, RX, RX, RX, RX, TX, TX, TX, RX, TX, TX, RX, TX, RX, RX, RX, RX, TX, TX, TX, RX, TX, TX, RX, TX, RX, RX, RX, RX, TX, TX, TX, RX, TX},
    {RX, TX, TX, RX, TX, TX, RX, RX, RX, RX, TX, TX, RX, TX, TX, RX, TX, TX, RX, RX, RX, RX, TX, TX, RX, TX, TX, RX, TX, TX, RX, RX, RX, RX, TX, TX, RX, TX, TX, RX, TX, TX, RX, RX, RX, RX, TX, TX} };

 
  ArrayList<Slot> slots;  //Store slots
  int node_index;   //The actual node index in SEQ array
  int frame_prev;   //overflow viewer
  int frame_of;     //overflow count

  class Node {
	  int id;
	  int freq;
	  int phase;
	
	  public Node(int id, int freq, int phase) {
		  this.id = id;
		  this.freq = freq;
		  this.phase = phase;
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

    public void setFreq(int freq) {
      this.freq = freq;
    }

    public void setPhase(int phase) {
      this.phase = phase;
    }
    
    public String toString() {
      return "id: " + id + " freq: " + freq + " phase: " + phase;
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
          nodes.add(new Node(SEQ[i],0,0));
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
      return new Node(0,0,0);   //default
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

  }

  public void initalize() {
    slots = new ArrayList<Slot>(5);
    node_index = 0;
    frame_of = 0;
    frame_prev = 0;
  }

/*  //Upload frame with measure (single data)
  public void Upload(short frame, short freq, short phase) {
    if(frame_of[node_index]>frame)    //tulcsordulas figyelo
      frame += 255;
    int slot_start = (frame-NUMBER_OF_FRAMES) > 0 ? (frame-NUMBER_OF_FRAMES)*NUMBER_OF_SLOT_IN_FRAME : 0; //hanyadik slottol kezdjuk
    int slot_end = (frame/NUMBER_OF_FRAMES) > 0 ? (slot_start+NUMBER_OF_SLOTS_IN_SF) : (frame*NUMBER_OF_SLOT_IN_FRAME);
//    int SF_num = frame/NUMBER_OF_FRAMES; //hanyadik SF jott az uzenet
    System.out.println("frame: " + frame + " slot_start: " + slot_start + " slot_end: " + slot_end);

    for(int i=slot_start; i<slot_end; i++) {
      try{    
        System.out.println("inB");
        Slot s = slots.get(i);      //lekerjuk, hogy van-e ilyen slot, azert, hogy ha nincs meg ez a slot, akkor legalabb csinaljuk meg, fuggetlenul attol, hogy az adott node TX vagy RX, mert ugye TX-nel nem ad adatot.
        System.out.println("1b:" + i + " " + SF_slots[node_index][i%NUMBER_OF_SLOTS_IN_SF]);
        if(SF_slots[node_index][i%NUMBER_OF_SLOTS_IN_SF] == RX) {
          Node n = s.getNodeData(SEQ[node_index]);
          System.out.println("2b:" + i);
          n.setFreq(freq);
          System.out.println("3b:" + i);
          n.setPhase(phase);
          System.out.println("4b:" + i);
          s.setNode(n, SEQ[node_index]);
          System.out.println("5b:" + i);
          slots.set(i,s);
        }
        System.out.println("6b: " + i);
      } catch (IndexOutOfBoundsException e) {
        System.out.println("inA");
        Slot s = new Slot(i%NUMBER_OF_SLOTS_IN_SF);
        System.out.println("1a:" + i + " " + SF_slots[node_index][i%NUMBER_OF_SLOTS_IN_SF]);
        if(SF_slots[node_index][i%NUMBER_OF_SLOTS_IN_SF] == RX) {
          System.out.println("node_index: " + node_index);
          System.out.println("SEQ: " + SEQ[node_index]);
          Node n = s.getNodeData(SEQ[node_index]);
          System.out.println("2a:" + i);
          n.setFreq(freq);
          System.out.println("3a:" + i);
          n.setPhase(phase);
          System.out.println("4a:" + i);
          s.setNode(n,SEQ[node_index]);
          System.out.println("5a:" + i);
        } 
//itt tartottam. valamiert nem menti el a node letrehozast a tx es rx-nel. 78.dik sornal.
//          s.addNode(new Node(SEQ[node_index], freq, phase));
        slots.add(s);
        System.out.println("6a:" + i);
        System.out.println("slots.get: " + slots.get(i));
      }
    }
    frame_of[node_index] = frame;
  }
*/

  //Upload frame with measures
  public void Upload(short frame_mes, short[] freq, short[] phase) {
    int frame = 0;    //frame with overflow
    if(frame_prev>frame_mes) {    //overflow viewer
      frame_of++;
    }
    frame = frame_mes + frame_of*255;
 //   System.out.println("frame_mes: " + frame_mes);
    int slot_start = (frame-NUMBER_OF_FRAMES) > 0 ? (frame-NUMBER_OF_FRAMES)*NUMBER_OF_SLOT_IN_FRAME : 0; //hanyadik slottol kezdjuk
    int slot_end = (frame/NUMBER_OF_FRAMES) > 0 ? (slot_start+NUMBER_OF_SLOTS_IN_SF) : (frame*NUMBER_OF_SLOT_IN_FRAME);
    int p_cnt = 0;  //hanyadik freq,phase parosnal tartunk
//    System.out.println("frame: " + frame + " slot_start: " + slot_start + " slot_end: " + slot_end);

    for(int i=slot_start; i<slot_end; i++) {
      try{    
//        System.out.println("inB");
        Slot s = slots.get(i);      //lekerjuk, hogy van-e ilyen slot, azert, hogy ha nincs meg ez a slot, akkor legalabb csinaljuk meg, fuggetlenul attol, hogy az adott node TX vagy RX, mert ugye TX-nel nem ad adatot.
//        System.out.println("1b:" + i + " " + SF_slots[node_index][i%NUMBER_OF_SLOTS_IN_SF]);
        if(SF_slots[node_index][i%NUMBER_OF_SLOTS_IN_SF] == RX) {
          Node n = s.getNodeData(SEQ[node_index]);
//          System.out.println("2b:" + i);
          n.setFreq(freq[p_cnt]);
//          System.out.println("3b:" + i);
          n.setPhase(phase[p_cnt]);
//          System.out.println("4b:" + i);
          s.setNode(n, SEQ[node_index]);
//          System.out.println("5b:" + i);
          slots.set(i,s);
          p_cnt++;
        }
//        System.out.println("6b: " + i + " " + p_cnt);
      } catch (IndexOutOfBoundsException e) {
//        System.out.println("inA");
        Slot s = new Slot(i%NUMBER_OF_SLOTS_IN_SF);
//        System.out.println("1a:" + i + " " + SF_slots[node_index][i%NUMBER_OF_SLOTS_IN_SF] + " " +p_cnt);
        if(SF_slots[node_index][i%NUMBER_OF_SLOTS_IN_SF] == RX) {
//          System.out.println("node_index: " + node_index);
//          System.out.println("SEQ: " + SEQ[node_index]);
          Node n = s.getNodeData(SEQ[node_index]);
//          System.out.println("2a:" + i);
          n.setFreq(freq[p_cnt]);
//          System.out.println("3a:" + i);
          n.setPhase(phase[p_cnt]);
//          System.out.println("4a:" + i);
          s.setNode(n,SEQ[node_index]);
//          System.out.println("5a:" + i);
          p_cnt++;
        } 
        slots.add(s);
//        System.out.println("6a:" + i + " " + p_cnt);
//        System.out.println("slots.get: " + slots.get(i));
      }
    }
    frame_prev = frame_mes;
  }


  public DataCollectorTester(int rep) {
    initalize();
    Tester(rep);
  }

  public void Tester(int frame_number) {
    ArrayList<Integer> n_freq;
    ArrayList<Integer> n_phase;
    int end = 0;
    for(short i=0; i<frame_number; i++) {
      //data gen (measure)
      end = i>NUMBER_OF_FRAMES ? (NUMBER_OF_FRAMES*NUMBER_OF_SLOT_IN_FRAME) : i*NUMBER_OF_SLOT_IN_FRAME;
      n_freq = new ArrayList<Integer>();
      n_phase = new ArrayList<Integer>();
      for(int j=0; j<end; j++) {
        if(SF_slots[i%NUMBER_OF_FRAMES][j] == RX) {
          n_freq.add(2);     
          n_phase.add(3);    
        }
      }
      Integer[] i_data_freq = n_freq.toArray(new Integer[0]);
      short[] s_data_freq = new short[i_data_freq.length];
      Integer[] i_data_phase = n_phase.toArray(new Integer[0]);
      short[] s_data_phase = new short[i_data_phase.length];
      for(int j=0; j<i_data_freq.length; j++) {
        s_data_freq[j] = i_data_freq[j].shortValue();
        s_data_phase[j] = i_data_phase[j].shortValue();
      }
//      System.out.println("length: " + s_data_freq.length + " " + s_data_phase.length + " " + end  );
      //update (sync message received)
      node_index = i%NUMBER_OF_INFRAST_NODES;
      Upload(i, s_data_freq, s_data_phase);
    }

    //result check
    System.out.println("\n\nResult check\nslotsize: " + slots.size());
    System.out.println("Slots: ");
    for(int i = 0; i<slots.size(); i++) {
      Slot item = slots.get(i);
      System.out.println(i + ".slot Trans: " + item.getTrans() + "\n" + item.getAllNode() + "\n");
    }
  }  
   
  public static void main(String[] args) {
    DataCollectorTester a = new DataCollectorTester(Integer.parseInt(args[0]));
  }
}
