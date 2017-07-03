#!/bin/sh
. $(dirname "$0")/init.sh


output="$(conv comments.roff)"


assertRegex "$output" '!/SENTINEL1/i' \
	'Line comment (\") was not ignored!'

assertContains "$output" 'contains a line comment' \
	'Line comment (\") removed too much!'

assertRegex "$output" '!/SENTINEL2/i' \
	'Line comment command (.\") was not ignored!'

assertRegex "$output" '!/SENTINEL3/i' \
	'Block comment (.ig-..) was not ignored!'

assertRegex "$output" '!/SENTINEL4/i' \
	'Line comment command after escaped backslash (\\\") was not ignored!'

assertContains "$output" 'a block comment' \
	'Block comment (.ig-..) removed its surrounding paragraph!'

assertContains "$output" 'MARKER4' \
	'Escaped line comment (\\") was treated like a real line comment!'

assertContains "$output" 'MARKER5' \
	'Escaped line comment (with extra escaped backslash) (\\\\") was treated like a real line comment!'


success
