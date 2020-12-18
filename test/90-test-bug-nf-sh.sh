#!/bin/sh
. $(dirname "$0")/init.sh

# .nf code blocks may be ended with a new section title (.SH).

output="$(conv code.roff)"

expectedFragment=
expectedFragment="${expectedFragment}^# Unterminated\b.*"
expectedFragment="${expectedFragment}^    +my\b.*"
expectedFragment="${expectedFragment}^    +code\b.*"
expectedFragment="${expectedFragment}^# Terminator*"

assertRegex "$output" "/$expectedFragment/ms"


success
