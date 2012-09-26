package App::Test;
use Dwarf::Pragma;
use Dwarf::Test;
use Plack::Test;
use Test::More;
use App;

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

1;
