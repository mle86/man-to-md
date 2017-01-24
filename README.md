# Known nroff sequences:

* `.TH`  
	First line with name, man section, version, and date.

* `.B`, `.I`, `.R`  
	Sets the rest of the line in bold/italics/normal.

* `.BI`, `.IB`, `.RB`, `.BR`, `.RI`, `.IR`  
	Sets the rest of the line in bold/italics/normal,
	alternating with each word.

* `\fB`, `\fI`, `\fR`  
	Changes output mode to bold/italics/normal.
	(In-text.)

* `.SH`  
	Section title.

* `.SS`  
	Subsection title.

* `.IP`, `.TP  
	Begin of a list or definition list.

* `.RS`  
	Begin of a nested list.
	Increases list indentation level.

* `.RE`  
	End of a nested list.
	Decreases list indentation level.

* `.LP`  
	End of a list.

* `.P`/`.PP`  
	One blank line.

* `.nf`  
	A block of unformatted text.

* `.fi`  
	End of an unformatted block.

* `.de`  
	Macro definition (ignored).

