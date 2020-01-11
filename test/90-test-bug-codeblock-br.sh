#!/bin/sh
. $(dirname "$0")/init.sh

output="$(conv formatted-code.roff)"

	# .nf
	# This is the code block.
	# .BR Alternating " highlights" "!"
	# Regular text.
	# .B This line is bold
	# .fi


re1="This is the code block"
re2="Alternating highlights!"
re3="Regular text"
re4="This line is bold"
assertRegex "$output" "/^    ${re1}.*^    ${re2}.*^    ${re3}.*^    ${re4}.*/ms"


success
