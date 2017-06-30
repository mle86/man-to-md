#!/bin/sh
. $(dirname "$0")/init.sh


check_n_lines=8
output="$(conv_sample1 | head -n $check_n_lines)"
synopsis="$(printf '%s' "$output" | grep -A1 -m1 '^```' | tail -n1)"


assertContains "$synopsis" "testprog [OPTIONS] [--] [FILENAME...]" \
	"The synopsis does not contain the correct command call!"

success
