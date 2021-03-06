#!/usr/bin/env sh

# - Configuration ----------------------------------------------------------
villagebus="/cgi-bin/villagebus"
version='r133'
timeout=2
LOG=1

# - Logging ----------------------------------------------------------------
BUFFER="/tmp/status.log"
echo > $BUFFER
log() {
    if [ "$LOG" = "1" ] ; then
        echo "$1" >> "$BUFFER"
    fi
}
log "- `date` - starting device status report ----------------"


# - Status information -----------------------------------------------------
log "querying device configuration"
wlanmode=`uci get wireless.@wifi-iface[0].mode`
device=`uci get wireless.@wifi-iface[0].device`
interface=`uci get network.$device.ifname`
self=`uci get network.$device.ipaddr`
root=`uci get afrimesh.settings.root`
device_id=`uci get afrimesh.settings.deviceid`
mac=`ifconfig $interface | grep HWaddr | awk '{ print $5 }'`
path_status="$root/db/device:$self:status"
path_history="$root/db/interface:$self:history"
log "device:    $device"
log "interface: $interface"
log "root:      $root"
log "self:      $self"
log "mac:       $mac"
log "deviceid:  $device_id"
log "path_status:  $path_status"
log "path_history: $path_history"

# don't report status info for unprovisioned devices
[ -z "$device_id" > /dev/null ] && {
    log "device has not been provisioned. exiting."
    exit
}

# misc information
log "querying system information"
#timestamp=`date +%s`000
timestamp=`date +%s`
uname=`uname -a`
uptime=`cat /proc/uptime | awk '{ print $1 }'`
idle=`cat /proc/uptime | awk '{ print $2 }'`
longitude=`uci get afrimesh.location.longitude`
latitude=`uci get afrimesh.location.latitude`

# traffic stats - TODO wifi0 as well
log "querying traffic statistics"
buffer=`cat /proc/net/dev|grep $interface`
bytes_tx=`echo $buffer | awk '{ print $2 }'`
bytes_rx=`echo $buffer | awk '{ print $10 }'`
bytes="{ 'tx' : $bytes_tx, \
         'rx' : $bytes_rx }"

# query radio signal levels
log "querying radio signal levels"
levels=`iwconfig $interface |grep Quality`
link_quality=`echo $levels | cut -d = -f 2 | awk '{ print $1 }'`
signal_level=`echo $levels | cut -d = -f 3 | awk '{ print $1 " " $2 }'`
noise_level=`echo $levels | cut -d = -f 4 | awk '{ print $1 " " $2 }'`
radio="{ 'rssi'   : '$link_quality', \
         'signal' : '$signal_level', \
         'noise'  : '$noise_level' }"


# - Query gateways --------------------------------------------------------- TODO mark default gw
log "querying mesh gateways:"
gateways=$(batmand -cbd2 | grep gateway |{
    while read line; do
        log "  $line"
        gateway_address=`echo $line | awk '{print \$2 }`
        nexthop_address=`echo $line | awk '{print \$4 }`
        score=`echo $line | awk 'BEGIN{FS="(";RS=")"}/\(/{print $2}'`
        failures=`echo $line | awk '{print \$13 }`
        #gateway_reply=`arping -f -w 2 -I $interface $gateway_address | grep reply`
        gateway_ping=`ping -w $timeout -c 1 $gateway_address 2> /dev/null | grep from | awk '{ print \$7 }' | cut -d = -f 2`
        [ -z $gateway_ping ] && gateway_ping="-1.0"
        nexthop_ping=`ping -w $timeout -c 1 $nexthop_address 2> /dev/null | grep from | awk '{ print \$7 }' | cut -d = -f 2`
        [ -z $nexthop_ping ] && nexthop_ping="-1.0"
        nexthop_arp=`cat /proc/net/arp |grep $nexthop_address | awk '{ print $4 }'`
        radio=`wlanconfig $interface list|grep $nexthop_arp`
        radio_rate=`echo $radio | awk '{ print $4 }'`
        radio_rssi=`echo $radio | awk '{ print $5 }'`
        radio_signal=`echo $radio | awk '{ print $5 }'`
        entry="{ 'address'  : '$gateway_address', \
                 'nexthop'  : '$nexthop_address', \
                 'score'    : $score, \
                 'ping'     : { 'gateway' : $gateway_ping, 'nexthop' : $nexthop_ping }, \
                 'radio'    : { 'rate' : '$radio_rate', 'rssi' : '$radio_rssi/70', 'signal' : '$radio_signal dBm'  } }"
        fails="{ 'address'  : '$gateway_address', \
                 'failures' : $failures }"
        if [ "$gateways" != "" ]; then
            gateways="$gateways, $entry"
            failures="$failures, $fails"
        else 
            gateways="$entry"
            failures="$fails"
        fi
    done
    echo "$gateways|$failures"
})
failures=${gateways#*|}
gateways=${gateways%|*}

# TODO - neighbors

# construct & send HTTP request for instantaneous data
log "constructing report for instantaneous data"
json="{ 'timestamp' : $timestamp, \
        'mac'       : '$mac', \
        'self'      : '$self', \
        'root'      : '$root', \
        'device_id' : '$device_id',
        'version'   : '$version', \
        'uname'     : '$uname', \
        'uptime'    : $uptime, \
        'idle'      : $idle, \
        'location'  : { 'longitude' : '$longitude', 'latitude' : '$latitude' }, \
        'bytes'     : $bytes, \
        'gateways'  : [ $failures ] }"
json=`echo -e $json` # echo -e on Linux seems to be nuking whitespace, which is throwing off the
                     # Content-Length calc :-/ Ffffffffffuuuuuuuuuuuuuuuuuuu!!!!!!!!!!
HTTP="PUT $villagebus/$path_status HTTP/1.0\n"
CONTENT_TYPE="Content-Type: text/plain\n"
CONTENT_LENGTH="Content-Length: ${#json}\n"
REQUEST="\
$HTTP\
$CONTENT_TYPE\
$CONTENT_LENGTH\
\n\
$json"
log "sending report for instantaneous data --------------------------------"
if [ "$LOG" = "1" ] ; then
    echo -n -e $REQUEST | nc $root 80 >> "$BUFFER" 2>&1
else
    echo -n -e $REQUEST | nc $root 80 >& /dev/null
fi
log "--"

# construct & send HTTP request for temporal data
log "constructing report for temporal data"
json="{ 'self'      : '$self', \
        'timestamp' : $timestamp, \
        'radio'     : $radio, \
        'gateways'  : [ $gateways ] }"
json=`echo -e $json` # echo -e on Linux seems to be nuking whitespace, which is throwing off the
                     # Content-Length calc :-/ Ffffffffffuuuuuuuuuuuuuuuuuuu!!!!!!!!!!
HTTP="POST $villagebus/$path_history HTTP/1.0\n"
CONTENT_TYPE="Content-Type: text/plain\n"
CONTENT_LENGTH="Content-Length: ${#json}\n"
REQUEST="\
$HTTP\
$CONTENT_TYPE\
$CONTENT_LENGTH\
\n\
$json"
log "sending report for temporal data -------------------------------------"
if [ "$LOG" = "1" ] ; then
    echo -n -e $REQUEST | nc $root 80 >> "$BUFFER" 2>&1
else
    echo -n -e $REQUEST | nc $root 80 >& /dev/null
fi
log "--"

log "status report complete"
log ""

# TODO - eventually we want _this_:
#
#   */5 * * * * /www/cgi-bin/status 2> /dev/null | /www/cgi-bin/villagebus POST /root/db/status/self

# TODO - print header if being called from Web, else just echo json
#echo "Content-type: application/json"
#echo "Content-type: text/plain"
#echo
#echo $json

