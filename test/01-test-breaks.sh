#!/bin/sh
. $(dirname "$0")/init.sh


# There's a single linebreak between line1 and line2, which should collapse to a space.
# There's a .br between line2 and line3, which should get converted to a linebreak.
# There's a .P  between line3 and line4, which should get converted to a paragraph.
output="$(conv_sample1 | get_section 'BREAKS')"

assertRegex "$output" '/line 1( |\n)line 2/' \
	"Contiguous lines did not get converted correctly!"
assertRegex "$output" '/line 2  \nline 3/' \
	"Lines separated by .br did not get converted correctly!"
assertRegex "$output" '/line 3\n\nline 4/' \
	"Lines separated by .P did not get converted correctly!"


success
