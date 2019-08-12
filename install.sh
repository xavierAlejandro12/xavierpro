#!/bin/sh
# How to use case-esac

YELLOW='\033[1;33m'
RED='\033[0;31m'
SET='\033[0m'

echo "${YELLOW}Please choice:${SET}"
echo "${YELLOW}1: GSM/GPRS Shield${SET}"
echo "${YELLOW}2: Base Shield${SET}"
echo "${YELLOW}3: Cellular Iot Shield${SET}"

read answer
case $answer in
    1)    echo "${YELLOW}You choose GSM/GPRS Shield${SET}";;
    2)    echo "${YELLOW}You choose Base Shield${SET}";;
    3)    echo "${YELLOW}You choose Cellular Iot Shield${SET}";;
    *)    echo "${YELLOW}You did not choose 1, 2 or 3${SET}"; exit 1;
esac

echo "${YELLOW}Downloading setup files${SET}"
wget --no-check-certificate  https://github.com/xavierAlejandro12/xavierpro/blob/master/chat-connect -O chat-connect

if [ $? -ne 0 ]; then
    echo "${RED}Download failed${SET}"
    exit 1; 
fi

wget --no-check-certificate  https://github.com/xavierAlejandro12/xavierpro/blob/master/chat-disconnect -O chat-disconnect

if [ $? -ne 0 ]; then
    echo "${RED}Download failed${SET}"
    exit 1;
fi

wget --no-check-certificate  https://github.com/xavierAlejandro12/xavierpro/blob/master/provider -O provider

if [ $? -ne 0 ]; then
    echo "${RED}Download failed${SET}"
    exit 1;
fi

while [ 1 ]
do
	echo "${YELLOW}Do you have updated kernel ? [y/N] ${SET}"
	read answer2
	
	case $answer2 in
		y)  break;;
		
		N)  echo "${YELLOW}rpi-update${SET}"
			rpi-update
		    break;;
		*)  echo "${YELLOW}You did not choose y, N${SET}";;
	esac
done

echo "${YELLOW}ppp install${SET}"
apt-get install ppp

echo "${YELLOW}What is your carrier APN?${SET}"
read carrierapn 

echo "${YELLOW}What is your device?${SET}"
read devicename 

EXTRA='OK AT+QCFG="nwscanseq",01,1\nOK AT+QCFG="nwscanmode",1,1\nOK AT+QCFG="iotopmode",2,1'

mkdir -p /etc/chatscripts
if [ $answer -eq 3 ]; then
  sed -i "s/#EXTRA/$EXTRA/" chat-connect
else
  sed -i "/#EXTRA/d" chat-connect
fi

mv chat-connect /etc/chatscripts/
mv chat-disconnect /etc/chatscripts/

mkdir -p /etc/ppp/peers
sed -i "s/#APN/$carrierapn/" provider
sed -i "s/#DEVICE/$devicename/" provider
mv provider /etc/ppp/peers/provider

if ! (grep -q 'route' /etc/ppp/ip-up ); then
    echo "sudo route del default" >> /etc/ppp/ip-up
    echo "sudo route add default ppp0" >> /etc/ppp/ip-up
fi

if [ $answer -eq 2 ]; then
	if ! (grep -q 'max_usb_current' /boot/config.txt ); then
		echo "max_usb_current=1" >> /boot/config.txt
	fi
fi

while [ 1 ]
do
	echo "${YELLOW}Do you want to activate auto connect/reconnect service ? [y/N] ${SET}"
	read answer3

	case $answer3 in
		y)    echo "${YELLOW}Downloading setup file${SET}"
			  
			  wget --no-check-certificate https://github.com/xavierAlejandro12/xavierpro/blob/master/reconnect_service -O reconnect.service
			  
			  if [ $answer -eq 1 ]; then
			  
				wget --no-check-certificate  https://raw.githubusercontent.com/sixfab/rpiShields/master/ppp_installer/reconnect_gprsshield -O reconnect.sh
			  
			  elif [ $answer -eq 2 ]; then 
			  
				wget --no-check-certificate  https://github.com/xavierAlejandro12/xavierpro/blob/master/reconnect_baseshield -O reconnect.sh
				
			  elif [ $answer -eq 3 ]; then 
			  
				wget --no-check-certificate  https://raw.githubusercontent.com/sixfab/rpiShields/master/ppp_installer/reconnect_cellulariot -O reconnect.sh
			  
			  fi
			  
			  mv reconnect.sh /usr/src/
			  mv reconnect.service /etc/systemd/system/
			  
			  
			  systemctl daemon-reload
			  systemctl enable reconnect.service
			  
			  break;;
			  
		N)   break;;
		*)   echo "${YELLOW}You did not choose y, N${SET}";;
	esac
done

reboot

