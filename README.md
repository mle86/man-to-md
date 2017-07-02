# Known nroff sequences:

* `.TH`  
	First line with name, man section, version, and date.

* `.B`, `.I`, `.R`  
	Sets the rest of the line in bold/italics/normal.
	(Line will be tokenized.)

* `.BI`, `.IB`, `.RB`, `.BR`, `.RI`, `.IR`  
	Sets the rest of the line in bold/italics/normal,
	alternating with each token/word.
	(Line will be tokenized.)

* `\fB`, `\fI`, `\fR`  
	Changes output mode to bold/italics/normal.
	(In-text.)

* `.SH`  
	Section title.

* `.SS`  
	Subsection title.

* `.IP`  
	One list item.
	Begin of a list.

* `.TP`  
	One definition list entry.
	Begin of a list.

* `.RS`  
	Begin of a nested list.
	Increases list indentation level.

* `.RE`  
	End of a nested list.
	Decreases list indentation level.

* `.LP`/`.P`/`.PP`  
	One blank line.
	Also end of a list.

* `.nf`  
	A block of unformatted text.

* `.fi`  
	End of an unformatted block.

* `.de`  
	Macro definition (ignored).

* `\"`, `.\"`  
    Line comment (ignored).

* `\ `  
    Non-breaking space.

