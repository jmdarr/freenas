#!/usr/local/bin/bash

# some IFS malarky
OIFS=${IFS}
IFS=$'\n'

# this is the string we want:
# GeoIP Country Edition: CA, Canada
wantstring='CA, Canada'

# run the update script
echo -n "Updating geoip database... "
/usr/local/bin/geoipupdate.sh >/dev/null 2>&1 && echo "success" || echo "failure"

# before we go further, lets make sure our fw rules are for the right interface
# also try to overcome some VPN shenanigans
echo -n "Checking for multiple openvpn pids... "
[ $(ps aux | grep -v grep | grep openvpn | wc -l | awk '{ print $1 }') -gt 1 ] && {
    echo "found"
    echo -n "Trying to correct multiple running pids... "
    until [ $(ps aux | grep -v grep | grep openvpn | wc -l | awk '{ print $1 }') -eq 1 ]; do
        /usr/sbin/service openvpn stop >/dev/null 2>&1
        pkill openvpn >/dev/null 2>&1
        sleep 1
    done
    /usr/sbin/service openvpn start >/dev/null 2>&1 && echo "success" || echo "failure"
} || { echo "not found"; }

echo -n "Checking VPN tunnel iface name against firewall rules... "
fwiface=$(grep -Eio 'tun[0-9]{1}' /etc/ipfw.rules)
realiface=$(/sbin/ifconfig | grep -Eio 'tun[0-9]{1}')
[ "${fwiface}" != "${realiface}" ] && {
    echo "mismatch"
    echo -n "Attempting to correct firewall rules... "
    sed -i '' "s#${fwiface}#${realiface}#g" /etc/ipfw.rules >/dev/null 2>&1
    /usr/sbin/service ipfw restart >/dev/null 2>&1
    fwiface=$(grep -Eio 'tun[0-9]{1}' /etc/ipfw.rules)
    realiface=$(/sbin/ifconfig | grep -Eio 'tun[0-9]{1}')
    [ "${fwiface}" != "${realiface}" ] && echo "failure" || echo "success"
} || { echo "match"; }

# Get our output and make sure we're on the VPN
echo -n "Checking to see if VPN is active... "
output=$(/usr/local/bin/geoiplookup $(/usr/local/bin/wget -qO - http://icanhazip.com))
[[ "${output}" =~ "${wantstring}" ]] && {
    echo "active"
    # If we are, make sure transmission is running
    echo -n "Making sure transmission is online... "
    [[ "$(/usr/sbin/service transmission status 2>&1)" =~ "is running as pid" ]] && echo "online" || {
        echo "offline"
        echo -n "Starting transmission... "
        /usr/sbin/service transmission start >/dev/null 2>&1 && echo "success" || echo "failure"
    }
} || {
    # If we're not. stop transmission and restart openvpn
    echo "INACTIVE"
    echo -n "Stopping transmission... "
    service transmission stop >/dev/null 2>&1 && echo "success" || echo "failure"
    echo -n "Restarting openvpn... "
    service openvpn restart >/dev/null 2>&1 && echo "success" || echo "failure"
}


# more of that IFS crap
IFS=${OIFS}
