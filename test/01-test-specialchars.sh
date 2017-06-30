#!/bin/sh
. $(dirname "$0")/init.sh


assertContains "$(conv_sample1 | get_section 'OPTIONS')" "--verbose" \
	"Conversion of \"\\-\" to plain \"-\" failed!"


output="$(conv_sample1 | get_section 'SPECIAL CHARACTERS')"
errmsg="Conversion of special character sequence failed!"

assertContains "$output" "lq<“>"  "$errmsg"
assertContains "$output" "rq<”>"  "$errmsg"
assertContains "$output" "dq<\">" "$errmsg"


# There's a single linebreak between line1 and line2, which should collapse to a space.
# There's a .br between line2 and line3, which should get converted to a paragraph.
# There's a .P  between line3 and line4, which should get converted to a paragraph.
output="$(conv_sample1 | get_section 'BREAKS')"

test_pcre "$output" 'line 1( |\n)line 2' \
	"Contiguous lines did not get converted correctly!"
test_pcre "$output" 'line 2\n\nline 3' \
	"Lines separated by .br did not get converted correctly!"
test_pcre "$output" 'line 3\n\nline 4' \
	"Lines separated by .P did not get converted correctly!"


success
