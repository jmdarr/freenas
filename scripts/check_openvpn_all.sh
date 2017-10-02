#!/bin/bash

jail_search_string="transmission"

while read id name; do
    echo "${name}"
    echo "-------------------------------"
    jexec ${id} "/root/check_openvpn.sh"
    echo "-------------------------------"
done < <(jls | grep "${jail_search_string}" | awk '{ print $1" "$3 }')
