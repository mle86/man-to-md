#!/bin/sh
. $(dirname "$0")/init.sh

output="$(conv section-links.roff)"

s="\\s+"


assertRegex "$output" "/below:${s}“\\[More Details \\((?:\\.{3}|…)\\)\\]\\(#more-details-including-numb3rs-and-special-cháractèrß\\)”\\./"

	# .SH DESCRIPTION
	# Check out the section below:
	# .\" LINK-TO MORE DETAILS, INCLUDING NUMB3RS AND SPECIAL CHÁRACTÈRß
	# \(lqMore Details (…)\(rq.

assertRegex "$output" "/to the${s}\\[[\\*_]Description[\\*_] section\\]\\(#description\\)${s}/"

	# .SH MORE DETAILS, INCLUDING NUMB3RS AND SPECIAL CHÁRACTÈRß
	# Head back to the
	# .\" LINK-TO DESCRIPTION
	# \(lqDescription\(rq
	# section

trailingPunctuationOutput="$(printf '%s\n' "$output" | get_section 'TRAILING PUNCTUATION')"
assertRegex "$trailingPunctuationOutput" "/This is\\s+\\[a link\\]\\([^\\)]+\\)\\./" \
	"Section link with trailing dot was not converted correctly!"

	# .SH TRAILING PUNCTUATION
	# This is
	# .\" LINK-TO DESCRIPTION
	# a link.

indentedOutput="$(printf '%s\n' "$output" | get_section 'INDENTED SECTION')"
indentedBoundary="(?: +|$  +)"  # either just a space, or a linebreak followed by at least two spaces.
assertRegex "$indentedOutput" "/This is an(?: +|[\\r\\n]+  +)\\[indented link\\]\\([^\\)]+\\)\\./" \
	"Indented section link was not converted correctly!"

	# .SH INDENTED SECTION
	# .TP
	# .B Subject 1
	# This is an
	# .\" LINK-TO DESCRIPTION
	# indented link.
	# This is indented text.


success
