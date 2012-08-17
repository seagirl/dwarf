package Dwarf::TempBuffer::Backend;
use strict;
use warnings;
use Dwarf::Util qw(load_class);
use FileHandle;

our $MaxMemoryBufferSize = 1024 * 1024;

sub new {
	my($class, $length) = @_;

	my $backend;
	if ($MaxMemoryBufferSize < 0) {
		$backend = "PerlIO";
	} elsif ($MaxMemoryBufferSize == 0) {
		$backend = "File";
	} elsif (!$length) {
		$backend = "Auto";
	} elsif ($length > $MaxMemoryBufferSize) {
		$backend = "File";
	} else {
		$backend = "PerlIO";
	}

	$class->create($backend, $length, $MaxMemoryBufferSize);
}

sub create {
	my($class, $backend, $length, $max) = @_;
	my $pkg = join '::', $class, $backend;
	load_class($pkg);
	$pkg->new($length, $max);
}

sub print;
sub rewind;
sub size;

1;
