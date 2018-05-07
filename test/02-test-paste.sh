#!/bin/sh
. $(dirname "$0")/init.sh


re_pasted_section="# PasteTest\\n+PASTED-SECTION-1093878\\n+"


output="$(conv_sample1 --paste-before DESCRIPTION:test/samples/PasteTest.md)"
assertRegex "$output" "/^${re_pasted_section}# Description/m"

output="$(conv_sample1 --paste-after HEADLINE:test/samples/PasteTest.md)"
assertRegex "$output" "/^# testprog.+\\n+${re_pasted_section}^Version 0.9.2/m"


success
