#!/bin/bash

while read id name; do
    echo "${name}"
    echo "-------------------------------"
    jexec ${id} "/root/check_openvpn.sh"
    echo "-------------------------------"
done < <(jls | grep transmission | awk '{ print $1" "$3 }')
