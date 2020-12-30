#!/bin/sh
. $(dirname "$0")/init.sh


assertContains "$(conv_sample1 | get_section 'OPTIONS')" "--verbose" \
	'Conversion of "\-" to plain "-" failed!'


output="$(conv_sample1 | get_section 'SPECIAL CHARACTERS')"
errmsg="Conversion of special character sequence failed!"

LT='(?:<|&lt;)'
GT='(?:>|&gt;)'

assertRegex "$output" "/lq${LT}“${GT}${LT}“${GT}/"  "$errmsg"
assertRegex "$output" "/rq${LT}”${GT}/"  "$errmsg"
assertRegex "$output" "/dq${LT}\"${GT}/" "$errmsg"
assertRegex "$output" "/Eu${LT}€${GT}/" "$errmsg"
assertRegex "$output" "/34${LT}¾${GT}/" "$errmsg"
assertRegex "$output" "/co${LT}©${GT}/" "$errmsg"

assertRegex "$output" "/nbsp(?: |&nbsp;)eol/" \
	'Conversion of "\ " to NBSP failed!'
assertRegex "$output" "/nbsp2(?: |&nbsp;)eol2/" \
	'NBSP at line-end did not cause the linebreak to get removed!'
assertRegex "$output" "/nbsp3(?: |&nbsp;)eol/" \
	'Conversion of "\~" to NBSP failed!'

assertRegex "$output" "/zwsp(?:​|&#x200b;|&#8203;)eol/" \
	'Conversion of "\:" to ZWSP failed!'

assertRegex "$output" "/bold-asterisk:\\s+<b>\\\\\\*<\\/b>\\./" \
	"Conversion of bold asterisk (\\fB*\\fR) failed!"
assertRegex "$output" "/italic-asterisk:\\s+<i>\\\\\\*<\\/i>\\./" \
	"Conversion of italic asterisk (\\fI*\\fR) failed!"
assertRegex "$output" "/bold-underscore:\\s+(?:<b>\\\\_<\\/b>|\\*\\*\\\\_\\*\\*)\\./" \
	"Conversion of bold underscore (\\fB_\\fR) failed!"
assertRegex "$output" "/italic-underscore:\\s+(?:<i>\\\\_<\\/i>|_\\\\__)\\./" \
	"Conversion of italic underscore (\\fI_\\fR) failed!"

assertRegex "$output" "/unicode-dot:\\s+(?:&#9679;|&#x25cf;|●)\\./" \
	"Conversion of Unicode codepoints failed!"

# complicated-varname: VAR_\fIAA\fR_\fIBB\fR.
assertRegex "$output" "/complicated-varname:\\s+(?:VAR_\\*AA\\*_\\*BB\\*|VAR_<i>AA<\/i>_<i>BB<\/i>|VAR\\\\__AA_\\\\__BB_)/"


success
