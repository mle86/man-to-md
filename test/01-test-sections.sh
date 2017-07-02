#!/bin/sh
. $(dirname "$0")/init.sh

output="$(conv_sample1)"


match_section_title () {
	local input="$1"
	local sectionlevel="$2"
	local sectiontitle="$3"
	local regex=

	# We don't test for Titlecase here, there's a specialized test just for that:
	regex="$regex""(?i)"
	# Section and Subsection titles should be preceded by at least one blank line:
	regex="$regex""\n\n+"
	# Start with no more than three spaces (lest they be considered a code block):
	regex="$regex"" {0,3}"
	# One hash# per section level, without spaces:
	regex="$regex""#{${sectionlevel}}"
	# Have at least one space between the hashes and the section title,
	regex="$regex"" +${sectiontitle}"
	# End with no more than one space:
	regex="$regex"" ?"
	# Should be followed by at least one blank line:
	regex="$regex""\n\n+"
	# In our test input, there are no empty sections
	# and all tested section start with some text:
	regex="$regex""\w"

	assertRegex "$input" "/$regex/"
}


match_section_title "$output" 1 "Description"		# .SH section
match_section_title "$output" 1 "Options"		# .SH section
match_section_title "$output" 2 "Texty Subsection"	# .SS subsection


success
