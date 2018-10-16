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


assertRegex "$(conv pkg.roff | head -n $check_n_lines)" "/xyz testing package v?$TESTPROG_VERSION, $TESTPROG_DATE/i" \
	"The package name (differing from the actual program name) was not included in the first few lines!"


output_nover="$(conv noversion.roff | head -n $check_n_lines)"
[ -z "$output_nover" ] && fail "Parsing noversion.roff failed!"

assertRegex "$output_nover" "!/Version v?$TESTPROG_VERSION/i" \
	"The first few lines contain a version string even when the input .TH line had no version!"


success
