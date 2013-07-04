package Dwarf::Plugin::JSON;
use Dwarf::Pragma;
use Dwarf::Util qw/encode_utf8 add_method/;
use JSON;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	my $package = __PACKAGE__;
	$c->{$package} = JSON->new();
	$c->{$package}->pretty(1) if defined $conf->{pretty};
	$c->{$package}->convert_blessed if defined $conf->{convert_blessed};
	$c->{$package}->utf8;

	add_method($c, json => sub {
		my $self = shift;
		if (@_ == 1) {
			$self->{$package} = $_[0];
		}
		return $self->{$package};
	});

	add_method($c, decode_json => sub {
		my ($self, $data) = @_;
		my $decoded = eval { $c->{$package}->decode($data) };

		if ($@) {
			$@ = undef;
			return $data;
		}

		return $decoded;
	});

	add_method($c, encode_json => sub {
		my ($self, $data) = @_;
		my $encoded = eval { $c->{$package}->encode($data) };

		if ($@) {
			$@ = undef;
			return $data;
		}

		return $encoded;
	});

	$c->add_trigger(AFTER_DISPATCH => sub {
		my ($self, $res) = @_;
		return unless ref $res->body;

		if ($res->content_type =~ /(application|text)\/json/) {
			$self->call_trigger(BEFORE_RENDER => $self->handler, $self, $res->body);
			my $encoded = $self->encode_json($res->body);

			my $callback = $c->param('callback');
			if (defined $callback and $callback =~ /^[0-9a-zA-Z_]+$/) {
				$encoded = $callback . "(" . $encoded . ")";
				$res->content_type('text/javascript');
			}
			
			$self->call_trigger(AFTER_RENDER => $self->handler, $self, \$encoded);
			$res->body(encode_utf8($encoded));
		}
	});
}

1;
