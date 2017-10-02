#!/usr/bin/env bash

portsnap fetch
portsnap extract
cd /usr/ports/converters/libiconv/
make deinstall
cd /usr/ports/security/openvpn
make install clean
mkdir -p /usr/local/etc/openvpn
echo -e 'openvpn_enable=”YES”\nopenvpn_configfile=”/usr/local/etc/openvpn/openvpn.conf”' >> /etc/rc.conf
echo -e 'firewall_enable="YES"\nfirewall_script="/etc/ipfw.rules"' >> /etc/rc.conf
env ASSUME_ALWAYS_YES=YES pkg install geoip
