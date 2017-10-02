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
