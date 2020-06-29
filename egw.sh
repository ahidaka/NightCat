#!/bin/sh

#
# usage:
#
#   on bootup, egw.sh
#
#   from nightcat, egw.sh nightcat
#

TMPF="/var/tmp/dpride/update/lastone"
LOCKF="/var/tmp/dpride/lockfile.txt"
LOGF="/var/tmp/dpride/logfile.txt"
ETKF="/var/tmp/dpride/etkconfig.txt"
OPCF="/var/tmp/dpride/opcua.txt"
AZF="/var/tmp/dpride/.iotx/cs"

DPR_DIR="/var/tmp/dpride/"
BTL_NAMEF="/tmp/btlname.txt"
BTLF=""

echo \
@ Boot Manager Version 1.25 
#                          ^ Caution this space should be needed to show the version.

# only bootup time execute this
if [ "$1" != "nightcat" ] ; then  

    BTL_NAME=btl-`date +%Y%m%d-%H%M%S`.log
    BTLF=${DPR_DIR}logs/${BTL_NAME}
    echo ${BTLF} > ${BTL_NAMEF}
    
    LOG_LINE=`date '+%m/%d/%y %H:%M:%S'`,egw-start,,
    echo ${LOG_LINE} >> ${BTLF}
    echo DBG: ${LOG_LINE}  ##### DBG

    if [ -r "${TMPF}" ] ; then
	(cd / ; /bin/tar xzf "${TMPF}" ; /bin/rm -f "${TMPF}" )
    fi

    sleep 1
    echo "5 operation" > /var/tmp/dpride/eoparam.txt

    rm -rf ${LOCKF} 

    (cd /home/pi/newgw/node/modules; pm2 start app.js)
fi

#
# Main process
#

CHECK_PGM="dpride"

if [ "${BTLF}" = "" ] ; then
    BTLF=`cat ${BTL_NAMEF} | sed -e "s/[\r\n]\+//g"`
fi

echo DBG: BTLF=${BTLF} ##### DBG

# Check lockfile
if [ -r ${LOCKF} ] ; then
    LOG_LINE=`date '+%m/%d/%y %H:%M:%S'`,ncat-locked,,
    echo ${LOG_LINE} >> ${BTLF}
    echo DBG: ${LOG_LINE}  ##### DBG
    exit
fi

if [ -r ${LOGF} ] ; then
    . ${LOGF}
fi

if [ -r ${ETKF} ] ; then
    CHECK_PGM="${CHECK_PGM} etk"
else
    rm -rf ${DPR_DIR}etk.pid
fi

if [ -r ${OPCF} ] ; then
    CHECK_PGM="${CHECK_PGM} opcua"
else
    rm -rf ${DPR_DIR}opcua.pid
fi

if [ -r {AZF} ] ; then
    CHECK_PGM="${CHECK_PGM} azure"
else
    rm -rf ${DOR_DIR}azure.pid
fi

echo DBG: CHECK_PGM=${CHECK_PGM} ##### DBG


##BROKER_FILE=/var/tmp/dpride/brokers.txt
##for file in `cat ${BROKER_FILE}` ; do
for file in ${CHECK_PGM} ; do

    sleep 1
    PID=""
    SYM=`echo ${file} | sed -e "s/[\r\n]\+//g"`
    ALREADY_RUNNING=""
    PGM=""
    if [ -r ${DPR_DIR}${SYM}.pid ] ; then
	PID=`cat ${DPR_DIR}${SYM}.pid | sed -e "s/[\r\n]\+//g"`
    fi
    case ${SYM} in
	"dpride")
	    PGM="dpride"
	    ;;
	
	"etk")
	    PGM="local/bin/client"
	    ;;

	"opcua")
	    PGM="EnOceanJob"
	    ;;
	"azure")
	    PGM="simulated_device_cloud"
	    ;;
	*)
	    #echo 'OTHER: [' ${SYM} ']'
	    ;;
    esac
    
    ps ax | fgrep ${PGM} | grep -v grep | awk '{ print $1 }' > /tmp/broker.tmp

    for list in `cat /tmp/broker.tmp` ; do

	PSLIST=`echo ${list} | sed -e "s/[\r\n]\+//g"`
	
	if [ "${PID}" = "${PSLIST}"  ] ; then
	    echo DBG: ${SYM} ALREADY_RUNNING="true" ### DBG
	    ALREADY_RUNNING="true"
	else
	    ALREADY_RUNNING=""
	fi
    done

    if [ "${ALREADY_RUNNING}" != "true" ] ; then
	logger -i "${PGM} not running"
	LOG_LINE=`date '+%m/%d/%y %H:%M:%S'`,${PGM}-notrun,,
	echo ${LOG_LINE} >> ${BTLF}
	echo DBG: ${LOG_LINE}  ##### DBG
	
	# heve to re-run
    else
	echo DBG: "${PGM} already running, continue" #### DBG
	continue;
    fi

    #
    # have to re-start
    #
    case ${SYM} in
	"dpride")
	    echo DBG: "DPRIDE"

	    if [ -x /usr/local/bin/dpride ] ; then
		#echo DEBUG: /usr/local/bin/dpride -L -l -o -e /var/tmp/dpride/eep.xml
		/usr/local/bin/dpride -L -l -o -e /var/tmp/dpride/eep.xml &
	    else
		LOG_LINE=`date '+%m/%d/%y %H:%M:%S'`,dpride-notfound,,
		echo ${LOG_LINE} >> ${BTLF}
		echo DBG: ${LOG_LINE}  ##### DBG
		continue;
	    fi
	    ;;
	
	"etk")
	    echo DBG: "ETK"
	    . ${ETKF}
	    
	    #echo 'USER=' ${user}
	    #echo 'DOMAIN=' ${domain}
	    #echo 'HOST=' ${host}
	    #echo 'PASS=' ${pass}

	    if [ ! -x /usr/local/bin/client ] ; then
		LOG_LINE=`date '+%m/%d/%y %H:%M:%S'`,client-notfound,,
		echo ${LOG_LINE} >> ${BTLF}
		echo DBG: ${LOG_LINE}  ##### DBG
		continue;
	    fi

	    if [ "${host}" != "" ] ; then
		if [ "${user}" = "" ] ; then
		    #echo DEBUG: /usr/local/bin/client ${ETKLOGFILE} -h ${host} -p 4502 -d "${domain}"
		    /usr/local/bin/client ${ETKLOGFILE} -h ${host} -p 4502 -d "${domain}" &
		else
		    #echo DEBUG: /usr/local/bin/client ${ETKLOGFILE} -h ${host} -p 443 -w -s -u "${user}" -P "${pass}" -d "${domain}"
		    /usr/local/bin/client ${ETKLOGFILE} -h ${host} -p 443 -w -s -u "${user}" -P "${pass}" -d "${domain}" &
		fi
	    fi
	    ;;
	
	"opcua")
	    echo DBG: "OPCUA"
	    . ${OPCF}

	    if [ ! -x /usr/local/bin/EnOceanJob ] ; then
		LOG_LINE=`date '+%m/%d/%y %H:%M:%S'`,EnOceanJob-notfound,,
		echo ${LOG_LINE} >> ${BTLF}
		echo DBG: ${LOG_LINE}  ##### DBG
		continue;
	    fi

	    if [ "${port}" != "" ] ; then
		#echo DEBUG: /usr/local/bin/EnOceanJob ${UALOGFILE} -p "${port}" -d "${domain}"
		/usr/local/bin/EnOceanJob ${UALOGFILE} -p "${port}" -d "${domain}" &
	    fi
	    ;;
	
	"azure")
	    echo DBG: "AZURE"

	    if [ ! -x /usr/local/bin/iot_edge ] ; then
		LOG_LINE=`date '+%m/%d/%y %H:%M:%S'`,iot_edge-notfound,,
		echo ${LOG_LINE} >> ${BTLF}
		echo DBG: ${LOG_LINE}  ##### DBG
		continue;
	    fi

	    IOTXCS=`cat /var/tmp/dpride/.iotx/cs`
	    if [ X"${IOTXCS}" != X"" ] ; then
		#echo DEBUG: /usr/local/bin/iot_edge ${AZLOGFILE}
		/usr/local/bin/iot_edge ${AZLOGFILE} &
	    fi
	    ;;
	
	*)
	    echo 'OTHER: [' ${SYM} ']'
	    ;;
    esac

done

if [ "$1" != "nightcat" ] ; then  
    /etc/rc.d/nightcat.sh &
fi
