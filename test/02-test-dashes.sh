#!/bin/sh
. $(dirname "$0")/init.sh

output_default="$(conv dashes.roff)"
output_escaped="$(conv dashes.roff --escaped-dashes)"

	# Escaped: A\-B.
	# .P
	# Plain: C-D.
	# .P
	# Escaped double: E\-\-F.
	# .P
	# Plain double: G--H.
	# .P

assertRegex "$output_default" "/A-B/" \
	"Escaped dashes in input were not handled correctly without --escaped-dashes option!"
assertRegex "$output_default" "/C-D/" \
	"Plain dashes in input were not handled correctly without --escaped-dashes option!"
assertRegex "$output_default" "/E--F/" \
	"Escaped double dashes in input were not handled correctly without --escaped-dashes option!"
assertRegex "$output_default" "/G--H/" \
	"Plain double dashes in input were not handled correctly without --escaped-dashes option!"

assertRegex "$output_escaped" "/A\\\\-B/" \
	"Escaped dashes in input were not handled correctly WITH --escaped-dashes option!"
assertRegex "$output_escaped" "/C-D/" \
	"Plain dashes in input were not handled correctly WITH --escaped-dashes option!"
assertRegex "$output_escaped" "/E\\\\-\\\\-F/" \
	"Escaped double dashes in input were not handled correctly WITH --escaped-dashes option!"
assertRegex "$output_escaped" "/G--H/" \
	"Plain double dashes in input were not handled correctly WITH --escaped-dashes option!"


success
