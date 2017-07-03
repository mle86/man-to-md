#!/bin/sh
. $(dirname "$0")/init.sh

output="$(conv code.roff)"


# Without the -f option, the output should be indented with 4 spaces
# and all highlighting escapes should be removed:
define expectedOutput <<EOT
This text comes before the code block.

    this is the code block
    empty line:
    
       indented x3
    
    0 bold 0 italics 0

This text comes after the code block.
EOT

assertEq "$(printf '%s' "$output" | get_section 'NFBLOCK')" "$expectedOutput" \
	"The .nf code block was not converted correctly!"


# With the -f option, we cannot use four spaces for the code block,
# because that mode does not support inline html.
# The program should use a <pre><code> block instead:
define expectedOutput <<EOT
This text comes before the code block.

<pre><code>this is the code block
empty line:

   indented x3

0 <b>bold</b> 0 <i>italics</i> 0
</code></pre>

This text comes after the code block.
EOT

assertEq "$(conv code.roff -f | get_section 'NFBLOCK')" "$expectedOutput" \
	"With the -f option, the .nf code block was not converted correctly!"


cm_output="$(printf '%s' "$output" | get_section 'CMBLOCK')"

assertRegex "$cm_output" "/(?:\`mycommand < myinput|<code>(?:<pre>)?mycommand &lt; myinput)/" \
	".cm command line not found! (Or HTML entity conversion problem)"
assertContains "$cm_output" "cm-output1" \
	".cm command output not found!"
assertContains "$cm_output" "cm-output2" \
	".cm command output only partially copied!"

success
