#!/bin/sh
. $(dirname "$0")/init.sh


output="$(conv_sample1 --paste-before DESCRIPTION:test/samples/PasteTest.md)"

assertRegex "$output" "/^# PasteTest\\n+PASTED-SECTION-1093878\\n+# Description/m"


success
