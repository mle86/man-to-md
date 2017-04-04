#!/bin/sh
. $(dirname "$0")/init.sh


comment="This is my comment 0987654321"

getcommentline () { head -n 1 ; }


assertContains "$(conv_sample1 --comment="$comment" | getcommentline)" "$comment" \
	"The first line does not contain the --comment!"


assertContains "$(conv_sample1 --comment | getcommentline)" "$DEFAULT_COMMENT" \
	"The first line does not contain the default comment!"


case "$(conv_sample1 | getcommentline)" in
	*"generated"*)
		fail "The first line contains the default comment, even when called without --comment!"
		;;
esac


success
