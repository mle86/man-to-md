[//]: # (This file was autogenerated from the man page with 'make README.md')

# man-to-md(1) - Converts nroff man pages to Markdown

Version 0.17.0, December 2020

<pre><code>$ <b>man-to-md.pl</b> [<i>OPTIONS</i>] &lt;<i>manpage.roff</i> &gt;<i>output.md</i></code></pre>

<a name="description"></a>

# Description

This program is a filter
that reads **man**(7)-formatted nroff man pages
and outputs Markdown.
It can be used to automatically convert
man page files
to Markdown README files.

<a name="options"></a>

# Options


* **-p**, **--paste-section-after** _SECTION_:_FILENAME_  
  Instructs the program to attach a Markdown file
  after the section named _SECTION_
  has been completely written to the output.
  _SECTION_ must be an exact match of the input section name.
  If the input contains no such section,
  the file will be attached to the end of the output.
  The attached file contents will have the exact _FILENAME_ (without the **.md** extension)
  as their top-level section title.  
  This option can be supplied more than once.
  Multiple files for the same section will be attached in the options' order.
* **-P**, **--paste-section-before** _SECTION_:_FILENAME_  
  Like **--paste-section-after**,
  but attaches the file contents
  to the output
  just _before_ the named section is written.
* **--paste-after** _SECTION_:_FILENAME_  
  Like **--paste-section-after**, but does not add a section title.
* **--paste-before** _SECTION_:_FILENAME_  
  Like **--paste-section-before**, but does not add a section title.
* **-c**, **--comment** [_COMMENT_]  
  Adds an invisible comment as first line.
  Without the argument, it uses this default comment:  
  “_This file was autogenerated from the man page with 'make README.md'_”.
* **--escaped-dashes**  
  Don't remove the backslash from escaped dashes (\\-).
* **-w**, **--word** _WORD_  
  Adds a _WORD_ to the list of known words
  not to be titlecased in section titles.
  (All other words will be titlecased
  except some known English stopwords which will be lowercased.)  
  This option can be supplied more than once
  to add multiple known words.
* **-f**, **--formatted-code**  
  Allows simple formatting in **.nf**-**.fi** code blocks
  and in the Synopsis line.
  (Without this option,
  all formatting in code block and in the Synopsis line
  will be removed.)
* **-h**, **--help**  
  Shows program help.
* **-V**, **--version**  
  Shows version and license information.

<a name="standards"></a>

# Standards

This program understands many **man**(7) nroff commands and macros
commonly used in man page files.
For a complete list, see&nbsp;[doc/Commands.md](doc/Commands.md).

The program emits Markdown syntax
that should be readable with most Markdown editors/viewers.
See&nbsp;[doc/Markdown_Output_Format.md](doc/Markdown_Output_Format.md)
for more information.

The program makes several assumptions about the input format
that are not standardized
but seem to be fairly commonplace
in man pages; see&nbsp;[doc/Input_Format.md](doc/Input_Format.md).
It does not yet understand the newer **mdoc**(7) format.

<a name="license"></a>

# License

[GNU GPL v3](http://gnu.org/licenses/gpl.html)

<a name="see-also"></a>

# See Also

Project homepage:
https://github.com/mle86/man-to-md

<a name="author"></a>

# Author

Maximilian Eul
&lt;[maximilian@eul.cc](mailto:maximilian@eul.cc)&gt;
(https://github.com/mle86)
