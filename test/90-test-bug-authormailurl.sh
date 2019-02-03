#!/bin/sh
. $(dirname "$0")/init.sh

output="$(conv author.roff | get_section 'AUTHOR')"

authorName='AuthorName'
authorMail='author@address.tld'
authorAddr='https://author.homepage/'

otherName='OtherAuthor'
otherMail=''
otherAddr='https://other-author.homepage/'

thirdName='ThirdAuthor'
thirdMail='third@author.tld'
thirdAddr=''



assertRegex "$output" '/\sAuthorName\s+(?:<|&lt;)\[author@address.tld\]\(mailto:author@address.tld\)(?:>|&gt;)\s+\(https:\/\/author.homepage\/\)\s/'

	# Author name with e-mail address AND url in next line.
	# The name-and-mail line should NOT be turned into a link.
	## A0
	## AuthorName <author@address.tld>
	## (https://author.homepage/)
	## A1

	# Expected:
	## A0
	## AuthorName &lt;[author@address.tld](mailto:author@address.tld&gt)&gt;
	## (https://author.homepage/)
	## A1

	# NOT expected:
	## A0
	## [AuthorName &lt;[author@address.tld](mailto:author@address.tld&gt)&gt;](https://author.homepage/)
	## A1

assertRegex "$output" '/\s\[OtherAuthor\]\(https:\/\/other-author.homepage\/\)\s/'

	## O0
	## OtherAuthor
	## (https://other-author.homepage/)
	## O1

assertRegex "$output" '/\sThirdAuthor\s+(?:<|&lt;)\[third@author.tld\]\(mailto:third@author.tld\)(?:>|&gt;)\s/'

	# Text block with a simple name followed by an e-mail addres
	# (which should be turned into a link).
	## T0
	## ThirdAuthor <third@author.tld>
	## T1

	# Expected Output:
	## T0
	## ThirdAuthor &lt;[third@author.tld](mailto:third@author.tld)&gt;
	## T1


success
