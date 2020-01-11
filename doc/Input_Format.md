# Input Format

This file describes
the nroff input format
expected by *man-to-md*.

The program should accept most simple man pages without significant changes.


## Header

### TH Headline

The first input line (after comments)
must be a `.TH` line with this syntax:

<pre><code><b>.TH</b> <i>programShortName</i> <i>manSection</i> [<i>date</i> [<i>programNameAndVersion</i> [...]]]</code></pre>

Example:
`.TH MAN-TO-MD 1 "July 2017" "man-to-md v0.4"`

* *programShortName* will be lowercased and used as the document title.
* *programNameAndVersion* should be a string
  like “`man-to-md 1.0`” or “`man-to-md v2.9.9-alpha3`”.
* Your program's name from the first token and its man section from the second token will be used for the output's headline
  (e.g. “man-to-md(1) - *description*).


### NAME Section

After the `.TH` line,
the first section must be the `NAME` section
which should contain only one text line:

<pre><code><b>.SH</b> NAME
<i>programName</i> \- <i>programDescription</i></pre></code>

Example:
```roff
.SH NAME
man-to-md \- Converts nroff man pages to Markdown
```

* <i>programName</i> will be ignored.
* <i>programDescription</i> should be a short description of your program's purpose.
  It will be used for the output's headline.
* Instead of the plain dash (`\-` or `-`),
  you can also use the en-dash (`\(en`)
  or the em-dash (`\(em`).


### SYNOPSIS Section

After the `NAME` section,
the next section must be called
either `SYNOPSIS` or `SYNTAX`
and it should only show your program's call syntax.

<pre><code><b>.SH</b> SYNOPSIS
<i>programCallSyntax</i></code></pre>

Example:
```roff
.SH SYNOPSIS
\fBman-to-md\fR
[\fIOPTIONS\fR]
[\fB--\fR]
<\fIFILENAME\fR
```

* In the output, this section will be shown as a <code>```</code> block
  below your program name, version, and short description.
* Without the `-f` option, any formatting will be removed.
* With the `-f` option, the `\fB`/`\fI`/`\fR` formatting sequences will be converted to Markdown HTML.
* Multiple invocation variants can be separated with `.br` lines.


## Main Content

After the `SYNOPSIS`/`SYNTAX` section
comes the main text content.

* From here on, *man-to-md* does not expect any particular section titles.
* It's common to start with a `DESCRIPTION` section
  that explains what the program actually does
  and what it's commonly used for.
* After that, an `OPTIONS` section usually describes the available program options
  (with a `.TP` list).
* The last sections are usually a subset of these:
    * `EXAMPLES` – usage examples and program output.
    * `EXIT CODES` – exit codes your program might return in various error conditions.
    * `LICENSE` – your program's license, preferrably with a link to the full license text.
    * `AUTHOR` – your name and contact information.
    * `SEE ALSO` – references to other man pages, plus maybe a link to your project's homepage.


### Subsections

Besides top-level sections (<code>.SH <i>sectionTitle</i></code>),
you may also use subsections:

<pre><code><b>.SS</b> <i>sectionTitle</i></code></pre>


### Text formatting

* Lines starting with the **`.B`** command will be printed in **\*\*boldface\*\***.
* Lines starting with the **`.I`** command will be printed in *\*italics\**.
* The **`\fB`**, **`\fI`**, and **`\fR`** escape sequences
  can be used anywhere
  for bold, italic, and regular text,
  respectively.
* The `.BI`/`.IB`/`.BR`/`.RB`/`.RI`/`.IR` commands
  will set the tokens on the remaining line
  in alternating highlighting.
  “`R`” means regular text.

Example:

```roff
Normal.
.B "This line will be printed in boldface!"
Normal again.
Let's mix it up: \fBbold!\fR normal! \fIitalics!\fR normal!
.BR bold! normal! "bold... ...still bold" "normal!"
```


### Line Breaks

* Line breaks in the input
  will be converted to spaces.
* Paragraphs should be separated with the **`.P`** command.  
  Alternatively, you can use the `.PP` or `.LP` commands for that.
* To print a line break,
  use the **`.br`** command.


### Comments

* Line comments (`\"`) may appear anyhwere.
* The line comment command (`.\"`) is also recognized.
* Block comments can be started with `.ig` and ended with `..`.


### Lists

*man-to-md* can handle two kinds of nroff lists:

* **`.TP`** lists,
  which are similar to TeX' *description* lists.  
  Each `.TP` command begins a new list item.
  The first line after the `.TP` line is special:
  It is the item's name and commonly printed in boldface (`.B` line).
  All lines after that (until the next `.TP` or `.P` line)
  will be indented.
* **`.IP`** lists,
  which are similar to TeX' *itemize* lists.  
  Each `.IP` command begins a new list item and should be followed by a bullet string (usually `"-"`) and an indentation depth (usually `2`).
  All lines after that (until the next `.IP` or `.P` line)
  will be indented.

List end:

* Lists should be ended with a new paragraph
  (`.P`/`.PP`/`.LP`).
  This resets the indentation back to default.
* The start of a new section (`.SH`/`.SS`) also ends any lists.

Nested lists:

* The `.RS` command increases the current indentation by one level, which can be used for a sub-list.
* The `.RE` command reduces the current indentation by one level.

Example of a combined nested list:

```roff
.TP
.B "-v, --verbose"
Enables verbose output.
.TP
.B "-q, --quiet"
Reduces output.
.TP
.B "-m, --mode=MODE"
Selects the operating mode.
Available modes:
.RS    \" begin nested list
.IP - 2
\fB0\fR: level zero mode.
.IP - 2
\fB1\fR: level one mode.
.RE    \" end nested list
.P     \" end list
```

(By default, nroff prints one empty line after every list item.
In case of nested lists, it might be better to suppress this behaviour
with a `.PD 0` command right before the `.RS` nested list begin.
Restore the original item padding with `.PD` after the `.RE` nested list end.
Usage of the `.PD` command will not change the *man-to-md* output.)


### Links

* Normal URLs in the input won't be changed in any way.
  Most Markdown viewers will turn them into links automatically.
* E-mail addresses in the input
  will be converted to
  <code>\[<i>addr</i>]\(mailto:<i>addr</i>)</code> links,
  but only if the current section is named “`AUTHOR`” (or “`AUTHORS`”).
  In all other sections,
  e-mail addresses will not be treated specially.
* To have a link with a custom label,
  put the label on its own line
  and the URL in parentheses (or brackets) on the next line,
  optionally followed by punctuation.
  It will be converted to a
  <code>\[<i>label</i>](<i>url</i>)</code> Markdown link.

Example:

```roff
For more information, refer to
RFC\ 8140
(https://tools.ietf.org/html/rfc8140).
```

This will be converted to
“`For more information, refer to [RFC 8140](https://tools.ietf.org/html/rfc8140).`”,  
which will render as
“For more information, refer to [RFC 8140](https://tools.ietf.org/html/rfc8140).”.

Special case: internal links.

* If you want your Markdown output file
  to include a relative link to a repository-internal file
  (GitHub supports this),
  there are two possible ways:
  * A comment line containing only the word “`INTERNAL-LINK`”,
    followed by the link target in angle brackets.  
    This will result in a <code>\[<i>target</i>](<i>target</i>)</code> link.
  * A comment line containing only the word “`INTERNAL-LINK`”,
    followed by one line containing the link title (must not start with an opening angle bracket),
    followed by the link target in angle brackets.  
    This will result in a <code>\[<i>title</i>](<i>target</i>)</code> link.

Internal link example:

```roff
For more information, see
.\" INTERNAL-LINK
<doc/Other_Information.md>.
Got it?
```


### Code blocks

Some man pages contain unformatted code blocks,
usually in the `EXAMPLES` section.

* The usual way to format a code block is to enclose it in **`.nf`** and **`.fi`** commands.  
  The Markdown output will be a <code>```</code> block.
* *man-to-md* knows extra syntax for shell input and sample output:
  **`.cm`**–`.cx` and
  **`.co`**–`.cx`.
    * `.cm` is for a shell command and its output.
      Follow the `.cm` command with the shell command in quotes.
      It will be printed in boldface and slightly indented.
      The following lines are considered the command's output
      and will be printed in regular text but slightly indented as well.  
      In the Markdown output, the first line will be a boldface <code>`</code> code line,
      followed by a regular <code>```</code> block.
    * `.co` is for a code block without a leading command.
      It will be printed in regular text, slightly indented.  
      In the Markdown output, the `.co` block
      will get converted to a <code>```</code> block.
    * End all `.cm` and `.co` code blocks with a `.cx` line.
* To use formatting in code blocks,
  see the [Synopsis section description](#synopsis-section) –
  the same rules apply here.

NB: The `.cm`/`.co`/`.cx` commands are a custom extension, not regular man-pages nroff commands!
If you want to use them in your manpages and have them actually work,
you should include this macro definition somewhere near the beginning of your nroff file:

```roff
.de co
.  P
.  nf  
.  RS 4
..
.de cm
.  co  
.  B "\\$1"
.  P
..
.de cx
.  RE  
.  fi  
.  P
..
```

