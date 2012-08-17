package Dwarf::Request::Upload;
use strict;
use warnings;
use Carp ();

sub new {
	my($class, %args) = @_;
	bless {
		headers  => $args{headers},
		tempname => $args{tempname},
		size     => $args{size},
		filename => $args{filename},
	}, $class;
}

sub filename { $_[0]->{filename} }
sub headers  { $_[0]->{headers} }
sub size     { $_[0]->{size} }
sub tempname { $_[0]->{tempname} }
sub path     { $_[0]->{tempname} }

sub content_type { shift->{headers}->content_type(@_) }
sub type { shift->content_type(@_) }

sub basename {
	my $self = shift;
	unless (defined $self->{basename}) {
		require File::Spec::Unix;
		my $basename = $self->{filename};
		$basename =~ s|\\|/|g;
		$basename = ( File::Spec::Unix->splitpath($basename) )[2];
		$basename =~ s|[^\w\.-]+|_|g;
		$self->{basename} = $basename;
	}
	$self->{basename};
}

1;