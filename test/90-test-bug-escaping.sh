#!/bin/sh
. $(dirname "$0")/init.sh


backslash="\\"

# input:
	# Backslashes in the input will be replaced with a literal \fB\\\\\fR,
	# while linebreaks in the input will be replaced with a literal \fB\\n\fR.
define expectedOutput <<-EOT
	Backslashes in the input will be replaced with a literal **${backslash}${backslash}${backslash}${backslash}**,
	while linebreaks in the input will be replaced with a literal **${backslash}${backslash}n**.
EOT


output="$(conv escaping.roff | get_section 'BACKSLASHES AND ASTERISKS')"
assertEq "$output" "$expectedOutput"

success
