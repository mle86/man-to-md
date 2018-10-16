#!/usr/bin/perl

# man-to-md -- Converts nroff man pages to Markdown.
# Copyright © 2016-2018  Maximilian Eul
#
# This file is part of man-to-md.
# 
# man-to-md is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# man-to-md is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with man-to-md.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Getopt::Long qw(:config no_getopt_compat bundling);
use File::Basename qw(dirname basename);
chdir dirname($0);

use constant {
	PROGNAME => basename($0),
	PROGVER  => '0.9.0',
	PROGDATE => '2018-05-07',

	DEFAULT_COMMENT => "This file was autogenerated from the man page with 'make README.md'",
};

my ($section, $subsection, $prev_section);
my ($is_synopsis, $in_list, $start_list_item, $is_desclist, $in_rawblock, $text_indent, $start_indented_line);
my ($progname, $mansection, $version, $is_bare_version, $verdate, $description);
my $headline_prefix = '# ';
my $section_prefix  = '# ';
my $subsection_prefix  = '## ';
my $re_token = '(?:"(?:\\.|[^"])*+"|(?:\\\\.|[^\s"])(?:\\\\.|\S)*+)';  # matches one token, with or without "enclosure".

my $replacement_token = "\001kXXfQ6Yd" . int(10000 * rand);

my %paste_after_section  = ( );  # ('section' => ['filename'...], ...)
my %paste_before_section = ( );
my $code_formatting = 0;
my $add_comment;

my %words = ( );
my %stopwords = map { $_ => 1 } (qw(
	a an the
	as at and but by for from nor or so yet while if on of off to it its it's
	on in onto into with within unless while after before once since until when since
));

sub Syntax (;$) {
	printf STDERR <<EOT, PROGNAME;
syntax: %s [OPTIONS] < input.nroff > output.md
Converts nroff man pages to Markdown.
Options:
  -p, --paste-section-after SECTION:FILENAME
                   Pastes the contents of FILENAME after the input SECTION
                   and adds the filename as section title.
  -P, --paste-section-before SECTION:FILENAME
                   Pastes the contents of FILENAME right before the input SECTION
                   and adds the filename as section title.
  --paste-after  SECTION:FILENAME   Like -p, but does not add a section title.
  --paste-before SECTION:FILENAME   Like -P, but does not add a section title.
  -c, --comment [COMMENT]  Adds an invisible comment as first line.
                           Uses a default comment without its argument.
  -w, --word WORD  Adds a word to the list of words
                   not to be titlecased in chapter titles.
  -f, --formatted-code  Allow formatting in nf/fi code blocks and Synopsis line.
  -h, --help     Show program help
  -V, --version  Show program version

EOT
	exit ($_[0] // 0);
}

sub Version () {
	printf <<EOT, PROGNAME, PROGVER, PROGDATE;
%s v%s
Written by Maximilian Eul <maximilian\@eul.cc>, %s.
License GPLv3+: GNU GPL Version 3 or later <http://gnu.org/licenses/gpl.html>

EOT
	exit;
}

GetOptions(
	'paste-after=s@'		=> sub{ add_paste_file('after', split /:/, $_[1]) },
	'paste-before=s@'		=> sub{ add_paste_file('before', split /:/, $_[1]) },
	'p|paste-section-after=s@'	=> sub{ add_paste_file('after', split(/:/, $_[1]), 1) },
	'P|paste-section-before=s@'	=> sub{ add_paste_file('before', split(/:/, $_[1]), 1) },
	'c|comment:s'		=> sub{ $add_comment = (length $_[1])  ? $_[1] : DEFAULT_COMMENT },
	'f|formatted-code'	=> sub{ $code_formatting = 1 },
	'w|word=s'		=> sub{ $words{ lc $_[1] } = $_[1] },
	'h|help'		=> sub{ Syntax 0 },
	'V|version'		=> sub{ Version },
);

sub add_paste_file ($$$) {
	my ($op, $section, $filename, $with_section) = @_;
	die "file not readable: $filename"  unless (-f $filename && -r $filename);
	my $addto = ($op eq 'after') ? \%paste_after_section : \%paste_before_section;
	push @{ $addto->{$section} }, [$filename, $with_section];
}

# Install postprocessing function for all output:
sub {
	my $pid = open(STDOUT, '|-');
	return  if $pid > 0;
	die "cannot fork: $!"  unless defined $pid;

	local $/;
	local $_ = <STDIN>;

	# merge code blocks:
	s#(?:\n```\n```\n|</code></pre>\n<pre><code>|</code>\n<code>\n?)# #g;
	s#(?:</code><code>|</pre><pre>)##g;
	s#(?:\n</synopsis>\n<synopsis>\n|\n</synopsisFormatted>\n<synopsisFormatted>\n)# #g;

	# ensure correct synposis format:
	s#(<(synopsis(?:Formatted)?)>.*</\2>)#postprocess_synopsis($1)#se;

	# URLs:
	my $re_urlprefix = '(?:https?:|s?ftp:|www)';
	s/^(.+[^)>])(?:$)\n^(?:[\[\(]\*{0,2}(${re_urlprefix}.+?)\*{0,2}[\]\)])([\s,;\.\?!]*)$/[$1]($2)$3/gm;

	# Line breaks;
	s/\n *${replacement_token}#BRK#/  \n/g;

	# Internal links:
	s=${replacement_token}#INTERNAL-LINK#\n?(?:((?!<|&lt;)[^\n]+)\n)?(?:<|&lt;)([^\n]+?)(?:>|&gt;)([\s,;\.\?!]*)$=
		'[' . ($1 // $2) . '](' . $2 . ')' . $3
		=gme;

	# Clean up remaining markers:
	s/${replacement_token}#[\w\-]+#\n?//g;

	# There should never be a linebreak after a NBSP, it defeats the entire purpose.
	s/(?<=&nbsp;)\n//g;

	print;
	exit;
}->();

# nextline(keep_blanklines=false)
#  Fetch next input line into $_.
#  Returns true if there was an input line, false if EOF.
#  If the first argument (keep_blanklines) is true,
#  blank lines will be returned;
#  by default, blank lines will be skipped.
#  This function also removes all line comments (\")
#  and block comments (.ig).
sub nextline {
	my $keep_blanklines = $_[0] // 0;
	my $in_comment;
	do {{
		$_ = <>;
		return 0 unless defined;

		# special markers in comments:
		s/^\.?\s*\\"\s*INTERNAL-LINK.*$/${replacement_token}#INTERNAL-LINK#/s  or

		s/^\.\\".*$//  # remove line comment commands
		or
		s/^((?:\\[^"]|[^\\])++)\\".*$/$1/;  # remove line comments

		if (m/^\.ig/ || $in_comment) {
			# block comment
			$in_comment = ! m/^\.\./;
			redo;
		}

	}} while (line_empty() && !$keep_blanklines);
	1
}

sub line_empty { m/^\s*$/ }

sub strip_highlighting {
	# remove remaining highlighting:
	s/(?:^\.[BIR]{1,2} |\\f[BIR])//g;

	# paragraphs:
	if (m/^\.br/i) {
		$_ = "${replacement_token}#BRK#";
		return
	} elsif (m/^\.(LP|P|PP)\b/) {
		$_ = "\n";  # one blank line
		if ($text_indent > 0) {
			$_ .= (' ' x (4 * ($text_indent - 1))) . ': ';
			$start_indented_line = 2;
		}
		$in_list = 0;
	}

	# known special characters:
	s/\\\(lq/“/g;
	s/\\\(rq/”/g;
	s/\\\(oq/‘/g;
	s/\\\(cq/’/g;
	s/\\\(dq/"/g;
	s/\\\(aq/'/g;
	s/\\\(Fo/«/g;
	s/\\\(Fc/»/g;
	s/\\\(fo/‹/g;
	s/\\\(fc/›/g;
	s/\\\(hy/-/g;
	s/\\\(en/–/g;
	s/\\\(em/—/g;

	s/\\[ ~]/&nbsp;/g;  # non-breakable space
#	s/\\-/&#8209;/g;  # non-breakable hyphen

	# other special characters, except "\\":
	s/`/\\`/g;
	s/\\([\- ])/$1/g;
#	s/\\(.)/$1/g;

	# non-printing zero-width characters, used to mask strings that are not commands:
	s/\\[&\):]//g;
	# other unprintables and control characters:
	s/\\[\/,]//g;


}

sub strip_html {
	# avoid accidental html output:
	my @result = map{ s/</&lt;/g; $_ } ($#_ >= 0 ? @_ : ($_));
	wantarray ? @result : $result[0]
}

sub section_title {
	# If the current line contains a section title,
	# this function sets $section, $prev_section, and the $is_... flags accordingly
	# and returns true.
	return 0 unless m/^\.SH +(.+)$/m;

	$in_list = 0;
	$text_indent = 0;
	$prev_section = $section // '';
	$section = qtok($1);
	undef $subsection;

	$is_synopsis = ($section eq 'SYNTAX' || $section eq 'SYNOPSIS');
	1
}

sub subsection_title {
	return 0 unless m/^\.SS +(.+)$/m;

	$in_list = 0;
	$text_indent = 0;
	$subsection = qtok($1);
	1
}

sub postprocess_synopsis {
	local $_ = $_[0];

	# Turn fake block tags into correct markup:
	s#<synopsis>(.*)</synopsis>#```$1```#s ||
	s#^<synopsisFormatted>\n(.*)\n</synopsisFormatted>#<pre><code>$1</code></pre>#s;

	# Synopsis blocks are processed line-by-line, then merged by the global output postprocessing function.
	# This may cause spaces to be inserted at unexpected places. Remove them:
	s/ *${replacement_token}#BRK# */\n/gs;

	$_
}

sub reformat_syntax {
	# commands to be ignored:
	if (m/^\.(?:PD|hy|\s|$)/) {
		$_ = '';
		return
	}

	# raw block markers:
	if (m/^\.(?:nf|co|cm)/) {
		$in_rawblock = 2;
		if (m/^\.cm(?:\s+($re_token))?/) {
			chomp;
			$_ = qtok($1);
			strip_highlighting();
			$_ = "\n**\`$_\`**\n\n"
		} elsif (m/^\.co/) {
			$_ = "\n"
		} else {
			$_ = ''
		}
		return
	}

	# command invocation in Synopsis section:
	if ($is_synopsis && !line_empty()) {
		# only code here
		chomp;
		if ($code_formatting) {
			# synopsis content with formatting
			$_ = strip_html($_);
			reformat_html();
			strip_highlighting();
			s/\\(.)/$1/g;  # in md <pre> blocks, backslashes are not special!
			$_ = "<synopsisFormatted>\n$_\n</synopsisFormatted>\n"
		} else {
			strip_highlighting();
			$_ = "<synopsis>\n$_\n</synopsis>\n";
		}
		return
	}

	# bold and italics:
	s/\\fB(.+?)\\fR/**$1**/g;
	s/\\fI(.+?)\\fR/*$1*/g;

	# groff concatenates tokens in .B and .I lines with spaces.
	# We still have to tokenize and re-join the line
	# to get rid of the token doublequote enclosures.
	s/^\.B +(.+)/'**' . join(' ', tokenize($1)) . '**'/ge;
	s/^\.I +(.+)/'*' . join(' ', tokenize($1)) . '*'/ge;

	s/^\.([BIR])([BIR]) *(.+)/alternating_highlighting($1, $2, $3)/ge;

	# other formatting:
	strip_highlighting();
	$_ = strip_html($_);

	if ($section eq 'AUTHOR' || $section eq 'AUTHORS') {
		# convert e-mail address to link:
		s/\b(\w[\w\-_\.\+]*@[\w\-_\+\.]+?\.[\w\-]+)\b/[$1](mailto:$1)/u;
	}

	# item lists and description lists:
	if (m/^\.IP(?: +($re_token))?/ || m/^\.TP/) {
		my $tok = defined($1) ? qtok($1) : undef;
		my $is_bullet = (!defined($tok) || $tok eq '' || $tok eq '-' || $tok eq 'o');
		$is_desclist = !$is_bullet || (m/^\.TP/ && ($section ne 'EXIT CODES' && $section ne 'EXIT STATUS'));
		my $indent = ($in_list > 1)
			? '    ' x ($in_list - 1)
			: '';
		$_ = $indent . '* ';  # no trailing break here
		if ($is_bullet) {
			$start_list_item = 1;
		} else {
			$_ .= $tok . "  \n";
		}
		if (!$in_list) {
			$_ = "\n$_";
			$in_list = 1;
		}
	} elsif ($in_list && m/^\.RS/) {
		$in_list++;
		$_ = ''
	} elsif ($in_list && m/^\.RE/) {
		$in_list--;
		$_ = ''
	} elsif (m/^\.RS/) {
		$text_indent++;
		$start_indented_line = 1;
		$_ = (' ' x (4 * ($text_indent - 1))) . ': ';
	} elsif (m/^\.RE/) {
		$text_indent--  if ($text_indent > 0);
		$_ = "\n";  # extra line ends the definition list indentation
	} elsif ($in_list) {
		if ($start_list_item) {
			$start_list_item = 0;

			# In description list (probably some CLI options).
			# Add extra line break after option name:
			s/$/  /  if $is_desclist;
		} else {
			my $indent = ' ' x (2 + (4 * ($in_list - 1)));
			s/^/$indent/;
		}
	} elsif ($text_indent) {
		if ($start_indented_line) {
			$start_indented_line--
		} else {
			my $indent = (' ' x (2 + (4 * ($text_indent - 1))));
			s/^/$indent/;
		}
	}
}

sub reformat_html {
	s#\\fB(.+?)\\fR#<b>$1</b>#g;
	s#\\fI(.+?)\\fR#<i>$1</i>#g;
	s#^\.B +(.+)#<b>$1</b>#g;
	s#^\.I +(.+)#<i>$1</i>#g;
}

# Strips doublequote enclosure from string tokens, if present.
sub qtok {
	my @result = map{ m/^"(.+)"$/ ? $1 : $_ } @_;
	wantarray ? @result : $result[0]
}

# Extracts all tokens from the input string and returns them in a list.
# Tokens are things enclosed in unescaped doublequotes or any strings without spaces.
sub tokenize { qtok($_[0] =~ m/$re_token/g) }


sub print_section_title    ($) { printf "\n%s%s\n\n", $section_prefix, strip_html($_[0]) }
sub print_subsection_title ($) { printf "\n%s%s\n\n", $subsection_prefix, strip_html($_[0]) }

sub paste_file {
	my ($filename, $with_section) = @_;
	return 0 unless -r $filename;

	if ($with_section && $filename =~ m/^(?:[a-zA-Z0-9_\-]+\/)*(.+)\.md$/) {
		my $section_title = $1;
		print_section_title $section_title;
	}

	open FH, "< $filename";
	local $/;
	my $content = <FH>;
	close FH;

#	$content =~ s/\s+$//;
	print "$content\n";

	1
}

sub alternating_highlighting {
	my @hl = @_[0, 1];
	my @tokens = tokenize($_[2]);
	my $h = 0;

	# groff concatenates tokens in .B and .I lines with spaces,
	# but tokens in .[BIR][BIR] lines are concatenated WITHOUT spaces.
	# Therefore we have to join('') the tokens here:

	return join '', map {
		my $highlightkey = $hl[$h++ % 2];

		if ($highlightkey eq 'R') {
			$_
		} elsif ($highlightkey eq 'I') {
			'*' . $_ . '*'
		} elsif ($highlightkey eq 'B') {
			'**' . $_ . '**'
		}
	} @tokens
}

sub titlecase {
	local $_ = $_[0];
	my $re_word = '(\pL[\pL\']*)';

	# lowercase stop words, keep case of known words, else titlecase
	s!$re_word!$stopwords{lc $1} ? lc($1) : ($words{lc $1} // ucfirst(lc($1)))!ge;
	# capitalize first word following colon or semicolon
	s/ ( [:;] \s+ ) $re_word /$1\u$2/x;
	# title first word (even a stopword), except if it's a known word
	s!^\s*$re_word!$words{lc $1} // ucfirst(lc($1))!e;

	$_
}

sub read_version {
	if ($_[0] eq '') {
		# no version string found
		$version = '';
		return 1
	}

	if ($_[0] =~ m/^(?:$progname(?: \(\d\))?\s+)(?:v|ver\.?|version)? ?(\d[\w\.\-\+]*)$/i) {
		# found explicit version following known progname
		$is_bare_version = 1;
		$version = $1;
		return 1
	}

	# found something else
	$version = $_[0];
	return 1
}

##############################

# eat first line, extract progname, version, and man section
nextline()
	and m/^\.TH ($re_token) ($re_token) ($re_token)(?: ($re_token))?/
	and (($progname, $mansection, $verdate) = (lc(qtok($1)), qtok($2), qtok($3)))
	and read_version(qtok($4 // ''))
	or die "could not parse first line";

# skip NAME headline, extract description
if (nextline() && section_title() && $section eq 'NAME') {
	if (nextline() && m/ \\?(?:-|\\\(em|\\\(en) +(.+)$/) {
		$description = $1;
		nextline();
	}
}

print "[//]: # ($add_comment)\n\n"  if defined $add_comment;
printf "%s%s(%s)", $headline_prefix, strip_html($progname), $mansection;
printf " - %s", strip_html($description)  if defined $description;
print "\n\n";

if (defined $paste_after_section{'HEADLINE'}) {
	paste_file(@$_)  foreach (@{ $paste_after_section{'HEADLINE'} });
	undef $paste_after_section{'HEADLINE'};
}

if ($version && $verdate) {
	if ($is_bare_version) {
		print "Version $version, $verdate\n\n";
	} else {
		print "$version, $verdate\n\n";
	}
}

# skip SYNOPSIS headline
nextline() if (section_title && $is_synopsis);


do {
	if ($in_rawblock) {
		if (m/^\.(?:fi|cx)/) {
			# code block ends
			$in_rawblock = 0;
			print "</code></pre>\n"  if $code_formatting;
			print "\n"  if m/^\.cx/;
		} elsif ($code_formatting) {
			# inside code block with limited html formatting
			if ($in_rawblock == 2) {
				$in_rawblock = 1;
				print "<pre><code>";
			}
			$_ = strip_html($_);
			reformat_html;
			strip_highlighting;
			s/\\(.)/$1/g;  # in md <pre> blocks, backslashes are not special!
			print
		} else {
			# inside code block without formatting
			strip_highlighting;
			s/\\(.)/$1/g;  # in md raw blocks, backslashes are not special!
			print "    $_"
		}

	} elsif (section_title) {
		# new section begins
		if (defined $paste_after_section{$prev_section}) {
			paste_file(@$_)  foreach (@{ $paste_after_section{$prev_section} });
			undef $paste_after_section{$prev_section};
		}
		if (defined $paste_before_section{$section}) {
			paste_file(@$_)  foreach (@{ $paste_before_section{$section} });
			undef $paste_before_section{$section};
		}
		print_section_title titlecase($section)

	} elsif (subsection_title) {
		# new subsection begins
		print_subsection_title $subsection

	} elsif (m/^\.de\b/) {
		# macro definition -- skip completely
		1 while (nextline(1) && ! m/^\.\./);

	} else {
		reformat_syntax;
		print
	}

} while (nextline(1));


foreach (values %paste_before_section)
	{ paste_file(@$_)  foreach (@$_) }
foreach (values %paste_after_section)
	{ paste_file(@$_)  foreach (@$_) }

