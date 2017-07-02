#!/bin/sh
. $(dirname "$0")/init.sh


output="$(conv_sample1 | get_section 'HIGHLIGHTING')"
output=" $output "  # extra spaces for liberal \s checks instead of (?:\s|$)

# regex components:
B='\*\*'
I='\*'
SP='(?: |&nbsp;|\s)'
KEEP_B="(?:${SP}+|${B}${SP}+${B})"  # space between two .B areas, we don't care if the space itself it bold as well
KEEP_I="(?:${SP}+|${I}${SP}+${I})"  # space between two .I areas, we don't care if the space itself is italic as well
BIS="(?:${SP}+${B}${SP}*${I}${SP}*|${SP}*${B}${SP}+${I}${SP}*|${SP}*${B}${SP}*${I}${SP}+)"  # change from bold to italics, with at least one space
IBS="(?:${SP}+${I}${SP}*${B}${SP}*|${SP}*${I}${SP}+${B}${SP}*|${SP}*${I}${SP}*${B}${SP}+)"  # change from italics to bold, with at least one space


# 0 \fBinline bold\fR 0 \fIinline italics\fR 0
assertRegex "$output" "/0\\s+${B}inline bold${B}\\s+0\\s+${I}inline italics${I}\\s+0/" \
	"Inline highlighting (\\fX) did not work as expected!"

# 1
# .B "bold"
# 1
# .I italics "iii1" iii2
# 1
assertRegex "$output" "/1\\s+${B}bold${B}\\s+1\\s+${I}italics${KEEP_I}iii1${KEEP_I}iii2${I}\\s+1/" \
	"Explicit highlighting with .B and .I did not work as expected!"

# .BR bold    " 2 "    "bold"    " 2"
# .RB "3 " "bold" \ 3\  bold " 3"
# .BR aaa\ bbb\ ccc " normal " bold"quoted \  spaced"bold " normal2"
# .BI "bold-4 " "italics-4 " bold4 " italics4"
assertRegex "$output" "/\\s${B}bold${B}\\s+2\\s+${B}bold${B}\\s+2/" \
	"Alternating highlighting (.BR) did not work as expected!"
assertRegex "$output" "/3\\s+${B}bold${B}${SP}+3${SP}+${B}bold${B}\\s+3/" \
	"Alternating highlighting (.RB, with escaped spaces in bare tokens) did not work as expected!"
assertRegex "$output" "/\\s${B}aaa${SP}+bbb${SP}+ccc${B}\\s+normal\\s+${B}bold\"quoted${KEEP_B}spaced\"bold${B}\\s+normal2\\s/" \
	"Alternating highlighting (.BR, with escaped-space-only bare tokens) did not work as expected!"
assertRegex "$output" "\\s${B}bold-4${BIS}italics-4${IBS}bold4${BIS}italics4${I}\\s/" \
	"Alternating highlighting (.BI) did not work as expected!"


success