CSVProcess ReadMe
The CVSProcess reads the parameters from a configuration file.
The only argument we have to provide is the path of that configuration file.
If we run CVSProcess without any given argument, then it will looking for "csv.ini" at the running directory.

Form of the parameters:
Only one parameters per lines are allowed.
nameofparameter(case insensitive) = value
eg.: insertGlobal=true
or 
nameofparameter(case insensitive)="value"
eg.: separator=" "

The following parameters can be in the configuration file. We only have to write those which we want to modify.
The parameters which are missing from the configuration file will be set to the default value. 


separator
	String(character) value, separator of the values of different columns in output files,  default is ";"

nodeIdSeparator
	String(character) value, separator of header id from node id in header of output files  ,default is ":"
		
maxerror
	Integer value, determines the threshold in detecting disruptions in local timeline ,default value is 120

timeformat
	String value, determines the time display format, default is "yyyy.MM.dd/HH:mm:ss.SSS"

confFile
	String value, path of the used structure's configuration file, default is "structs.ini"

csvExt
	String value, extension of output files, when there are more files, default is ".csv" 

startTime
	Long value [min, any long value], determines the starting time of the merging in the global file, default is "min" 

endTime
	Long value [max, any long value], determines the ending time of the merging in the global file, default is "max" 

timeWindow
	Long value, determines the length of the average calculation in millisecundums, default is 900000

timeType
	String value [start,end,middle], determines whether the starting, ending or middle of the time period
	 should be displayed at the averages, default is start

If we have different structures in our data set, we can process them separately. 
To do so we have to set some structure related parameters.
After the global parameters we have to place structure keyword and the name of that structure.   
The parameters of the structure can follow this line. We can repeat it with every structure. 
eg.:structure data


localColumn
	Integer value, indicates the column of the local time,  no default value, 
	this is field is mandatory
	
globalColumn
	Integer value, indicates the column of the global time,  no default value, 
	this is field is mandatory
	
dataColumns
	List of Integer values separated by ',' ,shows which are the data columns, no default value, 
	this is field is mandatory

outputFileName
	String value, prefix of the structure's output file, default is "global"
	
insertGlobal
	Boolean value [true,false], determines whether we want to insert the global time column into the output file, default value is "true"

avgOutputFileName
	String value, the prefix of the output file of the averages, default is "avgfile"
	
Every structure must be closed, by the endofstruct keyword.	
	
