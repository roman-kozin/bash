DEBUG=1
if [ $DEBUG -gt 0 ]
then
        exec 2>>/tmp/zext_msmtp.log
        set -x
fi
# Default parameters
# FROM='zabbix@example.org'
FROM='zabbix@moneyman.kz'
MSMTP_ACCOUNT='zabbix'

# Parameters (as passed by Zabbix):
#  $1 : Recipient
#  $2 : Subject
#  $3 : Message
recipient=$1
subject=$2
message=$3
echo $message >> /tmp/zabbix.txt

date=`date --rfc-2822`

# Replace linefeeds (LF) with CRLF and send message
sed 's/$/\r/' <<EOF | msmtp --account $MSMTP_ACCOUNT $recipient
From: <$FROM>
To: <$recipient>
Subject: $subject
Date: $date
$message
EOF
