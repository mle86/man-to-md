#!/bin/sh
. $(dirname "$0")/init.sh

output="$(conv section-links.roff)"

s="\\s+"


assertRegex "$output" "/below:${s}“\\[More Details \\((?:\\.{3}|…)\\)\\]\\(#more-details-including-numb3rs-and-special-cháractèrß\\)”\\./"

	# .SH DESCRIPTION
	# Check out the section below:
	# .\" LINK-TO MORE DETAILS, INCLUDING NUMB3RS AND SPECIAL CHÁRACTÈRß
	# \(lqMore Details (…)\(rq.

assertRegex "$output" "/to the${s}“\\[Description\\]\\(#description\\)”${s}section/"

	# .SH MORE DETAILS, INCLUDING NUMB3RS AND SPECIAL CHÁRACTÈRß
	# Head back to the
	# .\" LINK-TO DESCRIPTION
	# \(lqDescription\(rq
	# section


success
