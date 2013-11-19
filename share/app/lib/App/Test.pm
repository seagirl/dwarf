package App::Test;
use Dwarf::Pragma;
use parent 'Exporter';
use Dwarf::Test;
use JSON;
use Plack::Test;
use Test::More;
use App;

our @EXPORT = qw/res_ok res_not_ok/;

sub import {
	my ($pkg) = @_;
	Dwarf::Pragma->import();
	Test::More->import();
	Test::More->export_to_level(1);
	Plack::Test->import();
	Plack::Test->export_to_level(1);
	Plack::Test->import();
	Dwarf::Test->export_to_level(1);
	Dwarf::Test->import();
	App::Test->export_to_level(1);
}

use Dwarf::Accessor qw/context test/;

sub c { $_[0]->context }

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = bless {}, $class;
	$self->{context} = App->new;
	$self->{test} = [ @_ ];
	return $self;
}

sub run {
	my $self = shift;
	test_psgi app => $self->app, client => $self->client;
	done_testing;
}

sub app {
	my $self = shift;
	return sub {
		my $env = shift;
		$ENV{HTTP_HOST} ||= $env->{HTTP_HOST} = 'localhost';
		$self->{context} = App->new(env => $env);
		$self->c->to_psgi;
	};
}

sub client {
	my $self = shift;
	return sub {
		my $cb = shift;
		for my $t (@{ $self->test }) {
			$t->($self->c, $cb);
		}	
	};
};

sub res_ok {
	my ($method, $protocol, $cb, $path, @args) = @_;
	my $uri = URI->new($path);
	$uri->query_form($args[0]) if $method =~ /^(get|delete)$/;
	$method .= '_ok' if $method !~ /_ok$/ and $method !~ /_redirect/;
	$method = 'Dwarf::Test::' . $method;
	$method = \&$method;
	$ENV{HTTPS} = $protocol eq 'https' ? 'on' : 'off';
	my $res = $method->($cb, $uri->as_string, @args);
	return _check_response($res);
}

sub _check_response {
	my ($res) = @_;
	if ($res->code == 200 and $res->header('Content-Type') =~ /json/) {
		my $content = eval { decode_json($res->content) };
		if ($@) {
			warn $content;
		}
		$res->content($content);
		return $res;
	} elsif ($res->code == 302) {
		return $res;
	}
	return $res;
}

1;
