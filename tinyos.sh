export TOSROOT=/opt/tinyos-2.x
export TOSDIR=$TOSROOT/tos
JAVADIR=$TOSROOT/support/sdk/java
export CLASSPATH=$CLASSPATH:$JAVADIR:$JAVADIR/tinyos.jar:$JAVADIR/argparser.jar:$JAVADIR/Jama-1.0.2.jar:$JAVADIR/jline-0.9.94.jar:.
export PYTHONPATH=$PYTHONPATH:$TOSROOT/support/sdk/python
export MAKERULES=$TOSROOT/support/make/Makerules
