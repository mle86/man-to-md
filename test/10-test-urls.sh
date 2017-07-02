#!/bin/sh
. $(dirname "$0")/init.sh


output="$(conv urls.roff | paste -sd' ')"
output="$(conv urls.roff )"
	# We don't care about linebreaks/paragraphs in the output
	# that are functionally equivalent to spaces.
	# So we convert all linebreaks to spaces first --
	# makes our search patterns simpler.


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

addr='author2@dummy.test' ; maillink="\\[${addr}\\]\\(mailto:${addr}\\)"
assertRegex "$output" '/inside angle brackets:\s+<'"$maillink"'>\s/' \
	"E-mail address inside angle brackets was not converted correctly!"

	# This should also work inside angle brackets:
	# <author2@dummy.test>
	# Fin!

success
