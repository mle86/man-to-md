#!/bin/sh
. $(dirname "$0")/init.sh

output="$(conv short-highlight.roff)"


SP='(?:&nbsp;| | )'
B1='(?:\*\*|<b>)'
B0='(?:\*\*|<\\/b>)'
I1='(?:_|<i>)'
I0='(?:_|<\/i>)'

assertRegex "$output" "/${B1}CSI${SP}38;5;${B0}${I1}n${I0}${SP}${B1}m${B0}/"

	## including the “**CSI&nbsp;38;5;**_n_&nbsp;**m**” sequence
	## for extended color selection

assertRegex "$output" "/${B1}CSI${SP}38;2;${B0}${I1}r${I0}${B1};${B0}${I1}g${I0}${B1};${B0}${I1}b${I0}${SP}${B1}m${B0}/"

	## and the “**CSI&nbsp;38;2;**_r_**;**_g_**;**_b_&nbsp;**m**” sequence
	## for RGB true-color selection.


success
