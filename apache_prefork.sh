#!/bin/bash
TotalMem=$(free -m | grep Mem | awk '{ print $2 }')
HttpMem=$(ps aux | egrep 'httpd|apache2' | grep -v grep | awk '{sum +=$6}; END {print sum}')
HttpCount=$(ps aux | egrep 'httpd|apache2' | grep -v grep | wc -l)
Http1tread=$(echo "$HttpMem/$HttpCount/1024" | bc)
HttpMaxTreads=$(echo "$TotalMem/100*75/$Http1tread" | bc)
 
StartServers=$(echo "$HttpMaxTreads/5" | bc)
MinSpareServers=$StartServers
MaxSpareServers=$(echo "$MinSpareServers*2" | bc)
ServerLimit=$HttpMaxTreads
MaxClients=$HttpMaxTreads
MaxRequestsPerChild=$(echo "$MaxClients*$MinSpareServers" | bc)
 
echo -e "
<IfModule prefork.c>
StartServers\t    $StartServers
MinSpareServers\t    $MinSpareServers
MaxSpareServers\t    $MaxSpareServers
ServerLimit\t    $ServerLimit
MaxClients\t    $MaxClients
MaxRequestsPerChild\t    $MaxRequestsPerChild
</IfModule>
"
