package Dwarf::Plugin::XML::Simple;
use strict;
use warnings;
use Dwarf::Util qw/encode_utf8 add_method/;
use XML::Simple;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	my $package = __PACKAGE__;
	$c->{$package} = XML::Simple->new(%$conf);

	add_method($c, xml => sub {
		my $self = shift;
		if (@_ == 1) {
			$self->{$package} = $_[0];
		}
		return $self->{$package};
	});

	add_method($c, decode_xml => sub {
		my ($self, $data, @opts) = @_;
		return $c->{$package}->XMLin($data, @opts);
	});

	add_method($c, encode_xml => sub {
		my ($self, $data, @opts) = @_;
		return $c->{$package}->XMLout($data, @opts);
	});

	$c->add_trigger(AFTER_DISPATCH => sub {
		my ($self, $res) = @_;
		return unless ref $res->body;

		if ($res->content_type =~ /(application|text)\/xml/) {
			$self->call_trigger(BEFORE_RENDER => $self->handler, $self, $res->body);
			my $encoded = $self->encode_xml($res->body);
			$self->call_trigger(AFTER_RENDER => $self->handler, $self, \$encoded);
			$res->body(encode_utf8($encoded));
		}
	});
}

1;
