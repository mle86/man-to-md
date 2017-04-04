#!/bin/sh
. $(dirname "$0")/init.sh


check_n_lines=8
output="$(conv_sample1 | head -n $check_n_lines)"
headline="$(printf '%s' "$output" | grep '^#' | head -n 1)"


assertContains "$headline" "$TESTPROG_NAME($TESTPROG_SECTION)" \
	"The first headline does not contain the correct program name and man section!"

assertRegex "$output" "/Version v?$TESTPROG_VERSION/i" \
	"The first few lines do not contain the program version!"

assertContains "$output" "$TESTPROG_DATE" \
	"The first few lines do not contain the program date!"

success
