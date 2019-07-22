#!/bin/sh
. $(dirname "$0")/init.sh


assertContains "$(conv_sample1 | get_section 'OPTIONS')" "--verbose" \
	'Conversion of "\-" to plain "-" failed!'


output="$(conv_sample1 | get_section 'SPECIAL CHARACTERS')"
errmsg="Conversion of special character sequence failed!"

LT='(?:<|&lt;)'
GT='(?:>|&gt;)'

assertRegex "$output" "/lq${LT}“${GT}/"  "$errmsg"
assertRegex "$output" "/rq${LT}”${GT}/"  "$errmsg"
assertRegex "$output" "/dq${LT}\"${GT}/" "$errmsg"

assertRegex "$output" "/nbsp(?: |&nbsp;)eol/" \
	'Conversion of "\ " to NBSP failed!'
assertRegex "$output" "/nbsp2(?: |&nbsp;)eol2/" \
	'NBSP at line-end did not cause the linebreak to get removed!'
assertRegex "$output" "/nbsp3(?: |&nbsp;)eol/" \
	'Conversion of "\~" to NBSP failed!'

assertRegex "$output" "/zwsp(?:​|&#x200b;|&#8203;)eol/" \
	'Conversion of "\:" to ZWSP failed!'


success
