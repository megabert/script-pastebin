#!/bin/bash 

#
#	brute_force_calculator.sh
#
#	Calculates the max. time to get a password by brute-force-trying at
#	a given speed with given different charsets
#


# Speed of testing in Nr of Million tests per second
SPEED=10000

# PW_LEN Min + Max
PW_LEN=(6 12)

# character sets: quote correctly!
SETS=(
	"a-z" 
	"a-zA-Z" 
	"a-zA-Z0-9" 
	"a-zA-Z0-9_./=+*" 
	"a-zA-Z0-9!._/\"§$%&()=?*+#':,;^°~{}[]\\|-"
	)

function expand_charset 	{ perl -pe 's/(.)-(.)/join("",$1..$2)/ge' <<<"$1"; }	# $1 = charset
function get_possibilities 	{ bc <<<"scale=0;($2^$1)/1000000;"; }			# $1 = pw_length, $2 = count_chars
function calc_time 		{ bc <<<"scale=1;$2/$1;scale=0;$2/$1"; }		# $1 = calc_speed, $2 = nr_possibilities

function format_time {

	# generate human readable time from seconds

	local SECS=$1
	local SECS_INT=$2
	# echo >&2 ">> $SECS_INT <<"

	local INT=(1 60 3600 86400 604800 2592000 31536000)
	local INT_NAMES=(second minute hour day week month year)
	
	[ $SECS_INT == 0 ] && echo "0$SECS seconds" && return

	for((i=1;$i<${#INT[*]};i++)) ; do
		if [ $SECS_INT -lt ${INT[$(($i))]} ] ; then
			echo "$(bc <<<"scale=1;$SECS/${INT[$(($i-1))]}") ${INT_NAMES[$(($i-1))]}s" 
			return
		fi
	done

	echo "$(bc <<<"scale=1;$SECS/${INT[-1]}") ${INT_NAMES[-1]}s"
}

function format_int {
	NR="$1"
	NR_FORMATTED=""
	
	for((i=${#NR},z=0;$i>=0;i--,z++)) ;do
		NR_FORMATTED="${NR:$i:1}$NR_FORMATTED"
		[ "$(($z%3))" == "0" -a $z != "0" ] && NR_FORMATTED=".$NR_FORMATTED"
	done
	echo $NR_FORMATTED
}

# ---------- MAIN PROGRAM STARTS HERE -------------------

echo -e "\nMax. compute time of brute force testing at Speed of $(format_int $SPEED) million tests per Second\n"

for SET in "${SETS[@]}" ;do
	EXPANDED="$(expand_charset "$SET")"
	echo -e "\tCharset: ${#EXPANDED} Characters: $SET"
	echo 
	for((PW_LENGTH=${PW_LEN[0]};$PW_LENGTH<=${PW_LEN[1]};PW_LENGTH++)) ;do
		# set -x
		POSSIBILITIES="$(get_possibilities "$PW_LENGTH" "${#EXPANDED}")"
		CALC_TIME="$(calc_time "$SPEED" "$POSSIBILITIES")"
		TIME="$(format_time $CALC_TIME)"
		# TIME="$(format_time $(calc_time "$SPEED" "$(get_possibilities "$PW_LENGTH" "${#EXPANDED}")"))"
		set -- $TIME
		set +x
		printf "\t\tPassword length: %2s - Time: %9s %s\n" "$PW_LENGTH" "$1" "$2"
	done
	echo 
done

