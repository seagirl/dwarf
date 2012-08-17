#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw/abs_path getcwd/;
use File::Path 'mkpath';
use FindBin;
use Getopt::Long;
use Pod::Usage 'pod2usage';

my $bin = $FindBin::RealBin;

my $opts = { output => getcwd };
GetOptions($opts, 'name=s', 'output=s', 'help');

if (@ARGV) {
	$opts->{name} = $ARGV[0];
	$opts->{output} = $ARGV[1] if $ARGV[1];
}

if (not $opts->{name} or $opts->{help}) {
	pod2usage;
}

my $dst = $opts->{output} . "/" . $opts->{name};

my $src;

for my $a (qw/app sql htdocs/) {
	$src = "$bin/src/$a";
	mkpath $dst unless -d $dst;
	system "cp -rf $src $dst";
	print "created $dst/$a\n";
}

system "find $dst -type f | xargs perl -i -pe 's/<APP_NAME>/$opts->{name}/g'";

=head1 SYNOPSIS

dwarf.pl APP_NAME

=cut

