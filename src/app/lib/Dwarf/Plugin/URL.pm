package Dwarf::Plugin::URL;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	add_method($c, is_ssl => sub {
		my $self = shift;
		return (($ENV{HTTPS}//'') eq 'on' or ($ENV{HTTP_X_FORWARDED_PROTO}//'') eq 'https') ? 1 : 0;
	});

	add_method($c, base_url => sub {
		my $self = shift;
		return $self->is_ssl ? $self->conf('url')->{ssl_base} : $self->conf('url')->{base};
	});

	add_method($c, want_ssl => sub {
		my ($self, $path) = @_;
		$path //= $ENV{REQUEST_URI}//'';
		if ($self->conf("ssl") and not $self->is_ssl) {
			my $host = $ENV{HTTP_X_FORWARDED_HOST} || $ENV{HTTP_HOST};
			$self->redirect("https://$host$path");
		}
	});

	add_method($c, do_not_want_ssl => sub {
		my ($self, $path) = @_;
		$path //= $ENV{REQUEST_URI}//'';
		if ($self->is_ssl) {
			my $host = $ENV{HTTP_X_FORWARDED_HOST} || $ENV{HTTP_HOST};
			$self->redirect("http://$host$path");
		}
	});
}

1;
