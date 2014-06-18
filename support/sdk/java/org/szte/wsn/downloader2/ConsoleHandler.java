package org.szte.wsn.downloader2;

import java.io.IOException;
import java.util.ArrayList;

import jline.ConsoleReader;
import jline.SimpleCompletor;
import jline.Terminal;

public class ConsoleHandler {
	private ConsoleReader reader;	
	private ArrayList<ConsoleCommand> commands=new ArrayList<ConsoleCommand>();
	private String prompt;
	private String helpCommand;
	private Terminal terminal=Terminal.setupTerminal();
	private boolean progressPrinted=false;
	private String name;
	
	private void exception(IOException e){
		System.err.println("Exception from ConsoleReader, exiting");
		e.printStackTrace();
		System.exit(1);
	}
	
	private String repetition(String base, int times){
		String ret="";
		for(int i=0;i<times;i++)
			ret+=base;
		return ret;
	}
	
	public void setProgress(long completed, long total, String preInfo, String postInfo) {
		if (terminal == null)
			return;
		reader.setDefaultPrompt("");
		int barWidth = reader.getTermwidth()/2-2;
		int progress=(int)((double)completed/total*barWidth);
		String bar=" ["+repetition("=",progress)+repetition("-",barWidth-progress)+"] ";
		String result=preInfo+bar+postInfo;
		progressPrinted=true;
		try {
	       reader.getCursorBuffer().clearBuffer();
	       reader.getCursorBuffer().write(result);
	       reader.setCursorPosition(reader.getTermwidth());
	       reader.redrawLine();
		}
		catch (IOException e) {
	       exception(e);
                               
		}
	}
	
	public void printWelcome(){
		System.out.println(name+" Type '"+helpCommand+"' for instructions");
	}
	
	public ConsoleHandler(String name,String prompt,String helpCommand){
		this.name=name;
		this.prompt=prompt;
		this.helpCommand=helpCommand;
		try {
			reader=new ConsoleReader();
		} catch (IOException e) {
			exception(e);
		}
		addCommand(helpCommand,"Prints all known commands");
	}
	
	private class ConsoleCommand{
		String fullCommand;
		String commandId;
		String help;
		
		public ConsoleCommand(String fullCommand, String commandId, String help){
			this.fullCommand=fullCommand;
			this.commandId=commandId;
			this.help=help;
		}
		
		public boolean match(String command){
			if(command.startsWith(commandId)&&fullCommand.startsWith(command)){
				return true;
			}else
				return false;
					
		}
		
	}
	
	public boolean addCommand(String command, String help){
		for(ConsoleCommand curr:commands){
			if(curr.fullCommand.equals(command))
				return false;
		}
		String commandId="";
		for(ConsoleCommand curr:commands){
			while(command.startsWith(curr.commandId)){
				curr.commandId=curr.fullCommand.substring(0,curr.commandId.length()+1);
				if(commandId.length()<curr.commandId.length())
					commandId=command.substring(0,curr.commandId.length());
			}
		}
		if(commandId.length()==0)
			commandId=command.substring(0,1);
		commands.add(new ConsoleCommand(command,commandId, help));
		reader.addCompletor(new SimpleCompletor(command));
		return true;
	}
	
	private ConsoleCommand searchCommand(String cmd){
		for(ConsoleCommand curr:commands){
			if(curr.match(cmd)){
				return curr;

			}
		}
		return null;
	}
	
	public void printCommandHelp(ConsoleCommand cmd){
		if(cmd==null){
			System.err.println("Unknown command. Type '"+helpCommand+"' for help.");
		} else if(cmd.help==null||cmd.help.equals("")){
			System.err.println("No help for command "+cmd.fullCommand);
		} else if(cmd.fullCommand.equals(helpCommand)){
			System.out.println("Known commands:");
			for(ConsoleCommand curr:commands){
				System.out.print("'"+curr.fullCommand+"' ");
			}
			System.out.println("For command help, type '"+helpCommand+" <command>'");
		} else {
			System.out.println("Help for command "+cmd.fullCommand);
			System.out.println(cmd.help);
		}
	}
	

	public void printHelp(String cmd) {
		printCommandHelp(searchCommand(cmd));		
	}
	
	public String readCommand(){
		String command=null;
		try {
			if(progressPrinted){
				progressPrinted=false;
				reader.getCursorBuffer().clearBuffer();
				reader.printNewline();
			}
			while(command==null){
				String readcmd[]=reader.readLine(prompt).split(" ");
				ConsoleCommand cmd=searchCommand(readcmd[0]);
				
				if(cmd==null){
					printCommandHelp(null);
				} else if(cmd.fullCommand.equals(helpCommand)){
					if(readcmd.length>2)
						printCommandHelp(null);
					else if(readcmd.length==1){
						printCommandHelp(cmd);
					} else {
						printCommandHelp(searchCommand(readcmd[1]));
					}
				} else {
					command=cmd.fullCommand;
					for(int i=1;i<readcmd.length;i++)
						command+=" "+readcmd[i];
					break;
				}
			}
		} catch (IOException e) {
			exception(e);
		}
		
		return command;
	}
	
	public String readChar(String allowed[]){
		String ret="";
		for(String s:allowed)
			s=s.toLowerCase();
		String prompt="[";
		for(String s:allowed){
			prompt+=s+"/";
		}
		prompt=prompt.substring(0,prompt.length()-1);
		prompt+="]";
		while(ret.length()!=1&&ret!=null){
			try {
				ret=reader.readLine(prompt);
			} catch (IOException e) {
				exception(e);
			}
			if(ret==null)
				break;
			ret=ret.toLowerCase();
			if(ret.length()==1){
				for(String s:allowed){
					if(ret.equals(s))
						return ret;
				}
				ret="";//no match, so we stay in the loop
			}
			System.err.println("Invalid input. Valid characters are: "+prompt);
		}
		return ret;//should never happend
	}

	
}
