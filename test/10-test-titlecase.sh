#!/bin/sh
. $(dirname "$0")/init.sh


words="-w XML --word cRaZyCaPs --word ENV_VAR"
sample1_headlines="$(conv_sample1_headlines $words)"

assertContains \
	"$sample1_headlines" \
	"A Simple Approach to Title-Casing of Known Words Like XML and cRaZyCaPs" \
	"The program did not correctly title-case the section headlines!"

assertContains \
	"$sample1_headlines" \
	"The ENV_VAR Variable" \
	"The program did not correctly title-case the section headlines!"

assertContains \
	"$sample1_headlines" \
	"Section with W31rd Numb3rs"

assertContains \
	"$(conv unicode2.roff | grep '^#')" \
	"Únicòde in Hëadlíneş"


success
