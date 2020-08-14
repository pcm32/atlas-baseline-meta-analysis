# The condensed SDRF that only contains the desired samples
CONDENSED=$1
COUNTS_FILE=$2
DESTINATION_COUNTS=$3


first_col=$(head -n 1 $COUNTS_FILE | awk -F'\t' '{ print $1 }')
cols=$first_col","$(awk -F'\t' '{ print $3 }' $CONDENSED | sort -u | tr '\n' ',' | sed s/,$//)

echo "Getting cols: $cols"

set +e
csvcut -t -c "$cols" $COUNTS_FILE | csvformat -T > $DESTINATION_COUNTS
