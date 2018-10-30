#!/bin/sh
. $(dirname "$0")/init.sh


LT='&lt;'  # plain "<" is NOT acceptable!
GT='&gt;'
# fake program name is "a<b>"
PROG="a${LT}b${GT}"
PLAINPROG="a<b>"


tests () {
	local output="$1"
	local mode="$2"

	local headline="$(printf '%s' "$output" | grep -m1 '^#')"
	assertRegex "$headline" "/$PROG/i" \
		"HTML conversion in headline did not work as expected! ($mode)"
	assertRegex "$headline" '!/</' \
		"Headline still contains some HTML tag! ($mode)"

	local sectiontitle="$(printf '%s' "$output" | grep -im1 '^# main')"
	assertRegex "$sectiontitle" "/$PROG/i" \
		"HTML conversion in section titles did not work as expected! ($mode)"

	assertRegex "$output" "/the mysterious (?:“|\")$PROG(?:”|\") program/i" \
		"HTML conversion in text body did not work as expected! ($mode)"

	assertRegex "$output" "/bold line about $PROG/i" \
		"HTML conversion in .B line did not work as expected! ($mode)"

	assertRegex "$output" "!/<pre>.*?$PLAINPROG.*?<\/pre>/is" \
		"HTML conversion in <pre> code block did not work as expected! ($mode)"

	assertRegex "$output" "!/\`\`\`.*?$PROG.*?\`\`\`/is" \
		"HTML conversion was too eager: converted tags inside a \`\`\` code block! ($mode)"

	assertRegex "$output" "!/^ {4,}.*?$PROG/im" \
		"HTML conversion was too eager: converted tags inside a four-space-indented code block! ($mode)"
}


tests "$(conv html.roff   )" 'without -f option'
tests "$(conv html.roff -f)" 'WITH -f option'


success
