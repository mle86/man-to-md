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

* `\fB`/`\f3`, `\fI`/`\f2`, `\f4`, `\fR`/`\fP`/`\f1`  
	Changes output mode to bold/italics/both/normal.
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

* <code>.ds <i>code</i> <i>replacement</i></code>  
	String definition.

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
* `\(ga` \`
* `\(aq` '
* `\(Fo` «
* `\(Fc` »
* `\(fo` ‹
* `\(fc` ›
* `\(hy` -
* `\(en` –
* `\(em` —
* `\(fm` ′
* `\(sd` ″
* `\(ha` ^
* `\(lh` ☜
* `\(rh` ☞

* `\(at` @
* `\(bu` ·
* `\(ci` ○
* `\(CR` ↵
* `\(de` °
* `\(dg` †
* `\(dd` ‡
* `\(lz` ◊
* `\(mc` µ
* `\(OK` ✓
* `\(ps` ¶
* `\(ru` _
* `\(sc` §
* `\(sh` #
* `\(sq` □
* `\(ti` ~

* `\(ct` ¢
* `\(Do` $
* `\(Eu` €
* `\(eu` €
* `\(Ye` ¥
* `\(Po` £
* `\(Cs` ¤

* `\(co` ©
* `\(rg` ®
* `\(tm` ™

* `\(ff` ﬀ
* `\(fi` ﬁ
* `\(Fi` ﬃ
* `\(fl` ﬂ
* `\(Fl` ﬄ
* `\(12` ½
* `\(14` ¼
* `\(34` ¾
* `\(38` ⅜
* `\(58` ⅝
* `\(78` ⅞
* `\(S1` ¹
* `\(S2` ²
* `\(S3` ³

* <code>\\[u<i>XXXX</i>]</code> Unicode characters

