Using Transfer from console:
----------------------------------------------------------------------------------------
The following options can be used with Transfer.java.
The location of argparser.jar must be provided in the classpath.

-s, -structfile
    must be followed by the location of the structrures's definition file
    default is structs.ini

-i, -input
    determines the type of input, it must be followed by one of [binfile, serial, shimmer, textfile, console]
    [binfile, serial, shimmer] are binary, [textfile, console] are text input.
    default is "binfile" 
   
-if, -inputfile
    determines the input parameters
    if the input type is [binfile, textfile, shimmer] it must be followed by the filename(s) seperated by space,
      or it can be followed by a wild card, which specifies the ending of the files we want to process
      e.g: -if *.bin
    if the input type is [serial], than the location of the source must be provided followed by the bandwith
      e.g.: -if serial@/dev/ttyUSB1:57600
    if the input type is [console], than this option makes no effect
    no default value

-o, -output
    determines the type of output, it must be followed by one of [binfile, textfile, serial, console]
    [binfile, serial, shimmer] are binary, [textfile, console] are text output
    default is "console"

-of, -outputfile
    must be followed by the output file name, 
    can't be used for multiple file names 
    by default the output file(s) will be the same as the input file(s)
    only the extension will be replaced with the output extension 
    if the output is serial, this option determines the destination
     e.g.: -if serial@/dev/ttyUSB1:57600

-ox, -outputext
    determines the extension of output files, if there are more files
    default is "csv"

-om, -outputmode
    determines the way of output file handling
    must be followed by one of [rewrite, append, norewrite]
    -rewrite: new output file will be created
    -append: the output will be added to the end of the existing file,
       instead of creating a new file
    -norewrite: throws error, if the output file exists
    default is norewrite
    
-ms, -monostruct 
	 different structures have to be written into different files
	 the name of the struct showed in the filename    

-nh, -noheader 
    the fields name won't be displayed in the output
    by default the field's names are displayed at the beginning of every new struct

-ns, -nostruct 
    the name of the struct won't be displayed in every line of the output
    by default every line of the output starts with the name of the actual struct

-sr, -separator
    must be followed by the desired separator
    default value is: ';'

-vb, -verbose
    determines the level of information printed out during processing
    must be followed by one of [0, 1, 2]
    -0: no additional information except IO error
    -1: prints out warning, when finds an unprocessable frame,
         which doesn't apply to any of the structs
         also prints out the length of that frame
    -2: prints out the whole unmatching frame
    default is level 1 

-?, -help
    displays help information

-v, -version
    writes the version

Using Transfer as Thread:
----------------------------------------------------------------------------------------
You can use Transfer as a thread in your application. You have to determine the binary and string media and the direction of communication.
Here are the constructors:

public Transfer(String binaryType, String binaryPath, String stringType, String stringPath, String structPath, boolean toString,
	 String separator,boolean showName, byte outputMode, boolean monoStruct)
public Transfer(PacketParser[] packetParsers, BinaryInterface binary, StringInterface string, boolean toString)


Making new struct:
----------------------------------------------------------------------------------------
If you want to use a unique structure, you have to add it to the structs.ini (or the file you store the structures).
-To declare a new structure, you have to use "struct" keyword, the word after it will be the name of the structure. 
-Don't use special characters in the name of structures and variables!
-The content of a structure must be between '{' and '}' and must end with ';'

-To declare a variable you have to write it's type and name followed by ';'
-eg.: nx_le_uint8_t id;
-Integers start with endiannes indicator, "nx_le" means little endian, othwerwise the variable will be big endian.
-The next one is sign indicator, "uint" means unsigned integer, "int" means signed integer.
-The next is the size of the variable in bits, only 8, 16, 32 is supported

-Constants can be made by  providing the value of a variable after it's name.
-eg.: int8_t id=0x11;
In that case only those structs will be recognized, which have that exact value at the constant place

-It is possible to declare complex types. It means that the structure contains other structure.
-Multiple levels are allowed, but the inner structure must be defined first. See in the last example.

-To create an array of a variable, you have to put the size of the desired array in brackets 
-eg.: uint16_t value[1024];

-omit keyword should be added before the variable which doesn't have to be parsed.
-eg.:omit uint8_t id;  will result that the id won't be displayed in the output 

-The parser is case sensitive!
-The structure file mustn't contain other text like comments, license, author etc.


Sample:

struct simple{
  int8_t id=0x11;
  nx_le_uint16_t foo;
};

struct complex{
  int8_t id;
  simple const;
  nx_le_uint16_t humi;
  uint8_t light;
  omit uint32_t time;
  uint16_t value[1024];
};