#!/bin/sh
. $(dirname "$0")/init.sh


assertAnchor () {
	local input="$1"
	local expectedAnchorName="$2"
	assertContains "$input" "<a name=\"$expectedAnchorName\"></a>" \
		"Input does not contain expected anchor!"
}


output="$(conv_sample1)"

assertAnchor "$output" 'description'  # .SH DESCRIPTION
assertAnchor "$output" 'options'  # .SH "OPTIONS"
assertAnchor "$output" 'special-characters'  # .SH SPECIAL CHARACTERS
assertAnchor "$output" 'texty-subsection'  # .SH "Texty Subsection"
assertAnchor "$output" 'another-subsection'  # .SH Another    Subsection
assertAnchor "$output" 'section-with-dashed-words-on-and-off'  # .SH SECTION WITH DASHED-WORDS -- ON AND OFF.


output="$(conv unicode2.roff)"

assertAnchor "$output" 'únicòde-in-hëadlíneş'  # .SH ÚNICÒDE IN HËADLÍNEŞ
assertAnchor "$output" 'subsèction-ẅith-uñicøde'  # .SS Subsèction ẅith Uñicøde


success
