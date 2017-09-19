#!/bin/bash

export LC_ALL=C

h1() { 

	local MSG="$*"
	local LEN=${#MSG}
	echo
	eval printf '*%.0s' {1..$(($LEN+8))}
	echo
	echo -e "*** $* ***"; 
	eval printf '*%.0s' {1..$(($LEN+8))}
	echo
	echo
}

h2() 		{ echo -e "*** $* ***\n"; }
error_exit() 	{ echo "ERROR: $*"; }

ip_config() {
	h2 "Interface IP-Address status"
	awk_block="$(
	ifconfig -a | gawk '
		# at an empty line all informations must exist
		match($0,/^[[:space:]]*$/) {
			if(ifname) {
				if(!ip) {
					ip_mask="";
				} else {
					ip_mask=ip"/"mask;
				}
				print ifname,mac,ip_mask ;
				ifname="";mac="";ip="";mask="";
				}
			}
		match($0, /^((en|eth)[^[:space:]]+)[[:space:]].*HWaddr[[:space:]](([0-9a-f]{2}:?)*)/ , a_ifname) { ifname=a_ifname[1];mac=a_ifname[3] } 
		match($0, /inet addr:([^[:space:]]+) .*Mask:([^[:space:]]+)/, a_ip) { ip=a_ip[1];mask=a_ip[2] }')"
	echo -e "$awk_block"
	MY_IPS="$(echo "$awk_block" | awk '{print $3}' | awk -F/ '{print $1}')"
	echo $ips
	echo

}

if_state() {
	h2 "Network Connection status"
	mii-tool 2>&1 | grep -E '^(en|eth)[^[:space:]]*:'
	echo
}

disks() {
	h2 "Disks"
	lsblk
	echo
}

my_ping() {
	if 	ping -c1 -i.2 -w2 $* &>/dev/null || \
		ping -c3 -i.2 -w5 $* &>/dev/null ; then

		echo success
	else
		echo fail
	fi
}

ip_connectivity() {

	h2 "Cluster IP-Connectivity"
	for ip in $* ; do
		if ! [[ $MY_IPS =~ $ip($|[[:space:]]) ]] ;then
			printf "checking host %-15s ... " "$ip"
			my_ping $ip
		fi
	done
	echo 

}

petasan_log() {

	h2 "PetaSAN Log"
	cat /opt/petasan/log/PetaSAN.log
	echo

}

hostinfo() {

	h1 "Diagnostic info for host $(hostname)"

}

clockinfo() {

	h2 "Server Clock"
	echo -e "Clock offset from $1: $(ntpdate -q 10.1.0.101 | grep stratum | awk '{print $6}' | tr -d ,)\n"
}

pci_info() {

	h2 "PCI Devices"
	lspci
	echo

}

requirements() {

	wich gawk &>/dev/null && error_exit "gawk not found, please install package"

}

requirements
hostinfo
clockinfo 10.1.0.101
if_state
ip_config 
ip_connectivity 10.1.0.101 10.5.3.11 10.5.4.11 10.1.0.102 10.5.3.12 10.5.4.12 10.1.0.103 10.5.3.13 10.5.4.13 8.8.8.8 www.google.de
disks
petasan_log
pci_info

