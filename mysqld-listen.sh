#!/bin/bash
 
checkMysql(){
        CMDCHECK=`lsof -i:3306 &>/dev/null`
        Port="$?"
        PIDCHECK=`ps aux|grep mysqld|grep -v grep`
        PID="$?"
        if [ "$Port" -eq "0" -a "$PID" -eq 0 ];then
                return 200
        else
                return 500
        fi
}
startMysql(){
        /etc/init.d/mysql start
}
checkMysql
if [ $? == 200 ];then
        echo "Mysql is running..."
else
        startMysql
        checkMysql
        if [ $? != 200 ];then
                while true
                do
                        killall mysqld
                        [ $? != 0 ] && break
						sleep 2
                done
                startMysql
        fi
fi