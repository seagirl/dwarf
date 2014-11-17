package Dwarf::Request;
use Dwarf::Pragma;
use parent 'Plack::Request';
use Encode ();
use Hash::MultiValue;

use Dwarf::Accessor qw/encoding/;

sub _build_encoding { 'utf-8' }

sub new {
	my ($class, $env) = @_;
	my $self = $class->SUPER::new($env);
	return $self;
}

# ------------------------------------------------------------------------- 
# This object returns decoded parameter values by default

sub body_parameters {
	my ($self) = @_;
	$self->{'dwarf.body_parameters'} ||= $self->_decode_parameters($self->SUPER::body_parameters());
}

sub query_parameters {
	my ($self) = @_;
	$self->{'dwarf.query_parameters'} ||= $self->_decode_parameters($self->SUPER::query_parameters());
}

sub _decode_parameters {
	my ($self, $stuff) = @_;

	my $encoding = $self->encoding;
	my @flatten = $stuff->flatten();
	my @decoded;
	while ( my ($k, $v) = splice @flatten, 0, 2 ) {
		push @decoded, Encode::decode($encoding, $k), Encode::decode($encoding, $v);
	}
	return Hash::MultiValue->new(@decoded);
}
sub parameters {
	my $self = shift;

	$self->env->{'dwarf.request.merged'} ||= do {
		my $query = $self->query_parameters;
		my $body  = $self->body_parameters;
		Hash::MultiValue->new( $query->flatten, $body->flatten );
	};
}

# ------------------------------------------------------------------------- 
# raw parameter values are also available.

sub body_parameters_raw {
	shift->SUPER::body_parameters();
}
sub query_parameters_raw {
	shift->SUPER::query_parameters();
}
sub parameters_raw {
	my $self = shift;

	$self->env->{'plack.request.merged'} ||= do {
		my $query = $self->SUPER::query_parameters();
		my $body  = $self->SUPER::body_parameters();
		Hash::MultiValue->new( $query->flatten, $body->flatten );
	};
}
sub param_raw {
	my $self = shift;

	return keys %{ $self->parameters_raw } if @_ == 0;

	my $key = shift;
	return $self->parameters_raw->{$key} unless wantarray;
	return $self->parameters_raw->get_all($key);
}

1;