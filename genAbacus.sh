#! /bin/sh

# can use \033 where \x1b is not supported
# \x1b7 save cursor position
# \x1b8 restore cursor position
# \x1b[6n get current cursor position
# \x1b[XG move cursor in the current row to X column
# \x1b[XA move cursor up by X amount
# \x1b[XB move cursor down by X amount

which busybox 2>/dev/null >/dev/null && bb=busybox || bb=""

valueToTAbacus() {
	$bb awk -v values="$1" '
BEGIN {
	len=split(values, arr, "")
	for (n=1; n <= len; n++) {
		if (arr[n] > 4) {
			result[1] = result[1] "1"
			result[2] = result[2] (arr[n] - 5)
		} else {
			result[1] = result[1] "0"
			result[2] = result[2] arr[n]
		}
	}
	print result[1] "\n" result[2]
}'
}

repeat() {
	$bb awk -v num=$1 -v str="$2" 'BEGIN {r=""; for (i=0; i < num; i++) {r=r str}; printf("%s", r)}'
}

genHorizontal() {
	local length=$1
	local offset=$2
	local startPattern="$3"
	local pattern="$4"
	local endPattern="$5"
	printf "\033[%dG%s" "$offset" "$startPattern"
	repeat $length "$pattern"
	echo "$endPattern"
}

genTopRow() {
	local offset=$1
	shift
	$bb awk -v v1="$1" -v v2="$1" '
BEGIN {
	gsub("0", " #", v1); gsub("1", " .", v1); printf("|%s |\n", v1)
	gsub("0", " .", v2); gsub("1", " #", v2); printf("|%s |\n", v2)
}' | \
	$bb awk -v offset=$offset '{sub("^", "\x1b[" offset "G")}1'
}

genBottomRow() {
	local offset=$1
	shift
	printf "$1\n$1\n$1\n$1\n$1\n" | $bb sed -e '
	1 { s/^/|/ ; s/0/ ./g ; s/[1-4]/ #/g ; s/$/ |/ ; }
	2 { s/^/|/ ; s/1/ ./g ; s/[0,2-4]/ #/g ; s/$/ |/ ; }
	3 { s/^/|/ ; s/2/ ./g ; s/[0-1,3-4]/ #/g ; s/$/ |/ ; }
	4 { s/^/|/ ; s/3/ ./g ; s/[0-3,4]/ #/g ; s/$/ |/ ; }
	5 { s/^/|/ ; s/4/ ./g ; s/[0-3]/ #/g ; s/$/ |/ ; }' | \
	$bb awk -v offset=$offset '{sub("^", "\x1b[" offset "G")}1'
}

addPadding() {
	local len=$(($1 - 1))
	$bb sed -e ":e; s/^.\{1,$len\}$/0&/ ; te"
}

genAbacus() {
	local nDigits="$1"
	local offset="$2"
	[ "$3" = "" ] && set -- 0
	set -- $(valueToTAbacus "$3" | addPadding $nDigits)

	genHorizontal $nDigits $offset " " "__" "_ "
	genTopRow $offset $1
	genHorizontal $nDigits $offset "|" "--" "-|"
	genBottomRow $offset $2
	genHorizontal $nDigits $offset " " "--" "- "
}

showHelp() {
	cat << EOF
Usage : $0 [-h] [-n INT] [-o INT] <value>

ASCII soroban abacus generator.

	-h	This help.
	-n INT	The amount of columns in the abacus.
	-o INT	Horizontal offset to draw the abacus.

EOF
}

if [ "$_AS_LIBRARY" = "" ]; then
	numDigits=8
	offset=20
	while getopts hn:o: f 2>/dev/null; do
		case $f in
			h) showHelp; exit 0 ;;
			n) numDigits=$OPTARG;;
			o) offset=$OPTARG;;
		esac
	done
	[ $(($OPTIND > 1)) = 1 ] && shift $($bb expr $OPTIND - 1)

	if [ "$2" != "" ]; then
		showHelp
		exit 1
	fi

	if [ "$offset" = "0" ]; then
		offset=1
	fi

	# valueToTAbacus 99999999

	if [ "$1" = "" ]; then
		set -- 0
	fi

	genAbacus $numDigits $offset "$1"
fi
