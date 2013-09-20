package Dwarf::Pragma;
use strict;
use warnings;
use boolean ();

my $utf8;
my $feature;

sub import {
	my ($class, %args) = @_;

	$utf8 = 1 unless defined $args{utf8};
	$feature = "5.10" unless defined $args{feature};

	warnings->import;
	strict->import;
	boolean->import;
	boolean->export_to_level(1);

	if ($utf8) {
		utf8->import;
	}

	if ($feature ne 'legacy') {
		require 'feature.pm';
		feature->import(":" . $feature);
	}
}

sub unimport {
	warnings->unimport;
	strict->unimport;
	boolean->unimport;

	if ($utf8) {
		utf8->unimport;
	}

	if ($feature ne 'legacy') {
		feature->unimport;
	}
}

1;
