import static java.lang.System.out;
import java.text.SimpleDateFormat;
import java.util.Date;
import net.tinyos.packet.*;
import net.tinyos.message.*;
import net.tinyos.util.PrintStreamMessenger;
import java.io.*;
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

	public static final int PAYLOAD_LENGTH = 13;	//payload merete (1 byte meres_id + 1 byte seq_num + 100 byte adat)
				//PAYLOAD_LENGTH=10-re valami baja van. csomag kimenetek a vege fele 0-ra valtanak.
				//payload meresi adat resze
	public static final int DATA_LENGTH = PAYLOAD_LENGTH-3; 	//ket bajtot elfoglal mas
	public static final int MEASUREMENT_LENGTH = 40;				//meres hossza 
	public static final int TOSH_DATA_LENGTH = PAYLOAD_LENGTH; 	//message.h payload merete
	public static final int MAX_MEASUREMENT_NUMBER = 10;
	public static final int MAX_MOTE_NUMBER = 50;
	
	private JPanel contentPane;
	private JTextArea textArea_data;
	private JTextArea textArea_motes;
	private JScrollPane scroll_data;
	private JScrollPane scroll_motes;
	private JTextField textField_moteNumber;
	private JLabel label_moteNumber;
	private JLabel label_moteID;
	
	private MoteIF moteIF;

	int[] mote_array;		//a mote id-kat taroljuk
	int mote_num;			//mennyi mote van bejelentkezve
	int send_mote_num;		//adatkeresnel hasznaljuk (SendDataReq())
	int[][] mesure;			//adatokat taroljuk
	int missing_slice;		//hianyzo csomagnal beallitja nem nullara az erteket
	int missing_packet;		//hianyzo csomagnal beallitja nem nullara az erteket
	int packet_number;		//mennyi csomagot ad az adott mote osszesen
	int node_id = 2;			//melyik node kuldi a csomagot. Alapertelmezett 2-es
	boolean slicesOK = true;	//minden szelet megerkezett

	int rand = 0;			//szeleteldobashoz szimulalasahoz
	boolean ok = false;		//szeleteldobashoz szimulalasahoz
	boolean stop = true; 	//az adatlekeres befejezve

	SimpleDateFormat DATE_FORMAT;
	Date time;


	public BaseStationApp(MoteIF moteIF){
		initalize();
		this.moteIF=moteIF;
		this.moteIF.registerListener(new RadioDataMsg(),this);
		this.moteIF.registerListener(new MesNumberMsg(),this); 
		this.moteIF.registerListener(new LoginMoteMsg(),this);
		gui();
	}
	
/******************************************/
/**************FRAME***********************/
/******************************************/
        
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
	void mesureMerger(short[] data, short mes_id, short seq_id) {		//szeleteket teljes csomagokka teszi ossze
		System.out.println("Data, id_mes " + mes_id + ", seq_id " + seq_id + " packet_number: " + packet_number + " getSlice: " + getSliceNumber());
//		rand++;						//szeleteldobas szimulalasahoz a harom kommentezett sort uncommentelni
//	if(rand%4==0 || ok ==true){
		for(int i=0; i<data.length; i++) {
			if(data[i] != 0) {
				mesure[mes_id][i+seq_id*(DATA_LENGTH)] = (int)data[i];
				out.print(data[i] + " ");
			}
		}
//	}
		out.println("\n");
		if(mes_id == packet_number-1 && seq_id == getSliceNumber()-1 || slicesOK == false) {	//utolso csomag erkezett meg
			ok = true;			
			System.out.println("Last Data, mes_id " + mes_id + ", seq_id " + seq_id);
			slicesOK = allSliceChecker();
			if(slicesOK == true) {
				out.println("allSliceChecker: true");	
				if(stop == false) {		//ha meg nem ertunk a mote sor vegere
					fileWriter();		//adatokat kiirjuk fajlba
					sendDataReq();		//kuldheti a masik mote, aki a halozatban van
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
		for(int i=0; i<MAX_MEASUREMENT_NUMBER; i++) {
			for(int j=0; j<getSliceNumber(); j++) {	//egesz szamu a csomagmeret/szeletmeret
				if(mesure[i][(j*(DATA_LENGTH))] == 0) {
					missing_slice = j; 				//hanyadik szelet
					missing_packet = i;				//hanyadik csomag
					out.println(" mesure[" + i + "][" + j + "] = " + mesure[i][j*(DATA_LENGTH)] + " missing_slice: " + missing_slice + "\nmissing_packet: " + missing_packet);
					sendSliceReq();		//lekerjuk a hianyzo adatot
					return false;		//van hianyzo adat, igy false-al terunk vissza
				}
			}
		}
		return true;		//minden adat megvan
	}

	void fileWriter() {			//fajlba irja a csomagokat
		out.println("inside fileWriter");
		out.println("Packet_number: " + packet_number);
		FileWriter fw = null;
		BufferedWriter out = null;
		for(int i=0; i<packet_number; i++) {
			try {
				time = new Date();
				DATE_FORMAT = new SimpleDateFormat("dd-MM-yyyy");
				String date_dir = DATE_FORMAT.format(time);
				File dir = new File("mesures/" + node_id + ".node_id/" + date_dir);
				dir.mkdirs();
				if (null != dir)
				{
					dir.mkdirs();
				}
				DATE_FORMAT = new SimpleDateFormat("dd-MM-yyyy:HH:mm:SS");
				String date = DATE_FORMAT.format(time);
				fw = new FileWriter("mesures/" + node_id +".node_id/"+date_dir+"/"+date+"_packet_"+i+".txt");
				out = new BufferedWriter(fw);
				for(int j=0; j<MEASUREMENT_LENGTH; j++) {
					out.write(mesure[i][j]+"\n");
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
		
	}

	void initalize() {		//inicializalja a valtozokat
		out.println("inside initalize");
		missing_packet = 0;
		missing_slice = 0;
		packet_number = 0;
		node_id = 2;		//alapertelmezett ertek (ezzel a node-al probalom test-nel)
		mesure = new int[MAX_MEASUREMENT_NUMBER][MEASUREMENT_LENGTH];
		for(int i=0; i<MAX_MEASUREMENT_NUMBER; i++) {
			for(int j=0; j<MEASUREMENT_LENGTH; j++) {
				mesure[i][j] = 0;
			}
		}
		mote_array = new int[MAX_MOTE_NUMBER];
		for(int i=0; i<MAX_MOTE_NUMBER; i++) {
			mote_array[i] = 0;
		}
		mote_num = 0;
		send_mote_num = 0;
		rand = 0;
		stop = true;
	}

	void moteRegister(short mote_id) {		//regisztralja a mote-kat
		out.println("inside moteRegister");
		boolean isThere = false;
		for(int i=0; i<mote_num; i++) {
				if(mote_array[i] == mote_id) {
					isThere = true;
					break;
				}
		}
		if(isThere == false) {
			mote_array[mote_num] = mote_id;
			textArea_motes.setText(textArea_motes.getText() + mote_id + "  ");
			mote_num++;
			textField_moteNumber.setText(mote_num+"");
			if(mote_num % 6 == 0) {
				textArea_motes.setText(textArea_motes.getText() + "\n");
			}
		}
	}


	//MESSAGE RECEIVE
	
	public void messageReceived(int dest_addr,Message msg){
		System.out.println("inside Message arrived");
		if (msg instanceof RadioDataMsg) {
			System.out.println("inside RadioDataMsg arrived");
			RadioDataMsg mes = (RadioDataMsg)msg;
			node_id = mes.get_node_id();
			out.println("RadioDataMsg: " +mes.get_node_id() + " " + mes.get_mes_id() + " " + mes.get_seq_num());
			mesureMerger(mes.get_data(),mes.get_mes_id(),mes.get_seq_num());
		}
		if (msg instanceof MesNumberMsg) {
			System.out.println("inside MesNumberMsg arrived");
			MesNumberMsg mes = (MesNumberMsg)msg;
			packet_number = mes.get_mes_number();
			out.println("MesNumberMsg: " + mes.get_node_id() + " "+mes.get_mes_number() +"\n");
			if(packet_number == 0) {
					sendDataReq();
			}
		}
		if (msg instanceof LoginMoteMsg) {
			System.out.println("inside LoginMoteMsg arrived");
			LoginMoteMsg mes = (LoginMoteMsg)msg;
			out.println("moteRegister: " + mes.get_node_id() + "\n");
			moteRegister(mes.get_node_id());
		}
	}
	
	//MESSAGE SEND

	public void sendReq() {
		stop = false;
		send_mote_num = 0;
		sendDataReq();
	}

	public void sendDataReq() {
		out.println("Inside sendDataReq");
		textArea_data.setText(textArea_data.getText() + "\n S: " +send_mote_num + " m: " +mote_num + "st: " + stop);
		CommandMsg msg=new CommandMsg();
		try{
			if(mote_num != 0) { 	//ha nincs egy mote se bejelentkezve
				if(send_mote_num < mote_num) {		//ha csak egy mote van bejelentkezve
					msg.set_node_id_start((byte)mote_array[send_mote_num]);
					if(send_mote_num == 0) {
						msg.set_node_id_stop((byte)0);		//0 node id nem lehet
					} else {
						msg.set_node_id_stop((byte)mote_array[send_mote_num-1]);
						textArea_data.setText(textArea_data.getText() + "\n ma: " +(byte)mote_array[send_mote_num-1]);
					}
				} else {			//utolso mote-hoz ertunk a sorban, igy befejezzuk az adatlekerest
					stop = true; 	//az adatlekeresek befejezve
					out.println("stop true");
					msg.set_node_id_start((byte)0);
					msg.set_node_id_stop((byte)mote_array[send_mote_num-1]);
					textArea_data.setText(textArea_data.getText() + "\n mak: " +(byte)mote_array[send_mote_num-1]);
				}
				send_mote_num = send_mote_num + 1;
				moteIF.send(MoteIF.TOS_BCAST_ADDR,msg); 
			}
			out.println("Inside sendDataReq: " + msg.get_node_id_start() + " " + msg.get_node_id_stop());	
		}catch(IOException e)
		{
			out.println("Command message cannot send to mote ");
		}
	}
	
	public void sendSliceReq() {
		out.println("Inside sendSliceReq");
		GetSliceMsg msg=new GetSliceMsg();
		try{
			msg.set_slice((byte)missing_slice);
			msg.set_mes_id((byte)missing_packet);
			msg.set_node_id((byte)node_id);
			moteIF.send(MoteIF.TOS_BCAST_ADDR,msg);
			out.println("sendSliceReq send: " + (byte)node_id + " " + (byte)missing_packet + " " + (byte)missing_slice);
		}catch(IOException e)
		{
			out.println("SliceReq message cannot send to mote ");
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
}

