#!/bin/sh
. $(dirname "$0")/init.sh


words="-w XML --word cRaZyCaPs"

assertContains \
	"$(conv_sample1_headlines $words)" \
	"A Simple Approach to Title-Casing of Known Words Like XML and cRaZyCaPs" \
	"The program did not correctly title-case the section headlines!"


success
