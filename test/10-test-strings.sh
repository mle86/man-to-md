#!/bin/sh
. $(dirname "$0")/init.sh


output="$(conv strings.roff | get_section 'OUTPUT')"

# regex components:
B='\*\*'
I='_'
# .ds Y (SINGLE-Y)
# .ds  YY  \fB(DOUBLE-Y)\fR
# .ds  YM  (\fIMULTI-\
# LINED\fR)
Y_USAGE="\\(SINGLE-Y\\)"
YY_USAGE="${B}\\(DOUBLE-Y\\)${B}"
YM_USAGE="\\(${I}MULTI-LINED${I}\\)"


# aaaa\*Ybbbb\*(YYcccc
# Used _before_ any .ds commands, so the strings should be empty.
assertRegex "$output" "/\\baaaabbbbcccc\\b/" \
	"Unknown strings (not yet defined with .ds) did not get replaced with empty string!"

# dddd\*Yeeee\*(YYffff
# Used correctly after .ds string definitions.
assertRegex "$output" "/\\bdddd${Y_USAGE}eeee\\b/" \
	"Single-letter string \\*Y was not replaced correctly!"
assertRegex "$output" "/\\beeee${YY_USAGE}ffff\\b/" \
	"Two-letter string \\*(YY was not replaced correctly!"

# gggg\*(YMhhhh
# Used correctly after .ds string definition, although that .ds definition contains a line continuation.
assertRegex "$output" "/\\bgggg${YM_USAGE}hhhh\\b/" \
	"Two-letter string \\*(YM was replaced, but its multi-line .ds defintion was not read correctly!"


success
