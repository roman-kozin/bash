#!/bin/bash

#################################
#
#  Manage MySQL and PPTPD script
#  Ver. 0.1b
#
#################################


### Setting ###

DBUSER='root'
DBPASS='uAdTpTrth7MKGEfcl37z'
DBHOST='localhost'

AUTHFILE='/home/r.kozin/.my.cnf'
BACKFOLDER='/home/r.kozin/mysqlusers_back'
BACKFILE=`date +%Y-%m-%d_%H:%M:%S.sql`

###############

if [ -z "$AUTHFILE" ]; then echo "[ ERROR ] Variable AUTHFILE is empty."; exit 1; fi
if [ -z "$BACKFOLDER" ]; then echo "[ ERROR ] Variable BACKFOLDER is empty."; exit 1; fi
if [ -z "$BACKFILE" ]; then echo "[ ERROR ] Variable BACKFILE is empty."; exit 1; fi

if [ ! -r "$AUTHFILE" ]; then 
	touch `echo $AUTHFILE`
	echo -e "[client]\n\nuser='$DBUSER'" > $AUTHFILE
	if [ -n "$DBPASS" ]; then echo "password='$DBPASS'" >> $AUTHFILE; fi
	if [ -n "$DBHOST" ]; then echo "host='$DBHOST'" >> $AUTHFILE; fi
fi

mkdir -p $BACKFOLDER

mysql_query() {
        /usr/bin/mysql --defaults-file=$AUTHFILE -BN -e "$1"
}


backupsGrants() {
	
	VERSION=$(mysql --defaults-file=$AUTHFILE -BN -e "SELECT @@version;")
	VERSION=`echo ${VERSION:0:3} |sed 's/\.//g'`
        if [ "$VERSION" -gt 56 ]; then
                #whiptail --title "MySQL query error" --msgbox "Detail: \n [ !WARNING! ] MySQL version 5.7 and higher not supported temorary. Backup users and grants not saved!" 30 120
		#echo "[ !WARNING! ] MySQL $VERSION not supported temorary. Backup users and grants not saved!"
                #exit 1;
		
		for i in `mysql --defaults-file=$AUTHFILE -BN -e "SELECT CONCAT('\'', user, '\'@\'', host, '\'') AS query FROM mysql.user;"`;
		do
			echo -e "## Create user and grants for $i ##";
			mysql --defaults-file=$AUTHFILE -BN -e "SHOW CREATE USER $i; SHOW GRANTS FOR $i;";
			echo -e "### \n";
		done >> $BACKFOLDER/$BACKFILE
        else
		mysql --defaults-file=$AUTHFILE -B -N -e "SELECT DISTINCT CONCAT('SHOW GRANTS FOR \'', user, '\'@\'', host, '\';') AS query FROM mysql.user" | mysql --defaults-file=$AUTHFILE | sed 's/\(GRANT .*\)/\1;/;s/^\(Grants for .*\)/## \1 ##/;/##/{x;p;x;}' >> $BACKFOLDER/$BACKFILE
	fi
}


OPTION=$(whiptail --title "MySQL User Management" --menu "Select an action" 15 60 8 "1" "Create MySQL user" "2" "Drop MySQL user" "3" "List MySQL users" "4" "Backup current MySQL Users and Privileges" "-" "" "5" "Create new pptp user" "6" "Drop pptp user" 3>&1 1>&2 2>&3)

case "$OPTION" in 
     1)
	USER=$(whiptail --title "New User" --inputbox "Input new Username" 10 60 3>&1 1>&2 2>&3)
	HOST=$(whiptail --title "Allow host" --inputbox "Input hostname or IP address" 10 60 % 3>&1 1>&2 2>&3)
	PASSWORD=$(whiptail --title "MySQL User Management" --passwordbox "Input password" 10 60 3>&1 1>&2 2>&3)
	CONFIRM=$(whiptail --title "MySQL User Management" --passwordbox "Confirm password" 10 60 3>&1 1>&2 2>&3)
		if [ -n "$USER" ] && [ -n "$PASSWORD" ]; then
			if [ $PASSWORD == $CONFIRM ]; then
				GRANTS=$(whiptail --title "MySQL User Management" --checklist "Select the grants for new user" 30 60 23 "ALL_PRIVILEGES" "" OFF "SELECT" "" OFF "INSERT" "" OFF "UPDATE" "" OFF "DELETE" "" OFF "FILE" "" OFF "CREATE" "" OFF "ALTER" "" OFF "INDEX" "" OFF "DROP" "" OFF "CREATE_TEMPORARY_TABLES" "" OFF "GRANT" "" OFF "SUPER" "" OFF "PROCESS" "" OFF "RELOAD" "" OFF "SHOW_DATABASES" "" OFF "REFERENCES" "" OFF "LOCK_TABLES" "" OFF "EXECUTE" "" OFF "REPLICATION_CLIENT" "" OFF "REPLICATION_SLAVE" "" OFF 3>&1 1>&2 2>&3)
				GRANTS=$(echo $GRANTS| tr -d \" | sed 's/ /, /g'|sed 's/_/ /g')
				
				if [ -n "$GRANTS" ]; then
					QUERY="CREATE USER '$USER'@'$HOST' IDENTIFIED BY '$PASSWORD'; GRANT $GRANTS ON * . * TO '$USER'@'$HOST'; FLUSH PRIVILEGES;"
					mysql_query "$QUERY"
					backupsGrants
					
					if [ $? = 0 ]; then
						whiptail --title "Successful" --msgbox "User \"$USER\" successful created. \n\n List of privilege user \"$USER\": \n $GRANTS \n\n Saved to file: $BACKFOLDER/$BACKFILE" 15 70
					else
						whiptail --title "MySQL query error" --msgbox "Detail: \n CREATE USER '$USER'@'$HOST' IDENTIFIED BY '$PASSWORD'; \n GRANT $GRANTS ON * . * TO '$USER'@'$HOST'; \n FLUSH PRIVILEGES;" 30 120
					fi
				else
					whiptail --title "Error" --msgbox "You have not selected GRANTS" 10 50
					$0
				fi
			else
				whiptail --title "Error" --msgbox "Passwords do not match." 10 50
				$0
			fi
		fi
	;;
     2)
	QUERY="SELECT CONCAT('\'', user, '\'@\'', host, '\'') AS query FROM mysql.user;"
	LIST=$(mysql_query "$QUERY")
	RESULT=$(whiptail --title "User list" --inputbox "List MySQL Uuser: \n\n $LIST \n\n\n Enter the full username from the list to delete." 30 60 3>&1 1>&2 2>&3)
	
	if [ -n "$RESULT" ]; then
		QUERY="DROP USER $RESULT"
		mysql_query "$QUERY"
		
		if [ $? = 0 ]; then
                	backupsGrants
                	whiptail --title "Successful" --msgbox "User \"$RESULT\" successful droped. \n\n Saved to file: $BACKFOLDER/$BACKFILE" 15 70
        	else
                	whiptail --title "MySQL query error" --msgbox "Detail: \n $QUERY" 30 120
                	$0
        	fi
	else
		$0
	fi
		
	#if [ $? = 0 ]; then
	#	backupsGrants
	#	whiptail --title "Successful" --msgbox "User \"$RESULT\" successful droped. \n\n Saved to file: $BACKFOLDER/$BACKFILE" 15 70
	#else
	#	whiptail --title "MySQL query error" --msgbox "Detail: \n $QUERY" 30 120
	#	$0
	#fi
	;;
     3)
	QUERY="SELECT CONCAT(' - ', '\'', user, '\'@\'', host, '\'') AS query FROM mysql.user;"
	LIST=$(mysql_query "$QUERY")
	whiptail --title "List Users" --msgbox "List MySQL Users: \n\n $LIST" 50 120
	;;
     4)
	backupsGrants
	if [ $? = 0 ]; then
		whiptail --title "Successful" --msgbox "Backup Users and Privileges successful created. \n\n Saved to file: $BACKFOLDER/$BACKFILE" 15 70
	else
		whiptail --title "MySQL query error" --msgbox "Detail: $?" 10 40
	fi
	;;
     -)
	$0
	;;
     5)
	if [ -w "/etc/ppp/chap-secrets" ]; then 
		USER=$(whiptail --title "PPTP User Management" --inputbox "Enter new PPTP username" 10 60 3>&1 1>&2 2>&3)
        	PASSWORD=$(whiptail --title "PPTP User Management" --passwordbox "Enter PPTP password" 10 60 3>&1 1>&2 2>&3)
		
		echo -e "$USER\t*\t\"$PASSWORD\"\t*" >> /etc/ppp/chap-secrets
		whiptail --title "Successful" --msgbox "PPTP user $USER successful created. \n\n [ WARNING ] PPTP Daemon need restart." 10 60
	else
		whiptail --title "Error" --msgbox "[ ERROR ] File /etc/ppp/chap-secrets not exist or not writable" 10 60
	fi
	;;
     6)
	if [ -w "/etc/ppp/chap-secrets" ]; then
		USER=$(whiptail --title "New User" --inputbox "Enter username for to delete" 10 60 3>&1 1>&2 2>&3)
		EXIST_USER=$(cat /etc/ppp/chap-secrets|awk '{print $1}'|grep -x $USER)
		
		if [ -n "$EXIST_USER" ]; then
			sed -i "/$EXIST_USER/d" /etc/ppp/chap-secrets
			whiptail --title "Successful" --msgbox "PPTP user $USER successful delited. \n\n [ WARNING ] PPTP Daemon need restart." 10 60
		else
			whiptail --title "Error" --msgbox "[ ERROR ] User $USER not found" 10 40
		fi
        else
                whiptail --title "Error" --msgbox "[ ERROR ] File /etc/ppp/chap-secrets not exist or not writable" 10 60
        fi
	;;
esac

