#!/bin/bash
exec >&2 > task4_1.out
if [[ ! -f /usr/sbin/dmidecode ]]; then

  apt-get update -y -qq
  apt-get install  dmidecode iproute2 -y -qq

fi

MAN=$(dmidecode -s baseboard-manufacturer | sed -e '/^#/d')
BASE=$(dmidecode -s baseboard-product-name | sed -e '/^#/d')
SN_IN=$(dmidecode -s system-serial-number | sed -e '/^#/d')
###########################
if [ "$SN_IN" == "" ] || [ ! "$SN_IN" ]; then
   SN="Unknown"
else
   SN=$SN_IN
fi

#######################
if [ "$MAN" ] && [ "$BASE" ] || [ ! "$MAN" == "" ] && [ ! "$BASE" == "" ]; then
   MOBO="$MAN $BASE"
elif [ "$MAN" ] && [ ! "$BASE" ] || [ ! "$MAN" == "" ] && [  "$BASE" == "" ]; then
   MOBO="$MAN"
elif [ ! "$MAN" ] ; then
   MOBO="Unknown"
fi
########################

OS_NAME=$(cat /etc/*release*| grep "^NAME=" | cut -d'=' -f2 | sed -e 's/"//g')
OS_RCN=$(cat /etc/*release*| grep "^VERSION=" | cut -d'=' -f2 | sed -e 's/"//g' | sed -e 's/(//g' | sed -e 's/)//g' )

echo "--- Hardware ---"
grep "model name"  /proc/cpuinfo | head -n 1 | sed -e 's/\s\+/ /g' | sed -e 's/model name :/CPU:/g'
grep MemTotal /proc/meminfo | sed -e 's/\s\+/ /g' | sed -e 's/MemTotal:/RAM:/g' | sed -e 's/.*/\U&/g'
echo "Motherboard: $MOBO"
echo "System Serial Number: $SN"
echo "--- System ---"
echo "OS Distribution: $OS_NAME $OS_RCN"
echo "Kernel version: $(uname -r )"
echo "Installation date: $(fs=$(df / | tail -1 | cut -f1 -d' ') && tune2fs -l $fs | grep created | sed -e 's/\s\+/ /g' | cut -d':' -f2- | sed -e 's/^\s//g')"
echo "Hostname: $(hostname -f)"
echo "Uptime: $(uptime -p | cut -d' ' -f2-)"
echo "Processes running: $(ps uax | wc -l)"
echo "User logged is: $(uptime|cut -d',' -f2 |sed -e 's/\([0-9]*\) users/\1/g' | sed -e 's/\s\+//g')"
echo "--- Network ---"
i=0
for iface in $(ip a | grep "^[0-9]" | cut -d':' -f2 ); do
        #$(ip a | grep inet | cut -d'/' -f 1 |sed -e 's/\s\+inet\s\+//g')
        IP=$(ip a | sed -n "/^[0-9]*:\s${iface}/,/^[0-9]*:/p"| awk -F"brd" '{print $1}' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}.[0-9]{1,2}\b" | tr '\n' ' '| sed -e 's/\([0-9]\)\s\([0-9]\)/\1, \2/g')
        #IP=$(ip a | grep "${iface}" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
        ### tail -n 1 | cut -d'/' -f1 | sed -e 's/\s\+inet\s\+//g')
        if [ "$IP" ]; then
           echo "$iface: $IP"
        else
           echo "$iface: -"
        fi
done
