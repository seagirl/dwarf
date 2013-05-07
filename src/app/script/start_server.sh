#!/bin/sh
ROOT=${0%/*}/..
PID=$ROOT/starman.pid
PSGI=$ROOT/app.psgi
HOST=127.0.0.1
PORT=11022
MODE=debug

# オプションをハンドリング
while getopts m:h opt
do
	case $opt in
	m )    MODE=$OPTARG
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

cd $ROOT
if [ ${MODE} = 'production' ]
then
	starman -I lib -l $HOST:$PORT --pid $PID $PSGI
else
	plackup -I lib -R lib,tmpl --host $HOST --port $PORT $PSGI
fi