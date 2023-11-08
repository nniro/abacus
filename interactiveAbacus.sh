#! /bin/sh

_AS_LIBRARY=1
. ./genAbacus.sh

if [ "$bb" = "" ]; then
	echo "This script requires busybox to work correctly"
	exit 1
fi

numDigits=8
currentValue=0
offset=30
if [ "$1" != "" ]; then # first argument is a description
	echo "$1"

	if [ "$2" != "" ]; then # second argument is the initial value
		currentValue=$2
	fi
fi

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

genAbacus $numDigits $offset "$currentValue"

printf "\033[%dG^\033[0G" $(($offset + ($numDigits * 2)))
printf "\033[9A"
cat << EOF
left, right: move
up, down: +/- 1
page up, down: +/- 5
<#>: number
q: quit
EOF
printf "\033[6B"
#echo "a : left - o : right - e : add 1 - j : rem 1 - u : add 5 - k : rem 5 - q : quit"
#echo "left, right : move - up, down : add 1, rem 1 - page up, down : add 5, rem 5 - <#> : number - q : quit"

colCursor=0
maxValue=$(echo "10^$numDigits" | bc -l)
lastInput=""
while :; do
	# we lose openBSD support with this or at least POSIX shells because -n <n> is not supported
	input=$($bb sh -c 'read -rsn 1 input; printf "$input"')

	#printf "$input" | $bb xxd -p

	if [ "$(printf "$input" | $bb xxd -p)" = "1b" ]; then
		# we got an escape command
		input=$(busybox sh -c 'read -rsn 2 input; printf "$input"')
	fi

	if [ "$lastInput" != "" ] && [ "$input" = "" ]; then
		input=$lastInput
	fi
	printf "\033[1A\033[2K"

	tempValue=$currentValue # save the value so it can be reverted
	case $input in
		q)
			clear
			echo "result : $currentValue"
			#echo "result : $(echo $currentValue | sed -e 's/^0*\([^0]\|0$\)/\1/')"
			exit 0
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
			currentValue=$(printf "%d + 10^%d\n" $currentValue $colCursor | bc -l)
			[ $((currentValue >= maxValue)) = 1 ] && currentValue=$tempValue
		;;
		j|[B) # -1
			currentValue=$(printf "%d - 10^%d\n" $currentValue $colCursor | bc -l)
			[ $((currentValue < 0)) = 1 ] && currentValue=$tempValue
		;;
		u|[5) # +5
			currentValue=$(printf "%d + 5 * 10^%d\n" $currentValue $colCursor | bc -l)
			[ $((currentValue >= maxValue)) = 1 ] && currentValue=$tempValue
		;;
		k|[6) # -5
			currentValue=$(printf "%d - 5 * 10^%d\n" $currentValue $colCursor | bc -l)
			[ $((currentValue < 0)) = 1 ] && currentValue=$tempValue
		;;
	esac
	lastInput=$input
	printf "\033[12A"
	genAbacus $numDigits $offset "$currentValue"
	printf "\033[%dG\033[2K^\033[0G" $(($offset + ($numDigits * 2) - ($colCursor * 2)))
	printf "\033[2B"
done
