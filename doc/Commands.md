# Known nroff Macros:

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
	One description list entry.
	Begin of a list.

* `.RS`–`.RE`  
    Increased list indentation level.
    Can be used for sub-lists.

* `.LP`/`.P`/`.PP`  
	One blank line.
	Also end of a list.

* `.nf`–`.fi`  
	A block of unformatted text.

* `.de`–`..`  
	Macro definition (ignored).

* <code>.UM <i>url</i></code>–`.UE`
    URL link.

* <code>.MT <i>address</i></code>–`.ME`
    E-mail link.

* `.ig`–`..`  
    Block comment (ignored).


# Known nroff Escape Sequences:

* `\"`/`.\"`  Line comment (ignored).
* <code>\\&nbsp;</code>  Non-breaking space.
* `\&`  Non-printing zero-width character (ignored).
* `\:`  Non-printing breaking zero-width space (output: U+200B).
* `\(lq` “
* `\(rq` ”
* `\(oq` ‘
* `\(cq` ’
* `\(dq` "
* `\(aq` '
* `\(Fo` «
* `\(Fc` »
* `\(fo` ‹
* `\(fc` ›
* `\(hy` -
* `\(en` –
* `\(em` —

