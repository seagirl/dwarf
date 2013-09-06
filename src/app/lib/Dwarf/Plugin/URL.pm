package Dwarf::Plugin::URL;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {
		want_ssl_callback        => sub { my ($c, $host, $path) = @_; $c->redirect("https://$host$path") },
		do_not_want_ssl_callback => sub { my ($c, $host, $path) = @_; $c->redirect("http://$host$path") },
	};

	add_method($c, is_ssl => sub {
		my $self = shift;
		return (($c->env->{HTTPS}//'') eq 'on' or ($c->env->{HTTP_X_FORWARDED_PROTO}//'') eq 'https') ? 1 : 0;
	});

	add_method($c, base_url => sub {
		my $self = shift;
		return $self->is_ssl ? $self->conf('url')->{ssl_base} : $self->conf('url')->{base};
	});

	add_method($c, want_ssl => sub {
		my ($self, $path) = @_;
		$path //= $c->env->{REQUEST_URI}//'';
		if ($self->conf("ssl") and not $self->is_ssl) {
			my $host = $c->env->{HTTP_X_FORWARDED_HOST} || $c->env->{HTTP_HOST};
			$conf->{want_ssl_callback}->($self, $host, $path);
		}
	});

	add_method($c, do_not_want_ssl => sub {
		my ($self, $path) = @_;
		$path //= $c->env->{REQUEST_URI}//'';
		if ($self->is_ssl) {
			my $host = $c->env->{HTTP_X_FORWARDED_HOST} || $c->env->{HTTP_HOST};
			$conf->{do_not_want_ssl_callback}->($self, $host, $path);
		}
	});
}

1;
