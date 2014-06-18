import static java.lang.System.out;
import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
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
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

class BaseStationApp implements MessageListener{

	public static final int TOSH_DATA_LENGTH = 110;
	public static final int DATA_LENGTH = TOSH_DATA_LENGTH-6; 	
	public static final int MAX_MEASUREMENT_NUMBER = 10;
	public static final int DELETE_MES_NUMBER = 2;
	public static final int MAX_MOTE_NUMBER = 50;		//LinkedHashMap-hez, mert defaultan 16 erteket tud csak tarolni
	
	private MoteIF moteIF;

	LinkedHashMap<Integer,Integer> mote_packetMap;	//melyik mote mennyi adatot tarol
	short[] measure;	//adatokat taroljuk
	int measure_id;		//a jelenlegi meres azonositoja
	int measure_width;	//a meres teljes hossza
	ArrayList<Integer> missing_slice;	//hianyzo csomagokat tartalmazza
	int missing_packet;					//hianyzo csomagnal beallitja nem nullara az erteket
	int received_packet_number;			//mennyi meres erkezett eddig
	int total_packet_number;			//mennyi merese van osszesen a motenak
	boolean complete_packet; 			//egy meres teljesen megerkezett
	boolean end_slice;					//adott meresbol megkaptuk az utolso id-vel rendelkezo szeletet, ami nem azt jelenti, hogy minden szelet megerkezett
	int slice_width;			//szelet hossz
	int tmp_packet_number; 		//akivel epp beszelgetunk, annak megjegyzi a csomagszamat, azert van ra szukseg, hogy ha sok uj adata keletkezik mikozbe beszelgetunk vele, akkor ne kuldje el az osszeset, hanem csak annyit, amennyit a beszelgetes megkezdesekor kozolt velunk, de ne is vesszen el veletlenul az, hogy mennyi adat van jelenleg nala

	int node_id;			//melyik node kuldi a csomagot. Alapertelmezetten 0
	int prev_node_id;		//mi volt az elozo node_id, azt kell a commandMsg stop reszebe betenni
	boolean interrupt;		//ha epp adja a mote az adatokat, de nem ert a vegere, es kezdodik a meres, akkor az adott mereset nem kell kitorolni a mote_packetMap-bol

	boolean sending;//true - ha elkezdtuk az adatlekerest, false - nincs tobb mote, akitol adatot kernenk le
	int[] free_mes;	//azokat a mereseket tartalmazza, amelyeket ki lehet torolni
	int fm_number;	//segedvaltozo a free_mes-hez

	Timer timer;
	int msg_mode;	//milyen uzenetet kell ujrakuldeni (GetSliceRemind-nel hasznalom), ha veletlen nem kapta meg az uzenetet a mote

	SimpleDateFormat DATE_FORMAT;
	Date time;	

//TEST VARIABLES
	static ArrayList<Integer> mote_list;

	class GetSliceRemind extends TimerTask {
        public void run() {
//        	System.out.println("Timer fired: " + msg_mode + " " + mote_packetMap.size());
			switch(msg_mode) {
				case 0: break;
//TESTING
				case 1: msg_mode = 0;
						sendDataReqControl();
						break;
//END
				case 3: msg_mode = 0;
						if(!allSliceChecker()) 
							sendSliceReq();
						else
							allSliceReceived();
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
	}

//adatok inicializalasa	
	void initalize() {		//inicializalja a valtozokat
		mote_packetMap = new LinkedHashMap<Integer,Integer>(MAX_MOTE_NUMBER);
		measure_id = -1;
		measure_width = 0;
		
		missing_slice = new ArrayList<Integer>();
		missing_packet = 0;
		received_packet_number = 0;
		total_packet_number = 0;
		complete_packet = true;
		tmp_packet_number = 0;
		end_slice = false;
		slice_width = 0;

		node_id = 0;		
		prev_node_id = 0;
		interrupt = false;

		sending = false;
		free_mes = new int[DELETE_MES_NUMBER];
		Arrays.fill(free_mes,(short)0);
		fm_number = 0;

		timer = new Timer();
		msg_mode = 0;
	}
	
//mennyi szelet van
	int getSliceNumber() {		//egy szelet hosszat adja vissza
		return (int)Math.floor(measure_width/(DATA_LENGTH));
	} 

//uzenet erkezett	
	public void messageReceived(int dest_addr,Message msg){
		if (msg instanceof MeasureMsg) {
			MeasureMsg mes = (MeasureMsg)msg;

			timer.cancel();
			if(complete_packet || mes.get_mes_id() != measure_id) {
				complete_packet = false;
				measure_id = mes.get_mes_id();
				measure_width = mes.get_mes_width();
				measure = new short[measure_width];
				Arrays.fill(measure, (short)-1);
			}
			slice_width = mes.get_slice_width();

			measureMerger(mes.get_data(),mes.get_mes_id(),mes.get_seq_num());
		}
		if (msg instanceof AnnouncementMsg) {
			AnnouncementMsg mes = (AnnouncementMsg)msg;
//			System.out.println("Announcement: " + msg.getSerialPacket().get_header_src() + " " + mes.get_mes_number());
			if(mes.get_mes_number() > 0) {
				if(msg.getSerialPacket().get_header_src() != node_id) {//ha nem egyezik a jelenleg kommunikacioban levo mote_id-val
					mote_packetMap.put(msg.getSerialPacket().get_header_src(),(int)mes.get_mes_number());
				}
				else {
					tmp_packet_number = (int)mes.get_mes_number();				
				}
				if(!sending) {	
					sending = true;		//elkezdtunk venni, es vegig jarjuk a mote-kat
//TESTING
//					sendDataReq();		//elkezdjuk lekerni az adatokat a moteoktol
					timer = new Timer();
					timer.schedule(new GetSliceRemind(), 500);	//500ms varakozas az announcmentekre
					msg_mode = 1;
//END
				}
			}
		}
	}

//TESTING
//	public void sendDataReq() {
	public boolean sendDataReq() {
//END
		CommandMsg msg = new CommandMsg();
		try{
			if(mote_packetMap.size() > 0) { 	//ha van mote bejelentkezve	
				node_id = mote_packetMap.keySet().iterator().next();
		  		total_packet_number = mote_packetMap.get(node_id);			
				msg.set_node_id_start(node_id);	
				msg.set_node_id_stop(prev_node_id);	//kezdetben a prev_node_id = 0
//TESTING
				if(!mote_list.contains(node_id)) {
					msg.set_node_id_start(0);	
					msg.set_node_id_stop(prev_node_id);
					prev_node_id = node_id;
					moteIF.send(MoteIF.TOS_BCAST_ADDR,msg); 
					msg.set_node_id_stop(node_id);					
					mote_packetMap.remove(node_id);
				}
//END
			} else {		//minden motetol lekertuk az adatokat, a sor vegen vagyunk
				msg.set_node_id_start(0);
				msg.set_node_id_stop(prev_node_id);
			}

			short[] free_tmp = new short[DELETE_MES_NUMBER];			
			for(int i=0; i<DELETE_MES_NUMBER; i++) {
				free_tmp[i] = (short)free_mes[i];
			}
			Arrays.fill(free_mes,(short)0);
			msg.set_free(free_tmp);
			moteIF.send(MoteIF.TOS_BCAST_ADDR,msg); 
//TESTING
			if(mote_packetMap.size() == 0) {
				commEnd();
				return true;
			}
			if(!mote_list.contains(node_id))
				return false;		
//END
		} catch(IOException e) {
			out.println("sendDataReq message cannot send to mote ");
		}
		return true;
	}

//meres mentese
	void measureMerger(short[] data, int mes_id, short seq_id) {		//szeleteket teljes csomagokka teszi ossze
		timer = new Timer();
		timer.schedule(new GetSliceRemind(), 2000);
		msg_mode = 3;

		for(int i=0; i<slice_width; i++) {	
			measure[i+seq_id*(DATA_LENGTH)] = data[i];
		}

		if(seq_id == getSliceNumber() && !end_slice) {		//ha az utolso meres is megjott
//			msg_mode = 0;
			end_slice = true;			//utolso id-s szelet mar egyszer megjott
			allSliceChecker();		//minden szelet megvan
		}
		if(end_slice && missing_slice.isEmpty()) { 	//minden meres megerkezett		
//			msg_mode = 0;
			allSliceReceived();
		}
		if(!missing_slice.isEmpty()) {						//van szelet amit le kell kerni
//			msg_mode = 0;
			sendSliceReq();
		}
	}

//leellenorizzuk, hogy minden szeletet megkaptunk-e
	boolean allSliceChecker() {		
		missing_slice.clear();
		for(int j=0; j<=getSliceNumber(); j++) {	//egesz szamu a csomagmeret/szeletmeret
			if(measure[j*(DATA_LENGTH)] == -1) {	//ha a szelet elso cellaja -1, akkor nincs meg az a szelet
				missing_slice.add(j); 				//melyik szeletek hianyoznak
				missing_packet = measure_id;		//hanyadik csomag
			}
		}
		if(!missing_slice.isEmpty()) {
			return false;		//van hianyzo adat, igy false-al terunk vissza
		}
		return true;		//minden adat megvan
	}

//minden szelet megerkezett a meresbol
	void allSliceReceived() {
		end_slice = false;
		complete_packet = true;
		free_mes[fm_number] = measure_id;		//minden szelet megerkezett a meresbol, mostmar ki lehet torolni
		fm_number = DELETE_MES_NUMBER-1 == fm_number ? 0 : fm_number+1; 
		fileWriter();
		received_packet_number++;		//megkapott uzenetek szamat noveljuk
		if(received_packet_number >= total_packet_number)	{	//utolso meres is megerkezett			
			allPacketReceived();
		}else		//nem erkeztunk az utolso mereshez, az adott mote-nal
			sendFree();	
	}

//minden csomagot megkaptunk a mote-tol
	void allPacketReceived() {
		received_packet_number = 0;
		total_packet_number = 0;
		mote_packetMap.remove(node_id);	//kitoroljuk a listabol a mote-ot
		if(tmp_packet_number != 0) { 	//ha kozben jott announcment, hogy van adata, akkor a sor vegere tesszuk a motet {}
			mote_packetMap.put(node_id, tmp_packet_number);		
			tmp_packet_number = 0;
		}
		prev_node_id = node_id;
//TESTING
//		sendDataReq();	//elkezdjuk kerni a kov motetol az adatokat
		sendDataReqControl();
//END
	}

//megszunt a kommunikacio a mote-kal, vagy vege az adatlekereseknek
	void commEnd() {
		if(interrupt) {		//ha megszakitas volt, vagyis elkezdtek merni a moteok, mikozben adatlekeres folyt
			mote_packetMap.put(node_id,total_packet_number-received_packet_number);
		}
		node_id = 0;
		prev_node_id = 0;
		missing_packet = 0;
		missing_slice.clear();
		complete_packet = true;
		Arrays.fill(free_mes,(short)0);
		sending = false;
		
//TESTING
		System.exit(1);
//END
	}

//fajlba irjuk a merest
	void fileWriter() {			//fajlba irja a csomagokat
		time = new Date();
		DATE_FORMAT = new SimpleDateFormat("dd-MM-yyyy");
		String date_dir = DATE_FORMAT.format(time);
// //csv
// 		File dir_csv = new File("measures/csv/");
// 		dir_csv.mkdirs();
// 		if (null != dir_csv)
// 			dir_csv.mkdirs();
// 		DATE_FORMAT = new SimpleDateFormat("dd-MM-yyyy:HH:mm:SS");
// 		String date = DATE_FORMAT.format(time);
// 		
// 		String pathprefix_csv = "measures/csv/" + measure_id + ". packet_";	
// 		Measurement meas = new Measurement(new Date(), node_id, measure, pathprefix_csv);
//         meas.print();
// 
// //txt
// 		File dir_txt = new File("measures/txt/");
// 		dir_txt.mkdirs();
// 		if (null != dir_txt) 
// 			dir_txt.mkdirs();
// 		String pathprefix_txt = "measures/txt/" + measure_id + ". packet_";		
// 		Measurement meas_txt = new Measurement(new Date(), node_id, measure, pathprefix_txt);
//         meas_txt.printTXT();
//bin
		File dir_bin = new File("measures/binary/");
		dir_bin.mkdirs();
		if (null != dir_bin) 
			dir_bin.mkdirs();
		String pathprefix_bin = String.format("measures/binary/",measure_id);
		Measurement meas_bin = new Measurement(new Date(), node_id, measure, pathprefix_bin);
        meas_bin.printBin();
	}
	
//egy szelet kerest kuldunk el
	public void sendSliceReq() {
		GetSliceMsg msg = new GetSliceMsg();
		try{
			int miss_slice = missing_slice.get(0);	//az elso elemet kivesszuk, es kitoroljuk
			missing_slice.remove(0);
			msg.set_slice((short)miss_slice);
			msg.set_mes_id(missing_packet);
			msg.set_node_id(node_id);
			moteIF.send(MoteIF.TOS_BCAST_ADDR,msg);
		} catch(IOException e) {
			out.println("SliceReq message cannot send to mote ");
		}
	}

//torolje ki a mar elkuldott csomagokat
	public void sendFree() {		
		FreeMsg msg = new FreeMsg();
		try{
			short[] free_tmp = new short[DELETE_MES_NUMBER];
			for(int i=0; i<DELETE_MES_NUMBER; i++)
				free_tmp[i] = (short)free_mes[i];
			msg.set_free(free_tmp);
			msg.set_node_id(node_id);
			moteIF.send(MoteIF.TOS_BCAST_ADDR,msg);
		} catch(IOException e) {
			out.println("SliceFree message cannot send to mote ");
		}
	}
	
	public static void main(String[] args) throws Exception 
	{
		PhoenixSource phoenix = null;
		MoteIF mif = null;
//		System.out.println("Program started");

		if( args.length == 0 ){
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		} else if( args.length >= 2 && args[0].equals("-comm") ) {
			phoenix = BuildSource.makePhoenix(args[1], PrintStreamMessenger.err);
		} else {
			System.err.println("usage: java BaseStationApp [-comm <source>] mote1 mote2 mote3 ...");
			System.exit(1);
		}
		mif = new MoteIF(phoenix); 
		moteListReader(args);		
		BaseStationApp app= new BaseStationApp(mif); 
	}


	private class Measurement{
		private short[] data;
		private String pathprefix;
		  
		private Date timeStamp;
		private int nodeid;

		private long toLong(short[] from){
		  	long ret = (from[0]<<24) | (from[1]<<16) | (from[2]<<8) | from[3];
			return ret;
		}

		private int toInt(short[] from){
		  	int ret = (from[0]<<8) | from[1];
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
		
		public Measurement(Date timeStamp, int nodeid, short[] rawData, String pathprefix){
		  this.timeStamp = timeStamp;
		  this.nodeid = nodeid;
		  this.pathprefix = pathprefix;
		  data = Arrays.copyOf(rawData, rawData.length);
		}
		
		public void printBin(){
			int MeasId = toInt(Arrays.copyOfRange(data, data.length-2, data.length));
			Path path = Paths.get(String.format("%s%05d_%05d.raw",pathprefix, MeasId, nodeid));
			ByteArrayOutputStream bos = new ByteArrayOutputStream(); 
			DataOutputStream dos = new DataOutputStream(bos);
			try{
				for(short meas:data){
					dos.writeByte((byte)meas);
				}
				dos.writeLong(timeStamp.getTime());
				dos.close();
				Files.write(path, bos.toByteArray()); //creates, overwrites
			} catch(IOException e){
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}

			
	}


//TEST METHODS
	static void moteListReader(String[] args) {
		mote_list = new ArrayList<Integer>();
		for(int i=2; i<args.length; i++) {
			mote_list.add(Integer.parseInt(args[i]));
		}
//		System.out.println(mote_list);
	}	

	void sendDataReqControl() {
//		System.out.println("PacketMap: " + mote_packetMap + " size: " + mote_packetMap.size());
		while(!sendDataReq() && mote_packetMap.size() > 0);
/*		{
			msg_mode = 1;
			timer = new Timer();
			timer.schedule(new GetSliceRemind(), 100);
		}*/
	}	
}

