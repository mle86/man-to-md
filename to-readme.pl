#!/usr/bin/perl -W

use Getopt::Long qw(:config no_getopt_compat bundling);
use File::Basename qw(dirname basename);
chdir dirname($0);

use constant {
	PROGNAME => basename($0),
	PROGVER  => '0.9',
	PROGDATE => '2016-05',

};

my ($section, $prev_section);
my ($is_synopsis, $in_list);
my ($progname, $mansection, $version, $verdate);
my $headline_prefix = '# ';
my $section_prefix  = '# ';

my %paste_after_section  = ( );  # ('section' => ['filename'...], ...)
my %paste_before_section = ( );

#require 'dumpvar.pl';

sub Syntax (;$) {
	printf STDERR <<EOT, PROGNAME;
syntax: %s [OPTIONS] < input.nroff > output.md
Options:
  -p, --paste-after SECTION FILENAME   Pastes the contents of FILENAME
                                       after the input SECTION.
  -P, --paste-before SECTION FILENAME  Pastes the contents of FILENAME
                                       right before the input SECTION.
  -h, --help     Show program help
  -V, --version  Show program version

EOT
	exit ($_[0] // 0);
}

sub Version () {
	printf <<EOT, PROGNAME, PROGVER, PROGDATE;
%s v%s
Written by Maximilian Eul <maximilian\@eul.cc>, %s.

EOT
	exit;
}

GetOptions(
	'p|paste-after=s@'	=> sub{ add_paste_file('after', split /:/, $_[1]) },
	'P|paste-before=s@'	=> sub{ add_paste_file('before', split /:/, $_[1]) },
	'h|help'		=> sub{ Syntax 0 },
	'V|version'		=> sub{ Version },
);

sub add_paste_file ($$$) {
	my ($op, $section, $filename) = @_;
	die "file not readable: $filename"  unless (-f $filename && -r $filename);
	my $addto = ($op eq 'after') ? \%paste_after_section : \%paste_before_section;
	push @{ $addto->{$section} }, $filename;
}

sub output_filter {
	my $pid = open(STDOUT, '|-');
	return  if $pid > 0;
	die "cannot fork: $!"  unless defined $pid;

	local $/;
	local $_ = <STDIN>;

	# merge code blocks:
	s/```\n```/ /g;

	# URLs:
	my $re_urlprefix = '(?:https?|s?ftp:|www)';
	s/^(.+)(?:$)\n^(?:[<\[\(]\*{0,2}(${re_urlprefix}.+?)\*{0,2}[>\]\)])([\s,;\.\?!]*)$/[$1]($2)$3/gm;

	print;
	exit;
}
output_filter();

sub nextline {
	my $keep_blanklines = $_[0] // 0;
	do { $_ = <> } while (defined($_) && !$keep_blanklines && m/^\s*$/);
	defined $_
}

sub line_empty { m/^\s*$/ }

sub strip_highlighting { s/(?:^\.[BIR]{1,2} |\\f[BIR])//g }

sub section_title {
	# If the current line contains a section title,
	# this function sets $section, $prev_section, and the $is_... flags accordingly
	# and returns true.
	return 0 unless m/^\.SH +(.+)$/m;

	$in_list = 0;
	$prev_section = $section // '';
	$section = $1;

	$is_synopsis = ($section eq 'SYNTAX' || $section eq 'SYNOPSIS');
	1
}

sub reformat_syntax {
	if (m/^\.br/) {
		$_ = ($in_list) ? "" : "\n";
		return
	}

	if ($is_synopsis && !line_empty()) {
		# only code here
		chomp;
		strip_highlighting();
		$_ = "\`\`\`$_\`\`\`\n";
		return
	}

	# bold and italics:
	s/\\fB(.+?)\\fR/**$1**/g; s/^\.B +(.+)/**$1**/g;
	s/\\fI(.+?)\\fR/*$1*/g;   s/^\.I +(.+)/*$1*/g;
	s/^\.([BIR])([BIR]) *(.+)/alternating_highlighting($1, $2, $3)/ge;
	strip_highlighting();

	# other special characters:
	s/\\(.)/$1/g;

	if ($section eq 'AUTHOR') {
		# convert e-mail address to link:
		s/\b(\w[\w\-_\.\+]*@[\w\-_\+\.]+?\.[\w\-]+)\b/[$1](mailto:$1)/u;
	}

	# lists and definition lists:
	if (m/^\.IP/ || m/^\.TP/) {
		$_ = "* ";  # no trailing break here
		if (!$in_list) { $_ = "\n$_" }
		$in_list = 2;
	} elsif (m/^\.LP/) {
		$_ = "\n";  # one blank line
		$in_list = 0;
	} elsif ($in_list) {
		s/^/  / if $in_list == 1;
		$in_list = 1;
	}
}

sub qtok ($) { ($_[0] =~ m/^"(.+)"$/) ? $1 : $_[0] }

sub print_section_title ($) { print "\n$section_prefix$_[0]\n\n" }

sub paste_file {
	my ($filename, $section_title) = @_;
	return 0 unless -r $filename;

	open FH, "< $filename";
	local $/;
	my $content = <FH>;
	close FH;

	print_section_title $section_title;
	$content =~ s/\s+$//;
	print "$content\n";

	$prev_section = uc $section_title;
	1
}

sub alternating_highlighting {
	my @hl = @_[0, 1];
	my @tokens = split /\s+/, $_[2];
	my $h = 0;

	return join '', map {
		my $highlightkey = $hl[$h];
		$h++, $h %= 2;

		if ($highlightkey eq 'R') {
			$_
		} elsif ($highlightkey eq 'I') {
			'*' . $_ . '*'
		} elsif ($highlightkey eq 'B') {
			'**' . $_ . '**'
		}
	} @tokens
}

##############################

# eat first line, extract progname, version, and man section
my $re_token = '(?:"[^"]*"|[^"\s]+)(?=\s|$)';
nextline()
	and m/^\.TH $re_token ($re_token) ($re_token) ($re_token)/
	and (($mansection, $verdate) = (qtok $1, qtok $2))
	and qtok($3) =~ m/^(\w[\w\-_\.]*) v? ?(\d[\w\.\-\+]*)$/
	and (($progname, $version) = ($1, $2))
	or die "could not parse first line";

# skip NAME headline, extract description 
if (nextline() && section_title() && $section eq 'NAME') {
	if (nextline() && m/ \\?- +(.+)$/) {
		$description = $1;
		nextline();
	}
}

print "[//]: # (This file was autogenerated from the man page with 'make README.md')\n\n";
print "$headline_prefix$progname($mansection)";
print " - $description"  if defined $description;
print "\n\n";

print "Version $version, $verdate\n\n" if ($version && $verdate);

# skip SYNOPSIS headline
nextline() if (section_title && $is_synopsis);

do {
	if (section_title) {
		# new section begins
		if (defined $paste_after_section{$prev_section}) {
			paste_file($_)  foreach (@{ $paste_after_section{$prev_section} });
			undef $paste_after_section{$section};
		}
		if (defined $paste_before_section{$section}) {
			paste_file($_)  foreach (@{ $paste_before_section{$section} });
			undef $paste_before_section{$section};
		}
		print_section_title ucfirst(lc $section)
	} elsif (m/^\.nf/) {
		# raw block
		while (nextline(1) && !m/^\.fi/) { strip_highlighting; print "    $_" }
	} else {
		reformat_syntax;
		print
	}
} while (nextline(1));

foreach (values %paste_before_section)
	{ paste_file($_)  foreach (@$_) }
foreach (values %paste_after_section)
	{ paste_file($_)  foreach (@$_) }

