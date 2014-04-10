import static java.lang.System.out;
import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.FileWriter;
import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.text.SimpleDateFormat;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

import java.awt.Dimension;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.border.EmptyBorder;
import javax.swing.JButton;
import javax.swing.JTextField;
import javax.swing.JTextArea;
import javax.swing.JScrollPane;
import javax.swing.ScrollPaneConstants;
import javax.swing.JLabel;

class BaseStationApp extends JFrame implements MessageListener{

	public static final int TOSH_DATA_LENGTH = 110;
	public static final int DATA_LENGTH = TOSH_DATA_LENGTH-3; 	//ket bajtot elfoglal mas
	public static final int MEASUREMENT_LENGTH = 1000;				//meres hossza 
	public static final int MAX_MEASUREMENT_NUMBER = 10;
	public static final int DELETE_MES_NUMBER = 2;
	
	private JPanel contentPane;
	private JTextArea textArea_data;
	private JTextArea textArea_motes;
	private JScrollPane scroll_data;
	private JScrollPane scroll_motes;
	private JTextField textField_moteNumber;
	private JLabel label_moteNumber;
	private JLabel label_moteID;
	
	private MoteIF moteIF;

	ArrayList<Measurement> measurementList;		//fileWrite-nel hasznalnam, de nem sikerult array-bol arraylistet kesziteni

	ArrayList<Integer> moteList;		//a mote id-kat taroljuk
	HashMap<Integer,Integer> mote_packetMap;	//melyik mote mennyi adatot tarol
	int mote_num;		//mennyi mote van bejelentkezve
	int send_mote_num;	//adatkeresnel hasznaljuk (SendDataReq())
	short[] measure;		//adatokat taroljuk
	int measure_id;		//az adott meres azonositoja
	int missing_slice;	//hianyzo csomagnal beallitja nem nullara az erteket
	int missing_packet;	//hianyzo csomagnal beallitja nem nullara az erteket
	int node_id;		//melyik node kuldi a csomagot. Alapertelmezett 2-es
	boolean slicesOK;	//minden szelet megerkezett
	int received_packet_number;	//mennyi uzenet erkezett eddig
	int slice_width;
	int tmp_packet_number; 		//akivel epp beszelgetunk, annak megjegyzi a mote szamat, azert van ra szukseg, hogy ha sok uj adata keletkezik mikozbe beszelgetunk vele, akkor ne kuldje el az osszeset, hanem csak annyit, amennyit a beszelgetes megkezdesekor kozolt velunk, de ne is vesszen el veletlenul az, hogy mennyi adat van jelenleg nala

	int rand;		//szeleteldobashoz szimulalasahoz
	boolean ok;		//szeleteldobashoz szimulalasahoz
	boolean stop; 	//az adatlekeres befejezve
	int[] free_mes;	//azokat a mereseket tartalmazza, amelyeket ki lehet torolni
	int fm_number;	//segedvaltozo a free_mes-hez

	Timer timer;
	int msg_mode;	//milyen uzenetet kell ujrakuldeni (GetSliceRemind-nel hasznalom), ha veletlen nem kapta meg az uzenetet a mote

	SimpleDateFormat DATE_FORMAT;
	Date time;

	class GetSliceRemind extends TimerTask {
        public void run() {
            System.out.format("Timer !%n");
			switch(msg_mode) {
				case 0: break;
				case 3: msg_mode = 0;
						allSliceChecker();
						break;
				default: break;
			}	
            timer.cancel(); //Terminate the timer thread
        }
    }


	public BaseStationApp(MoteIF moteIF){
		initalize();
		this.moteIF=moteIF;
		this.moteIF.registerListener(new MeasureMsg(),this);
		this.moteIF.registerListener(new AnnouncementMsg(),this); 
		gui();
	}
	
//FRAME
        
	@Override
	public Dimension getPreferredSize() {
		return new Dimension(400, 400);
	}

	private static JFrame createAndShowGui() {
		JFrame frame = new JFrame("Collector");
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		frame.pack();
		frame.setLocationByPlatform(true);
		frame.setVisible(true);
		return frame;
	}	

//GUI
	void gui() {
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setBounds(100, 100, 800, 350);
		contentPane = new JPanel();
		setContentPane(contentPane);
		contentPane.setBorder(new EmptyBorder(5, 5, 5, 5));
		contentPane.setLayout(null);
		
		JButton btn_DataReq = new JButton("Data Request");
		btn_DataReq.setBounds(550, 280, 142, 25);
		contentPane.add(btn_DataReq);
		btn_DataReq.addMouseListener(new MouseAdapter() {
			@Override
			public void mouseClicked(MouseEvent e) {
				sendReq();
			}
		});
		
		textArea_data = new JTextArea();
		textArea_data.setBounds(12, 20, 500, 300);
		contentPane.add(textArea_data);
		textArea_data.setColumns(10);

		textArea_motes = new JTextArea();
		textArea_motes.setBounds(550, 20, 150, 200);
		contentPane.add(textArea_motes);
		textArea_motes.setColumns(10);
		
		textField_moteNumber = new JTextField();
		textField_moteNumber.setBounds(550, 250, 64, 19);
		contentPane.add(textField_moteNumber);
		textField_moteNumber.setColumns(10);

		label_moteNumber = new JLabel("Registered mote number:");
		label_moteNumber.setBounds(550, 235, 200, 10);
		contentPane.add(label_moteNumber);

		label_moteID = new JLabel("Registered mote IDs:");
		label_moteID.setBounds(550, 5, 200, 10);
		contentPane.add(label_moteID);
		
		this.setTitle("Base Station App");
	}

//METHODS
	void measureMerger(short[] data, short mes_id, short seq_id) {		//szeleteket teljes csomagokka teszi ossze
		System.out.println("Data, id_mes " + mes_id + ", seq_id " + seq_id + " packet_number: " + mote_packetMap.get(node_id) + " getSlice: " + getSliceNumber());
		timer = new Timer();
		timer.schedule(new GetSliceRemind(), 2000);
		msg_mode = 3;
//		rand++;						//szeleteldobas szimulalasahoz a harom kommentezett sort uncommentelni
//	if(rand%4==0 || ok ==true){
		measure_id = mes_id;
		for(int i=0; i<slice_width; i++) {	//mennyi a valos adat az adott szeletben
			measure[i+seq_id*(DATA_LENGTH)] = data[i];
			out.print(measure[i+seq_id*(DATA_LENGTH)] + " ");
		}
//	}
		out.println("\n");
		if((seq_id == getSliceNumber()) || (ok == true && slicesOK == false)) { //utolso szelet az adott meresbol	megerkezett
			ok = true;			
			msg_mode = 0;
			System.out.println("Last Data, mes_id " + mes_id + ", seq_id " + seq_id + " " + ok + " " + slicesOK);
			slicesOK = allSliceChecker();		//megnezi, hogy minden szelet megerkezett-e a meresbol
			if(slicesOK == true) {				//minden szelet megvan
				out.println("allSliceChecker: true");	
				ok = false;
				free_mes[fm_number] = measure_id;		//minden szelet megerkezett a meresbol, mostmar ki lehet torolni
				if(fm_number == DELETE_MES_NUMBER-1)
					fm_number = 0;
				else
					fm_number++;
				out.println("Stop: " + stop);
				if(stop == false) {		//ha meg nem ertunk a mote sor vegere
					fileWriter();		//adatokat kiirjuk fajlba
					received_packet_number++;		//megkapott uzenetek szamat noveljuk
					out.println("Received packets: " + received_packet_number + " packet_number: " + mote_packetMap.get(node_id));
					if(received_packet_number >= mote_packetMap.get(node_id))	{	//utolso meres is megerkezett
						mote_packetMap.put(node_id,tmp_packet_number);				
						received_packet_number = 0;					
						sendDataReq();		//kuldheti a masik mote, aki a halozatban van 
					}else		//nem erkeztunk az utolso mereshez, az adott mote-nal
						sendFree();	
				} else {
					textArea_data.setText(textArea_data.getText() + "\n VEGE");
				}
			} else
				out.println("allSliceChecker: false");
		}
	
	}
		
	int getSliceNumber() {		//egy szelet hosszat adja vissza
		return (int)Math.floor(MEASUREMENT_LENGTH/(DATA_LENGTH));
	} 

	boolean allSliceChecker() {		//megnezi, hogy hianyzik-e valamelyik csomagbol szelet, es ha hianyzik, akkor beallit ket valtozot, hogy melyik csomagbol, melyik szelet
		out.println("inside AllSliceChecker");
		for(int j=0; j<=getSliceNumber(); j++) {	//egesz szamu a csomagmeret/szeletmeret
			out.println(measure[j*(DATA_LENGTH)] + " ");
			if(measure[j*(DATA_LENGTH)] == -1) {	//ha a szelet elso cellaja -1, akkor nincs meg az a szelet
				missing_slice = j; 				//hanyadik szelet
				missing_packet = measure_id;	//hanyadik csomag
				out.println(" measure[" + j + "] = " + measure[j*(DATA_LENGTH)] + " missing_slice: " + missing_slice + "\nmissing_packet: " + missing_packet);
				sendSliceReq();		//lekerjuk a hianyzo adatot
				return false;		//van hianyzo adat, igy false-al terunk vissza
			}
		}
		return true;		//minden adat megvan
	}

	void fileWriter() {			//fajlba irja a csomagokat
		out.println("inside fileWriter");
		out.println("Packet_number: " + mote_packetMap.get(node_id));
		FileWriter fw = null;
		BufferedWriter out = null;
		try {
			time = new Date();
			DATE_FORMAT = new SimpleDateFormat("dd-MM-yyyy");
			String date_dir = DATE_FORMAT.format(time);
			File dir = new File("measures/" + node_id + ".node_id/" + date_dir);
			dir.mkdirs();
			if (null != dir)
			{
				dir.mkdirs();
			}
			DATE_FORMAT = new SimpleDateFormat("dd-MM-yyyy:HH:mm:SS");
			String date = DATE_FORMAT.format(time);
			String pathprefix = "measures/" + node_id +".node_id/"+date_dir+"/"+measure_id+". packet_"+date;
			fw = new FileWriter(pathprefix + ".txt");

//itt hibat dob, mert nem tudja atkonvertalni a tombot arraylist-re
//			ArrayList<Short> a = new ArrayList<Short>();
//			a.addAll(measure);
//			Measurement meas = new Measurement(new Date(), node_id, a, pathprefix);
//            meas.print();
//            System.out.println("Data saved from NodID#"+node_id);

			out = new BufferedWriter(fw);
			for(int j=0; j<MEASUREMENT_LENGTH; j++) {
				out.write(measure[j]+"\n");
				measure[j] = -1; 				//kiuritsuk a measure tombot
			}
		} catch (IOException e) {
			e.printStackTrace();
		}finally{
			try {
				out.close();
				fw.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}		
	}

	void initalize() {		//inicializalja a valtozokat
		out.println("inside initalize");
		missing_packet = 0;
		missing_slice = 0;
		node_id = 0;		
		measure = new short[MEASUREMENT_LENGTH];
		free_mes = new int[DELETE_MES_NUMBER];
		for(int j=0; j<MEASUREMENT_LENGTH; j++) {
			measure[j] = -1;
		}
		moteList = new ArrayList<Integer>();
		mote_packetMap = new HashMap<Integer,Integer>();
		measurementList = new ArrayList<Measurement>();
		mote_num = 0;
		send_mote_num = 0;
		rand = 0;
		ok = false;
		stop = true;
		received_packet_number = 0;
		tmp_packet_number = 0;
		slicesOK = true;
		measure_id = 0;
		for(int i=0; i<DELETE_MES_NUMBER; i++) {
			free_mes[i] = 0;
		}
		fm_number = 0;
		slice_width = 0;
		timer = new Timer();
	}


	void moteRegister(int mote_id) {		//regisztralja a mote-kat
		out.println("inside moteRegister");
		textArea_motes.setText(textArea_motes.getText() + mote_id + "  ");
		textField_moteNumber.setText(mote_num+"");
		if(mote_num % 6 == 0) {
			textArea_motes.setText(textArea_motes.getText() + "\n");
//egesz idaig torolheto lenne, ha nem kell gui
		}
	}


//MESSAGE RECEIVE	
	public void messageReceived(int dest_addr,Message msg){
		System.out.println("inside Message arrived");
		if (msg instanceof MeasureMsg) {
			System.out.println("inside MeasureMsg arrived");
			MeasureMsg mes = (MeasureMsg)msg;
			timer.cancel();
			node_id = msg.getSerialPacket().get_header_src();
			slice_width = mes.get_slice_width();
			out.println("MeasureMsg: " + node_id + " " + mes.get_mes_id() + " " + mes.get_seq_num() + " " + slice_width);
			measureMerger(mes.get_data(),mes.get_mes_id(),mes.get_seq_num());
		}
		if (msg instanceof AnnouncementMsg) {
			System.out.println("inside AnnouncementMsg arrived");
			AnnouncementMsg mes = (AnnouncementMsg)msg;
			out.println("AnnouncementMsg: " + msg.getSerialPacket().get_header_src() + " "+mes.get_mes_number() + " node_id " + msg.getSerialPacket().get_header_src() +"\n");		
			if(msg.getSerialPacket().get_header_src() != node_id) //nem egyezik a jelenleg kommunikacioban levo mote_id-val
				mote_packetMap.put(msg.getSerialPacket().get_header_src(),(int)mes.get_mes_number());
			else
				tmp_packet_number = (int)mes.get_mes_number();		
			if(msg.getSerialPacket().get_header_src() != 0 && !moteList.contains(msg.getSerialPacket().get_header_src())) {
				moteList.add(msg.getSerialPacket().get_header_src());
				mote_num++;
				moteRegister(msg.getSerialPacket().get_header_src());		//gui miatt kell csak
			}	
		}
	}
	
//MESSAGE SEND
	public void sendReq() {
		stop = false;
		send_mote_num = -1;
//bejarjuk hogy kinek van adata, onnan kezdjuk a lekerest
		Iterator<Integer> keySetIterator = mote_packetMap.keySet().iterator();
		while(keySetIterator.hasNext()){		//megkeressuk melyik az elso mote a sorban, akinek van adata
			Integer key = keySetIterator.next();
			if(mote_packetMap.get(key) != 0) {	//ha van adata
				send_mote_num = moteList.indexOf(key);			//melyik indexnel talalhato az adott mote_id
				received_packet_number = 0;
				for(int i=0; i<MEASUREMENT_LENGTH; i++) {
					measure[i] = -1;
				}
				for(int i=0; i<DELETE_MES_NUMBER; i++) {
					free_mes[i] = 0;
				}
				break;
			}
		}	
		if(send_mote_num != -1)		//van mote akitol kerhetunk adatot
			sendDataReq();
	}

	public void sendDataReq() {
		out.println("Inside sendDataReq");
		textArea_data.setText(textArea_data.getText() + "\n S: " +send_mote_num + " m: " +mote_num + "st: " + stop);
		CommandMsg msg = new CommandMsg();
		try{
			if(mote_num != 0) { 	//ha nincs egy mote se bejelentkezve
				short[] free_tmp = new short[DELETE_MES_NUMBER];
				if(send_mote_num < mote_num) {		//addig amig van mote a sorban
					out.println("send_mote_num " + send_mote_num + " mote_num " + mote_num);
					msg.set_node_id_start(moteList.get(send_mote_num));
					if(send_mote_num == 0) {			//elso mote-nal a sorban
						msg.set_node_id_stop(0);		//0 node id nem lehet
					} else {
						out.println("");
						missing_packet = 0;
						missing_slice = 0;
						msg.set_node_id_stop(moteList.get(send_mote_num-1));
						textArea_data.setText(textArea_data.getText() + "\n ma: " +moteList.get(send_mote_num-1));
					}
				} else {			//utolso mote-hoz ertunk a sorban, igy befejezzuk az adatlekerest
					out.println("Stop: " + stop + " send_mote_num " + send_mote_num + " mote_num " + mote_num);
					stop = true; 	//az adatlekeresek befejezve
					out.println("stop true");
					msg.set_node_id_start(0);
					msg.set_node_id_stop(moteList.get(send_mote_num-1));
					textArea_data.setText(textArea_data.getText() + "\n mak: " +moteList.get(send_mote_num-1));
				}
//uj motenak kuldunk uzenetet, es a reginek elkuldjuk a maradek free mereseket, majd nullazuk az uj mote varasara				
				node_id = 0;				
				for(int i=0; i<DELETE_MES_NUMBER; i++) {
					free_tmp[i] = (short)free_mes[i];
				}
				out.println("a");
				for(int i=0; i<DELETE_MES_NUMBER; i++) {
					out.print("free_mes: " + free_tmp[i] + " t: " + (byte)free_tmp[i] + " ");
				}
				for(int i=0; i<DELETE_MES_NUMBER; i++) {
					out.print("free_mes: " + free_mes[i] + " ");
					free_mes[i] = 0;
				}
				out.println("");
				msg.set_free(free_tmp);
				moteIF.send(MoteIF.TOS_BCAST_ADDR,msg); 
				send_mote_num = send_mote_num + 1;
				out.println("Inside sendDataReq: " + msg.get_node_id_start() + " " + msg.get_node_id_stop());	
			}
		}catch(IOException e)
		{
			out.println("sendDataReq message cannot send to mote ");
		}
	}
	
	public void sendSliceReq() {
		out.println("Inside sendSliceReq: " + missing_packet + " " + missing_slice);
		GetSliceMsg msg = new GetSliceMsg();
		try{
			msg.set_slice((byte)missing_slice);
			msg.set_mes_id((byte)missing_packet);
			msg.set_node_id(node_id);
			moteIF.send(MoteIF.TOS_BCAST_ADDR,msg);
			out.println("sendSliceReq send: " + node_id + " " + (byte)missing_packet + " " + (byte)missing_slice);
		}catch(IOException e)
		{
			out.println("SliceReq message cannot send to mote ");
		}
	}

	public void sendFree() {		//torolje ki a mar elkuldott csomagokat
		out.println("Inside sendFree");
		FreeMsg msg = new FreeMsg();
		try{
			short[] free_tmp = new short[DELETE_MES_NUMBER];
			for(int i=0; i<DELETE_MES_NUMBER; i++)
				free_tmp[i] = (short)free_mes[i];
			msg.set_free(free_tmp);
			msg.set_node_id(node_id);
			moteIF.send(MoteIF.TOS_BCAST_ADDR,msg);
			out.print("sendFree send: ");
			for(int i=0; i<DELETE_MES_NUMBER; i++)
				out.print(free_tmp[i] + " ");
			out.println("");
		}catch(IOException e)
		{
			out.println("SliceFree message cannot send to mote ");
		}
	}
	
	public static void main(String[] args) throws Exception 
	{
		PhoenixSource phoenix = null;
		MoteIF mif = null;
		out.println("Program started");

		if( args.length == 0 ){
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		} else if( args.length == 2 && args[0].equals("-comm") ) {
			phoenix = BuildSource.makePhoenix(args[1], PrintStreamMessenger.err);
		} else {
			System.err.println("usage: java SendApp [-comm <source>]");
			System.exit(1);
		}
		mif = new MoteIF(phoenix); 
		BaseStationApp app= new BaseStationApp(mif); 
		app.setVisible(true);
	}

//
	private class Measurement{
		private List<Short> data;
		private String pathprefix;
		  
		private Date timeStamp;
		private int nodeid;
		
		private int measureTime;
		private long period;
		private long phase;
		
		//dev stuff
		private int[] senders = new int[2];
		private int[] fineTune = new int[2];
		private int[] power = new int[2];
		private int channel;
		
		private int toInt(List<Short> list){
		  int ret = (list.get(0)<<8) | list.get(1);
		return ret;
		}

		private long toLong(List<Short> from){
		  long ret = (from.get(0)<<24) | (from.get(1)<<16) | (from.get(2)<<8) | from.get(3);
		return ret;
		}
		
		private byte toSignedByte(short from){
		  byte ret;
		  if( from < 128 ){
		    ret = (byte) from;
		  } else {
		    ret = (byte)(from - 256);
		  }
		  return ret;
		}
		
		public Measurement(Date timeStamp, int nodeid, ArrayList<Short> rawData, String pathprefix){
		  this.timeStamp = timeStamp;
		  this.nodeid = nodeid;
		  this.pathprefix = pathprefix;
		  /*
		  * Header:
		  *   typedef nx_struct result_t{
		    nx_uint16_t measureTime;
		    nx_uint32_t period;
		    nx_uint32_t phase;
		    //debug only:
		    nx_uint8_t channel;
		    nx_uint16_t senders[2];
		    nx_int8_t fineTunes[2];
		    nx_uint8_t power[2];
		  } result_t;
		  */
		  //19B
		  int offset = 0;
		  measureTime = toInt(rawData.subList(offset, offset + 2)); offset+=2;
		  period = toLong(rawData.subList(offset, offset + 4)); offset+=4;
		  phase = toLong(rawData.subList(offset, offset + 4)); offset+=4;
		  channel = rawData.get(offset); offset+=1;
		  senders[0] = toInt(rawData.subList(offset, offset + 2)); offset+=2;
		  senders[1] = toInt(rawData.subList(offset, offset + 2)); offset+=2;
		  fineTune[0] = toSignedByte(rawData.get(offset)); offset+=1;
		  fineTune[1] = toSignedByte(rawData.get(offset)); offset+=1;
		  power[0] = rawData.get(offset); offset+=1;
		  power[1] = rawData.get(offset); offset+=1;
		  data = rawData.subList(offset, rawData.size());
		}

		public void print(){
		  String now = new SimpleDateFormat("dd. HH:mm:ss.SSS").format(timeStamp);
		  Path path = Paths.get(pathprefix + now+"_"+Integer.toString(nodeid)+".csv");
		  try (BufferedWriter writer = Files.newBufferedWriter(path, StandardCharsets.UTF_8, StandardOpenOption.CREATE_NEW)){
		    writer.write("Timestamp, "+ new SimpleDateFormat("YYYY.MM.dd. HH:mm:ss.SSS").format(timeStamp)+"\n");
		    writer.write("NodeId, "+ Integer.toString(nodeid)+"\n");
		    writer.write("MeasureTime, "+ Integer.toString(measureTime)+"\n");
		    writer.write("Period, "+ Long.toString(period)+"\n");
		    writer.write("Phase, "+ Long.toString(phase)+"\n");
		    writer.write("Channel, " + Integer.toString(channel) + "\n");
		    writer.write("Sender, " + Integer.toString(senders[0]) + ", " + Integer.toString(senders[1]) + "\n");
		    writer.write("Finetune, " + Integer.toString(fineTune[0]) + ", " + Integer.toString(fineTune[1]) + "\n");
		    writer.write("Power, " + Integer.toString(power[0]) + ", " + Integer.toString(power[1]) + "\n");
		    writer.write("--\n");
		    for(Short meas:data){
		      writer.write(Short.toString(meas) + "\n");
		    }
		    writer.close();
		  } catch (IOException e) {
		    // TODO Auto-generated catch block
		    e.printStackTrace();
		  }
		}
	}

}

