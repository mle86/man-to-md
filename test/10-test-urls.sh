#!/bin/sh
. $(dirname "$0")/init.sh

output="$(conv urls.roff )"
macroOutput="$(printf '%s' "$output" | get_section 'GROFF MACROS')"


# The URL conversion feature should pick up on lines that contain only an URL in parentheses
# and convert the entire preceding line into the visible link text.
title='well-formatted URLs'
url='https:\/\/en.wikipedia.org\/wiki\/URL'
assertRegex "$output" '/after a while,\s+\['"$title"'\]\('"$url"'\)\s+show up/' \
	"URL line conversion fails!"

	# But after a while,
	# well-formatted URLs
	# (https://en.wikipedia.org/wiki/URL)
	# show up!


# The same should work with punctuation
# immediately following the URL's closing parenthesis.
title='sentence'
url='https:\/\/en.wiktionary.org\/wiki\/sentence'
assertRegex "$output" '/end a\s\['"$title"'\]\('"$url"'\)\.\s/' \
	"URL line conversion with following punctuation fails!"

	# They may also end a
	# sentence
	# (https://en.wiktionary.org/wiki/sentence).


# Plain URLs in the text (NOT in parentheses)
# should either be left as-is
# or be converted to an explicit [url](url) link.
url='https:\/\/en.wikipedia.org\/wiki\/URL'
assertRegex "$output" '/in the output:\s+(?:'"$url"'|\['"$url"'\]\('"$url"'\))\s+\(plain url\)\s/' \
	"Plain URL was not converted correctly!"

	# This URL is not in parentheses,
	# so it should not be its own link title
	# in the output:
	# https://en.wikipedia.org/wiki/URL
	# (plain url)


addr='author@dummy.test' ; maillink="\\[${addr}\\]\\(mailto:${addr}\\)"
assertRegex "$output" '/link:\s+'"$maillink"'\s/' \
	"E-mail address was not converted correctly!"

	# At least in this section, e-mail addresses
	# should automatically get converted to a link:
	# author@dummy.test


LT='(?:<|&lt;)'
GT='(?:>|&gt;)'

addr='author2@dummy.test' ; maillink="\\[${addr}\\]\\(mailto:${addr}\\)"
assertRegex "$output" '/inside angle brackets:\s+'"$LT$maillink$GT"'\s/' \
	"E-mail address inside angle brackets was not converted correctly!"

	# This should also work inside angle brackets:
	# <author2@dummy.test>
	# Fin!


intlnk='doc\/More_Information\.md'
assertRegex "$output" "/For more information, see\\s+\\[$intlnk\\]\\($intlnk\\)\\./msi" \
	"Internal link was not converted correctly!"
assertRegex "$output" "/with a different\\s+\\[link title\\]\\($intlnk\\)!/msi" \
	"Internal link with custom title was not converted correctly!"
assertRegex "$output" "/followed by an angle bracket:\\s+\\[$intlnk\\]\\($intlnk\\)\\s+&lt;other stuff/" \
	"Internal link (without custom title, but followed by an angle bracket) was not converted correctly!"


# .UM/.UE groff macros:
umUrl='https:\/\/test\.123456\/foo-bar\/09124'
umText='embedded\s+link'
assertRegex "$macroOutput" "/have an\\s+\\[$umText\\]\\($umUrl\\)\\.\\s+EOL1/ms" \
	".UM/.UE url macros have not been converted correctly!"


success
