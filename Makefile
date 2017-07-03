#!/usr/bin/make -f

.PHONY : all test clean

CONV=man-to-md.pl


all: ;

README.md: doc/man-to-md.1 $(CONV)
	perl $(CONV) --comment <$< >$@

test:
	git submodule update --init test/framework/
	test/run-all-tests.sh

clean: ;

