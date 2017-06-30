#!/bin/sh
. $(dirname "$0")/init.sh


check_n_lines=8

get_synopsis () { head -n $check_n_lines | grep -m1 -zoP '(?:(?<=\n<pre><code>).+(?=</code></pre>)|(?<=\n```\n).+)'; }


assertContains "$(conv_sample1 | get_synopsis)" "testprog [OPTIONS] [--] [FILENAME...]" \
	"The synopsis does not contain the correct command call!"

assertContains "$(conv_sample1 -f | get_synopsis)" "<b>testprog</b> [<i>OPTIONS</i>] [<b>--</b>] [<i>FILENAME</i>...]" \
	"The synopsis does not contain the correct command call!"

success
