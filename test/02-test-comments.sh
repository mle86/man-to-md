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

assertContains "$output" 'a block comment' \
	'Block comment (.ig-..) removed its surrounding paragraph!'


success
