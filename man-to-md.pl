#!/usr/bin/perl

# man-to-md -- Converts nroff man pages to Markdown.
# Copyright © 2016-2020  Maximilian Eul
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
use utf8;
use Getopt::Long qw(:config no_getopt_compat bundling);
use File::Basename qw(dirname basename);
chdir dirname($0);

use constant {
	PROGNAME => basename($0),
	PROGVER  => '0.17.0',
	PROGDATE => '2020-12-18',

	DEFAULT_COMMENT => "This file was autogenerated from the man page with 'make README.md'",
};

my ($section, $subsection, $prev_section);
my ($is_synopsis, $in_list, $start_list_item, $is_desclist, $in_rawblock, $in_preblock);
my ($in_urltitle, $in_mailtitle);
my ($progname, $mansection, $version, $is_bare_version, $verdate, $description);
my ($lineopt, $line_did_set_options);
my $headline_prefix = '# ';
my $section_prefix  = '# ';
my $subsection_prefix  = '### ';

my $re_token = qr/(?:"(?:\.|[^"])*+"|(?:\\.|[^\s"])(?:\\.|\S)*+)/;  # matches one token, with or without "enclosure".
my $re_urlprefix = qr/(?:https?:|s?ftp:|www)/;
my $re_url = qr/${re_urlprefix}.+?/;
my $re_email = qr/(?:\w[\w\-_\.\+]*@[\w\-_\+\.]+?\.[\w\-]+)/;
my $re_punctuation = qr/[\s,;\.\?!]/;

my $replacement_token = "\001kXXfQ6Yd" . int(10000 * rand);

my %paste_after_section  = ( );  # ('section' => ['filename'...], ...)
my %paste_before_section = ( );
my $plain_dashes = 1;
my $code_formatting = 0;
my $add_comment;

my %strings = ( );
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
  --escaped-dashes  Don't remove the backslash from escaped dashes (\\-).
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
	'escaped-dashes'        => sub{ $plain_dashes = 0 },
	'c|comment:s'		=> sub{ $add_comment = (length $_[1])  ? $_[1] : DEFAULT_COMMENT },
	'f|formatted-code'	=> sub{ $code_formatting = 1 },
	'w|word=s'		=> sub{ $words{ lc $_[1] } = $_[1] },
	'h|help'		=> sub{ Syntax 0 },
	'V|version'		=> sub{ Version },
);

sub add_paste_file ($$$) {
	my ($op, $section, $filename, $add_section_title) = @_;
	die "file not readable: $filename"  unless (-f $filename && -r $filename);
	my $addto = ($op eq 'after')
		? \%paste_after_section
		: \%paste_before_section;
	push @{ $addto->{$section} }, {file => $filename, add_section_title => $add_section_title};
}

# Install postprocessing function for all output:
sub {
	my $pid = open(STDOUT, '|-');
	return  if $pid > 0;
	die "cannot fork: $!"  unless defined $pid;

	# process entire output at once:
	local $/;
	local $_ = <STDIN>;
	utf8::decode($_);

	# merge code blocks:
	s#(?:\n```\n```\n|</code></pre>\n<pre><code>|</code>\n<code>\n?)# #g;
	s#(?:</code><code>|</pre><pre>)##g;
	s#(?:\n</(synopsis|synopsisFormatted)>\n<\1>\n)# #g;

	# ensure correct synposis format:
	s#(<(synopsis(?:Formatted)?)>.*</\2>)#postprocess_synopsis($1)#se;

	# URLs:
	s/(\[[^\]]+) (?=\]\((?:$re_urlprefix|mailto:))/$1/g;  # remove trailing spaces in link titles
	s/^(.+)(?<!&gt;)(?<!>)(?:$)\n^(?:[\[\(]\*{0,2}($re_url)\*{0,2}[\]\)])($re_punctuation*)$/[$1]($2)$3/gm;

	# Line breaks;
	s/\n *${replacement_token}#BRK#/  \n/g;

	# Internal links:
	s=${replacement_token}#INTERNAL-LINK#\n? *(?:((?!<|&lt;)[^\n]+)\n)? *(?:<|&lt;)([^\n]+?)(?:>|&gt;)($re_punctuation*)$=
		'[' . ($1 // $2) . '](' . $2 . ')' . $3
		=gme;
	s=${replacement_token}#LINK-TO#([^#]+)#\n? *(<|&lt;|“|‘|")?([^\n]+?)((?:>|&gt;|”|’|")?$re_punctuation*)?$=
		($2 // '') . '[' . $3 . '](#' . section_slug($1) . ')' . ($4 // '')
		=gme;
		# 1 target
		# 2 prefix
		# 3 link text
		# 4 suffix

	# Clean up remaining markers:
	s/${replacement_token}#[\w\-]+#\n?//g;

	# There should never be a linebreak after a NBSP, it defeats the entire purpose.
	s/(?<=&nbsp;)\n//g;

	utf8::encode($_);
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

		# options for following line(s):
		$line_did_set_options = 0;
		if (s/^\.?\s*\\"\s*(PLAIN)\s*$//) {
			$line_did_set_options = 1;
			add_lineopt($1);
		}

		# special markers in comments:
		s/^\.?\s*\\"\s*INTERNAL-LINK.*$/${replacement_token}#INTERNAL-LINK#/s  or
		s/^\.?\s*\\"\s*LINK-TO\s+([^\s#][^#\r\n]*)\s*$/${replacement_token}#LINK-TO#$1#/s  or

		s/^\.\\".*$//  # remove line comment commands
		or
		s/^((?:\\[^"]|[^\\])++)\\".*$/$1/;  # remove line comments

		if (m/^\.ig/ || $in_comment) {
			# block comment
			$in_comment = ! m/^\.\./;
			redo;
		}

		# Keep reading if line ends with “\<NEWLINE>”, it's not truly finished yet:
		while (!eof && s/((?:\\{2})*)\\[\r\n]+$/$1/) {
			$_ .= <>;
		}

	}} while (line_empty() && !$keep_blanklines);
	utf8::decode($_);
	1
}

sub line_empty { m/^\s*$/ }

sub has_lineopt ($) { defined($lineopt) && $lineopt =~ m/\b$_[0]\b/ }
sub add_lineopt ($) { $lineopt .= " $_[0] " }
sub clr_lineopt ()  { undef $lineopt }

sub strip_highlighting {
	# remove remaining highlighting:
	s/(?:^\.[BIR] |\\f[BIRP1234])//g  unless $_[0];
	# get rid of .BR formatting, but correctly unquote its arguments:
	s/^\.[BIR]{2} *(.+)/alternating_highlighting('R', 'R', $1)/ge  unless $_[0];

	# paragraphs:
	if (m/^\.br/i) {
		$_ = "${replacement_token}#BRK#";
		return
	} elsif (m/^\.(LP|P|PP|sp)\b/) {
		$_ = "\n";  # one blank line
		$in_list = 0;
	}

	# known special characters:
	s/\\\(lq/“/g;
	s/\\\(rq/”/g;
	s/\\\(oq/‘/g;
	s/\\\(cq/’/g;
	s/\\\(ga/`/g;
	s/\\\(aq/'/g;
	s/\\\(dq/"/g;
	s/\\\(fm/′/g;
	s/\\\(sd/″/g;
	s/\\\(Fo/«/g;
	s/\\\(Fc/»/g;
	s/\\\(fo/‹/g;
	s/\\\(fc/›/g;
	s/\\\(hy/-/g;
	s/\\\(en/–/g;
	s/\\\(em/—/g;
	s/\\\(ha/^/g;
	s/\\\(lh/☜/g;
	s/\\\(rh/☞/g;

	s/\\\(at/@/g;
	s/\\\(bu/·/g;
	s/\\\(ci/○/g;
	s/\\\(CR/↵/g;
	s/\\\(de/°/g;
	s/\\\(dg/†/g;
	s/\\\(dd/‡/g;
	s/\\\(lz/◊/g;
	s/\\\(mc/µ/g;
	s/\\\(OK/✓/g;
	s/\\\(ps/¶/g;
	s/\\\(ru/_/g;
	s/\\\(sc/§/g;
	s/\\\(sh/#/g;
	s/\\\(sq/□/g;
	s/\\\(ti/~/g;

	s/\\\(ct/¢/g;
	s/\\\(Do/\$/;
	s/\\\([Ee]u/€/g;
	s/\\\(Ye/¥/g;
	s/\\\(Po/£/g;
	s/\\\(Cs/¤/g;

	s/\\\(co/©/g;
	s/\\\(rg/®/g;
	s/\\\(tm/™/g;

	s/\\\(ff/ﬀ/g;
	s/\\\(fi/ﬁ/g;
	s/\\\(Fi/ﬃ/g;
	s/\\\(fl/ﬂ/g;
	s/\\\(Fl/ﬄ/g;
	s/\\\(12/½/g;
	s/\\\(14/¼/g;
	s/\\\(34/¾/g;
	s/\\\(38/⅜/g;
	s/\\\(58/⅝/g;
	s/\\\(78/⅞/g;
	s/\\\(S1/¹/g;
	s/\\\(S2/²/g;
	s/\\\(S3/³/g;

	# unicode characters:
	s/\\\[u0*?([0-9a-fA-F]+)\]/ chr hex $1 /ge;

	s/\\[ ~]/&nbsp;/g;  # non-breakable space
#	s/\\-/&#8209;/g;  # non-breakable hyphen
	s/\\%//g;  # hyphenation command

	# other special characters, except "\\":
	s/`/\\`/g;
	s/\\ / /g;
	s/\\-/-/g  if $plain_dashes;
#	s/\\(.)/$1/g;

	# non-printing zero-width characters, used to mask strings that are not commands:
	s/\\[&\)]//g;
	s/\\:/​/g;  # ZWSP
	# other unprintables and control characters:
	s/\\[\/,]//g;

	# unknown \*X or \*(XX string usages not previously defined with .ds:
	s/^(?:\\[^\*]|[^\\])*?\K\\\*[^\s\(]//g;
	s/^(?:\\[^\*]|[^\\])*?\K\\\*\([^\s]{2}//g;
	# These regexes look a bit weird.
	# They prevent removal of non-string-sequence input like ...**\\\\**...
	# but excluding there patterns with a negative look-behind
	# won't work because it's not a fixed-length match.
	# TODO: Apply similar exclusions to all other backslash-escaped replacements in this sub?

	utf8::encode($_);
}

sub strip_html {
	# avoid accidental html output:
	my @result = map{
			s/</&lt;/g;
			s/>/&gt;/g;
		$_ }
		($#_ >= 0 ? @_ : ($_));
	wantarray ? @result : $result[0]
}

sub section_title {
	# If the current line contains a section title,
	# this function sets $section, $prev_section, and the $is_... flags accordingly
	# and returns true.
	return 0 unless m/^\.SH +(.+)$/m;

	$in_list = 0;
	$prev_section = $section // '';
	$section = qtok($1);
	undef $subsection;

	$is_synopsis = ($section eq 'SYNTAX' || $section eq 'SYNOPSIS');
	1
}

sub subsection_title {
	return 0 unless m/^\.SS +(.+)$/m;

	$in_list = 0;
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
	if (m/^\.(?:PD|hy|ad|ft|fi|\s|$)/) {
		$_ = '';
		return
	}

	# replace .ds strings:
	for my $sname (keys %strings) {
		if    (length $sname == 1) { s/\\\*$sname/$strings{$sname}/g; }
		elsif (length $sname == 2) { s/\\\*\($sname/$strings{$sname}/g; }
	}

	# raw block markers:
	if (m/^\.(?:nf|co|cm)/) {
		if (has_lineopt('PLAIN')) {
			$in_preblock = 2;
		} else {
			$in_rawblock = 2;
		}
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

	# Usually we can get away with unescaped underscores.
	# But they'll lead to problems inside words that use \fI font changes.
	# So escape just these occurrences:
	s/(?=\S*\\f[IRP12]\S*)_/\\_/g;

	# bold and italics:
	# (The special cases <b>*</b> and <i>*</i> are handled after the strip_html() call.)
	s/(?:\\f[B3])+([^\*_]|.{2,}?)(?:\\f[RP1])+/**$1**/g;
	s/(?:\\f[I2])+([^\*_]|.{2,}?)(?:\\f[RP1])+/_$1_/g;
	s/(?:\\f4)+([^\*_]|.{2,}?)(?:\\f[RP1])+/**_$1_**/g;

	# groff concatenates tokens in .B and .I lines with spaces.
	# We still have to tokenize and re-join the line
	# to get rid of the token doublequote enclosures.
	s/^\.B +([^\*].*)/'**' . join(' ', tokenize($1)) . '**'/ge;
	s/^\.I +([^\*].*)/'_' . join(' ', tokenize($1)) . '_'/ge;

	s/^\.([BIR])([BIR]) *(.+)/alternating_highlighting($1, $2, $3)/ge;

	# other formatting:
	strip_highlighting(1);

	# escape html tags:
	$_ = strip_html($_);

	# process highlighting special cases:
	s#(?:\\f[B3])+(\*|_)(?:\\f[RP1])+#<b>\\$1</b>#g;
	s#(?:\\f[I2])+(\*|_)(?:\\f[RP1])+#<i>\\$1</i>#g;
	s#(?:\\f4)+(\*|_)(?:\\f[RP1])+#<b><i>\\$1</i></b>#g;
	s#^\.B +(\*.*)#'<b>' . join(' ', tokenize($1)) . '</b>'#ge;
	s#^\.I +(\*.*)#'<i>' . join(' ', tokenize($1)) . '</i>'#ge;

	# remove remaining highlighting:
	s/(?:^\.[BIR]{1,2} |\\f[BIRP1234])//g;

	if ($section eq 'AUTHOR' || $section eq 'AUTHORS') {
		# convert e-mail address to link:
		s/\b($re_email)\b/[$1](mailto:$1)/u;
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
	} elsif (m/^\.(?:RS|RE)/) {
		# ignore
		$_ = ''
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
	} elsif (m/\.UR ($re_url)\s*$/) {
		$in_urltitle = $1;
		$_ = '['
	} elsif (m/\.MT ($re_email)\s*$/) {
		$in_mailtitle = $1;
		$_ = '['
	} elsif (defined $in_urltitle && m/\.UE(?: (\S*)\s*)?$/) {
		$_ = "]($in_urltitle)" . ($1 // '') . "\n";
		undef $in_urltitle
	} elsif (defined $in_mailtitle && m/\.ME(?: (\S*)\s*)?$/) {
		$_ = "](mailto:$in_mailtitle)" . ($1 // '') . "\n";
		undef $in_mailtitle
	} elsif (defined $in_urltitle || defined $in_mailtitle) {
		s/[\r\n]+/ /g
	}

	s/$/  /  if has_lineopt('BRK');
	clr_lineopt()  unless $line_did_set_options;
}

sub reformat_html {
	s#\\f[B3](.+?)\\f[RP1]#<b>$1</b>#g;
	s#\\f[I2](.+?)\\f[RP1]#<i>$1</i>#g;
	s#\\f4(.+?)\\f[RP1]#<b><i>$1</i></b>#g;
	s#^\.B +(.+)#<b>$1</b>#g;
	s#^\.I +(.+)#<i>$1</i>#g;
	s/^\.([BIR])([BIR]) *(.+)/alternating_highlighting($1, $2, $3, 1)/ge;
}

# Strips doublequote enclosure from string tokens, if present.
sub qtok {
	my @result = map{ defined && m/^"(.+)"$/ ? $1 : $_ } @_;
	wantarray ? @result : $result[0]
}

# Extracts all tokens from the input string and returns them in a list.
# Tokens are things enclosed in unescaped doublequotes or any strings without spaces.
sub tokenize { qtok($_[0] =~ m/$re_token/g) }


sub section_slug ($) {
	local $_ = lc shift;
	s/[^\w\d\-_ ]//g;
	s/[ \-]+/-/g;
	$_
}

sub section_anchor ($) { "<a name=\"" . section_slug($_[0]) . "\"></a>" }

sub print_section_title    ($) {
	my $title = strip_html($_[0]);
	my $output = sprintf "\n%s\n\n%s%s\n\n", section_anchor($title), $section_prefix, $title;
	utf8::encode($output);
	print $output
}

sub print_subsection_title ($) {
	my $title = strip_html($_[0]);
	my $output = sprintf "\n%s\n\n%s%s\n\n", section_anchor($title), $subsection_prefix, $title;
	utf8::encode($output);
	print $output
}

sub paste_file (%) {
	my %args = @_;
	return 0 unless -r $args{'file'};

	if ($args{'add_section_title'} && $args{'file'} =~ m/^(?:[a-zA-Z0-9_\-]+\/)*(.+)\.md$/) {
		my $section_title = $1;
		print_section_title $section_title;
	}

	open FH, "< $args{'file'}";
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
	my $do_html = $_[3] // 0;
	my $h = 0;

	# groff concatenates tokens in .B and .I lines with spaces,
	# but tokens in .[BIR][BIR] lines are concatenated WITHOUT spaces.
	# Therefore we have to join('') the tokens here:

	return join '', map {
		my $highlightkey = $hl[$h++ % 2];

		if ($highlightkey eq 'R') {
			$_
		} elsif ($highlightkey eq 'I') {
			($do_html)
				? '<i>' . $_ . '</i>'
				: '_' . $_ . '_'
		} elsif ($highlightkey eq 'B') {
			($do_html)
				? '<b>' . $_ . '</b>'
				: '**' . $_ . '**'
		}
	} @tokens
}

sub titlecase {
	local $_ = $_[0];
	my $re_word = '(\pL[\pL\d\'_]*)';

	# lowercase stop words, keep casing of known words, else titlecase
	s!$re_word!$stopwords{lc $1} ? lc($1) : ($words{lc $1} // ucfirst(lc($1)))!ge;
	# capitalize first word following colon or semicolon
	s/ ( [:;] \s+ ) $re_word /$1\u$2/x;
	# titlecase first word (even a stopword), except if it's a known word
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
nextline()  or die "could not read first line";
m/^.(?:Dd|Dt)\b/  and die "man page is in mdoc format which is not supported";
m/^\.TH\b/  or die "first line does not contain '.TH' macro";
m/^\.TH ($re_token)(?:\s|$)/  or die ".TH line doesn't contain page title";
m/^\.TH ($re_token) ($re_token)(?: ($re_token)(?: ($re_token))?)?/  or die ".TH line doesn't contain man section";

($progname, $mansection, $verdate) = (lc(qtok($1)), qtok($2), qtok($3));
read_version(qtok($4 // ''));

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

# Fake section name 'HEADLINE' can be used
# to paste additional content right after the headline
# (but not before)
if (defined $paste_after_section{'HEADLINE'}) {
	paste_file(%$_)  foreach (@{ $paste_after_section{'HEADLINE'} });
	undef $paste_after_section{'HEADLINE'};
}

if ($version || $verdate) {
	if ($version) {
		print "Version "  if $is_bare_version;
		print $version;
	}
	if ($version && $verdate) {
		print ", ";
	}
	if ($verdate) {
		print $verdate;
	}
	print "\n\n";
}

# skip SYNOPSIS headline
nextline() if (section_title && $is_synopsis);


do {{
	if ($in_rawblock) {
		if (m/^\.(?:fi|SH|cx)/) {
			# code block ends
			$in_rawblock = 0;
			print "</code></pre>\n"  if $code_formatting;
			print "\n"  if m/^\.cx/;
			redo if m/^\.SH/;  # .nf sections can be ended with .SH, but we still need to print the new section title too
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

	} elsif ($in_preblock) {
		if (m/^\.fi/) {
			# preformatted block ends
			$in_preblock = 0;
			$_ = '';
		} else {
			# Add two spaces at EOL to force visible linebreak:
			add_lineopt('BRK');
		}
		reformat_syntax;
		print

	} elsif (section_title) {
		# new section begins
		if (defined $paste_after_section{$prev_section}) {
			paste_file(%$_)  foreach (@{ $paste_after_section{$prev_section} });
			undef $paste_after_section{$prev_section};
		}
		if (defined $paste_before_section{$section}) {
			paste_file(%$_)  foreach (@{ $paste_before_section{$section} });
			undef $paste_before_section{$section};
		}
		print_section_title titlecase($section)

	} elsif (subsection_title) {
		# new subsection begins
		print_subsection_title $subsection

	} elsif (m/^\.ds +(\S{1,2}) +"?(.+)$/) {
		$strings{ $1 } = $2

	} elsif (m/^\.de\b/) {
		# macro definition -- skip completely
		1 while (nextline(1) && ! m/^\.\./);

	} else {
		reformat_syntax;
		print
	}

}} while (nextline(1));


# Paste section which haven't matched anything yet:
# TODO: print warnings -- they probably should have gone somewhere else
foreach (values %paste_before_section)
	{ paste_file(%$_)  foreach (@$_) }
foreach (values %paste_after_section)
	{ paste_file(%$_)  foreach (@$_) }

