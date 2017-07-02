#!/bin/sh
. $(dirname "$0")/init.sh


assertContains "$(conv_sample1 | get_section 'OPTIONS')" "--verbose" \
	'Conversion of "\-" to plain "-" failed!'


output="$(conv_sample1 | get_section 'SPECIAL CHARACTERS')"
errmsg="Conversion of special character sequence failed!"

assertContains "$output" "lq<“>"  "$errmsg"
assertContains "$output" "rq<”>"  "$errmsg"
assertContains "$output" "dq<\">" "$errmsg"

assertRegex "$output" "/nbsp(?: |&nbsp;)eol/" \
	'Conversion of "\ " to NBSP failed!'


success
