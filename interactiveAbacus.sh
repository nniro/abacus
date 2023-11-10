#! /bin/sh

[ "$_AS_LIBRARY" = "" ] && _AS_LIBRARY=1 || _AS_LIBRARY=2
. ./genAbacus.sh
[ "$_AS_LIBRARY" = "1" ] && _AS_LIBRARY=""

if [ "$bb" = "" ]; then
	echo "This script requires busybox to work correctly"
	exit 1
fi

cursorUp() { printf "\033[%dA" "$1"; }
cursorDown() { printf "\033[%dB" "$1"; }

showButtonsHelp() {
	cursorUp 9
cat << EOF
left, right: move
up, down: +/- 1
page up, down: +/- 5
<#>: number
q: quit
EOF
	cursorDown 4
}

setValue() {
	local len=$1
	local rstValue=$2
	local rstPosition=$3
	local currentValue=$(echo $4 | addPadding $len)
	$bb awk -v rstValue=$rstValue -v value=$currentValue -v rst=$rstPosition '
BEGIN {
	len=split(value, arr, "")
	arr[len - rst]=rstValue
	for (i=1; i <= len; i++) {
		printf arr[i]
	}
}' | sed -e 's/^0*\([^0]\|0$\)/\1/'
}

handleInput() {
	local numDigits="$1"
	local decimalLen="$2"
	local outputVar="$3"
	local maxValue="$4"
	local colCursor="$5"
	local currentValue="$6"

	# we lose openBSD support with this or at least POSIX shells because -n <n> is not supported
	local input=$($bb sh -c 'read -rsn 1 input; printf "$input"')

	if printf "$input" | $bb xxd -p | grep -q "^1b"; then
		# we got an escape command
		input=$(busybox sh -c 'read -rsn 2 input; printf "$input"')
	fi

	local tempValue=$currentValue # save the value so it can be reverted
	case $input in
		q)
			if [ "$decimalLen" != "0" ]; then
				currentValue=$(printf "scale=$decimalLen; $currentValue / 10^$decimalLen" | $bb bc -l)
			fi
			clear
			if [ "$outputVar" = "" ]; then
				echo "result : $currentValue" >&2
			else
				eval $outputVar=$currentValue
			fi
			echo -1 -1
			return
		;;
		0) currentValue=$(setValue $numDigits 0 $colCursor $currentValue) ;;
		1) currentValue=$(setValue $numDigits 1 $colCursor $currentValue) ;;
		2) currentValue=$(setValue $numDigits 2 $colCursor $currentValue) ;;
		3) currentValue=$(setValue $numDigits 3 $colCursor $currentValue) ;;
		4) currentValue=$(setValue $numDigits 4 $colCursor $currentValue) ;;
		5) currentValue=$(setValue $numDigits 5 $colCursor $currentValue) ;;
		6) currentValue=$(setValue $numDigits 6 $colCursor $currentValue) ;;
		7) currentValue=$(setValue $numDigits 7 $colCursor $currentValue) ;;
		8) currentValue=$(setValue $numDigits 8 $colCursor $currentValue) ;;
		9) currentValue=$(setValue $numDigits 9 $colCursor $currentValue) ;;
		a|[D)
			if [ $((colCursor >= $numDigits - 1)) = 1 ]; then
				colCursor=0
			else
				colCursor=$((colCursor + 1))
			fi
		;;
		o|[C)
			if [ $((colCursor <= 0)) = 1 ]; then
				colCursor=$((numDigits - 1))
			else
				colCursor=$((colCursor - 1))
			fi
		;;
		e|[A) # +1
			currentValue=$(printf "%d + 10^%d\n" $currentValue $colCursor | $bb bc -l)
			[ $((currentValue >= maxValue)) = 1 ] && currentValue=$tempValue
		;;
		j|[B) # -1
			currentValue=$(printf "%d - 10^%d\n" $currentValue $colCursor | $bb bc -l)
			[ $((currentValue < 0)) = 1 ] && currentValue=$tempValue
		;;
		u|[5) # +5
			currentValue=$(printf "%d + 5 * 10^%d\n" $currentValue $colCursor | $bb bc -l)
			[ $((currentValue >= maxValue)) = 1 ] && currentValue=$tempValue
		;;
		k|[6) # -5
			currentValue=$(printf "%d - 5 * 10^%d\n" $currentValue $colCursor | $bb bc -l)
			[ $((currentValue < 0)) = 1 ] && currentValue=$tempValue
		;;
	esac
	echo $colCursor $currentValue
}

interactiveAbacus() {
	local numDigits=8
	local currentValue=0
	local offset=30
	local decimalLen=0
	local outputVar=""
	while getopts d:n:m:o: f 2>/dev/null; do
		case $f in
			d) decimalLen=$OPTARG;;
			n) numDigits=$OPTARG;;
			m) offset=$OPTARG; [ "$offset" = "0" ] && offset=1 ;;
			o) outputVar=$OPTARG;;
		esac
	done
	[ $(($OPTIND > 1)) = 1 ] && shift $($bb expr $OPTIND - 1)

	if [ "$1" != "" ]; then # first argument is a description
		echo "$1"

		if [ "$2" != "" ]; then # second argument is the initial value
			currentValue=$2
		fi
	fi

	local upArrow="^"

	genAbacus $numDigits $offset "$currentValue"

	printf "\033[%dG%s\033[0G" $(($offset + ($numDigits * 2))) "$upArrow"
	if [ $((offset >= 30)) = 1 ]; then
		showButtonsHelp
	fi
	cursorDown 2

	#echo "a : left - o : right - e : add 1 - j : rem 1 - u : add 5 - k : rem 5 - q : quit"

	colCursor=0
	maxValue=$(echo "10^$numDigits" | $bb bc -l)
	while :; do
		set -- $(handleInput "$numDigits" "$decimalLen" "$outputVar" "$maxValue" "$colCursor" "$currentValue")
		colCursor=$1
		currentValue=$2
		[ "$currentValue" = "-1" ] && return

		cursorUp 12
		genAbacus $numDigits $offset "$currentValue"

		printf "\033[%dG\033[2K%s\033[0G" $(($offset + ($numDigits * 2) - ($colCursor * 2))) "$upArrow"
		cursorDown 2
	done
}

if [ "$_AS_LIBRARY" = "" ]; then
	interactiveAbacus "$@"
fi
