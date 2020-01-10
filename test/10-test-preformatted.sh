#!/bin/sh
. $(dirname "$0")/init.sh

# We supports code blocks (.nf ... .fi)
# which have already been tested by test-codeblock.
# But we also support preformatted blocks (.\" PLAIN  .nf ... .fi).
# nroff of course renders them exactly the same,
# but the markdown output should not look like a code block --
# so no 4-space-indentation and no <code> either!

output="$(conv preformatted.roff)"
outputPreformatted="$(printf '%s\n' "$output" | get_section 'PREFORMATTED BLOCK')"
outputCodeblock="$(printf '%s\n' "$output" | get_section 'JUST A REGULAR CODE BLOCK')"

B='\*\*'
EOL="(?:  |<br\\/?>)\\n"


assertRegex "$outputPreformatted" "/^This is the preformatted${EOL}block\\.${EOL}(?:   )?indented x3${EOL}.*^This is ${B}regular${B} text again\\.\$/ms" \
	"Performatted block was not converted correctly!"

	# .\" PLAIN
	# .nf
	# This is the preformatted
	# block.
	#    indented x3
	# .fi
	# .P
	# This is \fBregular\fR text again.

assertRegex "$outputCodeblock" "/^    this is the code block.*^This is ${B}regular${B} text/ms" \
	"A regular codeblock was turned into a preformatted block instead!"


success
