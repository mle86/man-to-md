#!/bin/sh
. $(dirname "$0")/init.sh


# .nf code block output should be indented with 4 spaces
# and all highlighting escapes should be removed:
define expectedOutput <<EOT
This text comes before the code block.

    this is the code block
    empty line:
    
       indented x3
    
    0 bold 0 italics 0

This text comes after the code block.
EOT

assertEq "$(conv code.roff | get_section 'NFBLOCK')" "$expectedOutput" \
	"The .nf code block was not converted correctly!"


success
