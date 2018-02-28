#!/bin/sh
. $(dirname "$0")/init.sh


output="$(conv indent.roff | get_section 'INDENTATION')"

: '
ENV_0
: This is indented.
  Indented continuation line.

: Still indented.

Regular.
'

assertRegex "$output" '/^ENV_0/' \
	"Regular text got accidentally indented."
assertRegex "$output" '/\n\nRegular/ms' \
	"Regular text got accidentally indented."

assertRegex "$output" '/^: {1,3}This is indented/m' \
	"Indentation directly after regular text did not work."
assertRegex "$output" '/^ {0,3}Indented continuation line/m' \
	"Indentation continuation line did not work."
assertRegex "$output" '/^: {1,3}Still indented/m' \
	"Indentation did not persist through paragraph."

success
