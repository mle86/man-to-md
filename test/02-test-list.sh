#!/bin/sh
. $(dirname "$0")/init.sh


match_option () {
	local output="$1"
	local option="$2"
	local description="$3"

	local regex='\n\* .*?'"$option"'(?:.*\S)*?  \n'
	regex="$regex"' {1,3}(?:\S.*?)?'"$description"'.*?\S\n'

	if ! printf '%s' "$output" | grep -qzP "$regex"; then
		err ".TP option list got converted incorrectly! (Was checking \".TP --$option\" output)"
		err "  Regex:"
		err "$regex"
		err "  Output:"
		fail "$output"
	fi
	true
}

match_suboption () {
	local output="$1"
	local suboption="$2"
	local description="$3"

	local regex='\n {4,6}\* .*?'"$suboption"'(?:.*\S)*?\n'
	regex="$regex"' {5,7}(?:\S.*?)?'"$description"'.*?\S\n'

	if ! printf '%s' "$output" | grep -qzP "$regex"; then
		err ".IP sub list got converted incorrectly! (Was checking \"$suboption\" suboption)"
		err "  Regex:"
		err "$regex"
		err "  Output:"
		fail "$output"
	fi
	true
}


output="$(conv_sample1 | get_section 'OPTIONS')"

assertRegex "$output" '/program options[\.:]\n{2,}\* .*?--\w/' \
	"There was no blank line inserted between text line and .TP list!"

# First-level list items (.TP/.IP) should not be indented themselves,
# marked with a single asterisk,
# and their continuation lines should be indented with at least one space.
# .TP item names should have a line break after them (line ending with two spaces).
match_option "$output" "verbose" "Show more"
match_option "$output" "quiet"   "No output"
match_option "$output" "mode"    "operating mode"

# Second-level list items (.TP/.IP after .RS) should be indented with at least four spaces,
# marked with a single asterisk,
# and their continuation lines should be indented with at least one extra space.
match_suboption "$output" "M0" "Level zero"
match_suboption "$output" "M1" "Level one"
match_suboption "$output" "M2" "Level two"

# After a paragraph (.P/.LP/.PP), the list ends.
# This means the following text should have regular indentation
# and a leading blank line.
assertRegex "$output" '/\n\n {0,2}(?:\w[\w ]*)?section end/'


success
