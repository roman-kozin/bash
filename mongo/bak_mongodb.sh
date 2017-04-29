#!/bin/bash

TN=mongo-daily-bak

OF=$TN-`date '+%y%m%d%H%M'`.tar.gz

LOGFILE=/var/bak/mongo/backup.log
SRCD="/var/bak/mongo/mongodb"
TGTD="/var/bak/mongo/mongodbtar/"
SRCHOST="127.0.0.1:27017"
MAX_BACKUPS=5

rotateBackups() {
    echo "     >> Rotate mongo backups"  >>$LOGFILE
    files_rm=`ls $TGTD | sort -r`
    i=1
    for file_rm in $files_rm; do
        if ! [ $i -le $1 ]; then
            rm -rf $TGTD$file_rm &>>$LOGFILE
        fi
        i=`expr $i + 1`
    done
}

echo  >>$LOGFILE
echo "====================================================="  >>$LOGFILE
echo "$(date +'%d-%b-%Y %R')" >>$LOGFILE
echo "Задание \"$TN\" запущено..." >>$LOGFILE

OLD_IFS=$IFS

IFS=$'\n'

mongoDump() {

    if ! [ -d $SRCD ]; then
	mkdir -p $SRCD
    fi

    if ! [ -d $TGTD ]; then
	mkdir -p $TGTD
    fi

    if [ ! -f /usr/bin/mongodump ]; then
	echo "Установите пакет с mongodump"
	exit 1
    fi

    rm -Rf $SRCD/*

    /usr/bin/mongodump --host $SRCHOST -o $SRCD &>>$LOGFILE
}

mongoDump

STATUS=$?

IFS=$OLD_IFS

if [[ $STATUS != 0 ]]; then
    rm $TGTD$OF &>>$LOGFILE
    echo "###########################################" >>$LOGFILE
    echo "###  Произошла ошибка! Бэкап не удался. ###" >>$LOGFILE
    echo "###########################################" >>$LOGFILE
    echo "$(date +'%d-%b-%Y %R%nФайл') бекапа $OF не создан" &>>$LOGFILE
    /var/bak/mongo/zext_msmtp.sh backup@moneyman.ru "Mongodb backup fails on 52.58.249.136" "Mongodb backup fails on 52.58.249.136"
else
    tar -czf $TGTD$OF $SRCD &>>$LOGFILE && rm -Rf $SRCD/* &>>$LOGFILE
    rotateBackups $MAX_BACKUPS
    echo "Файл бэкапа сохранен как \"$TGTD$OF\"" >>$LOGFILE
    echo "Бэкап успешно завершен в $(date +'%R %d-%b-%Y')!" >>$LOGFILE
fi

exit
