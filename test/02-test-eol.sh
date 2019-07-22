#!/bin/sh
. $(dirname "$0")/init.sh


output="$(conv eol.roff)"


assertRegex "$output" '/^This is a continued line\.$/m' \
	"Line continuation with \\<RET> did not work as expected!"

assertRegex "$output" '/^Weirdly enough,\s+this line actually\s+\\\\contains a literal backslash\.$/m' \
	"Line continuation with \\<RET> did not work as expected when also ending with literal backslash escapes!"


success
