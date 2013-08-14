#!/bin/sh
ROOT=${0%/*}/..
PID=$ROOT/starman.pid
PSGI=$ROOT/app.psgi
HOST=127.0.0.1
PORT=11022
MODE=debug
LOCAL=NO

# オプションをハンドリング
while getopts m:lh opt
do
	case $opt in
	m )    MODE=$OPTARG
	       ;;
	l )    LOCAL=YES
	       ;;
	h )    echo '% ./start_server.sh [<option>]
version 1.0
    	
option:
    -m mode
       if you pass production then this run starman. if not, this run plackup'
		   exit
		   ;;
    ? )    echo 'Usage -h'
		   exit
		   ;;
	esac
done

if [ ${LOCAL} = 'YES' ]
then
	/bin/sh -c "sleep 0.5; open -a Safari http://$HOST:$PORT" &
fi

cd $ROOT
if [ ${MODE} = 'production' ]
then
	carton exec starman -I lib -l $HOST:$PORT --pid $PID $PSGI
else
	carton exec plackup -I lib -R lib,tmpl --host $HOST --port $PORT $PSGI
fi
