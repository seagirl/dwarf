package Dwarf;
use Dwarf::Pragma;
use Dwarf::Error;
use Dwarf::Message;
use Dwarf::Request;
use Dwarf::Response;
use Dwarf::Trigger;
use Dwarf::Util qw/capitalize filename load_class/;
use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

our $VERSION = '0.9.0';

use constant {
	BEFORE_DISPATCH    => 'before_dispatch',
	DISPATCHING        => 'dispatching',
	AFTER_DISPATCH     => 'after_dispatch',
	FINISH_DISPATCHING => 'finish_dispatching',
	ERROR              => 'error',
	NOT_FOUND          => 'not_found',
	SERVER_ERROR       => 'server_error',
};

use Dwarf::Accessor {
	ro => [qw/namespace base_dir env config error request response handler state/],
	rw => [qw/stash request_handler_prefix request_handler_method/],
};

sub _build_config {
	my $self = shift;
	$self->{config} ||= do {
		my $class = join '::', $self->namespace, 'Config';
		$class .= '::' . ucfirst $self->config_name if $self->can('config_name');
		load_class($class);
		return $class->new(context => $self);
	};
}

sub _build_error {
	my $self = shift;
	$self->{error} ||= Dwarf::Error->new;
}

sub _build_request {
	my $self = shift;
	$self->{request} ||= do {
		my $req = Dwarf::Request->new($self->env);

		if (defined $req->param('debug')) {
			require CGI::Carp;
			CGI::Carp->import('fatalsToBrowser');
		}

		$req;
	};
}

sub _build_response {
	my $self = shift;
	$self->{response} ||= do {
		my $res = Dwarf::Response->new(200);
		$res->content_type('text/plain');
		$res;
	};
}

sub new {
	my $invocant = shift;
	my $class = ref $invocant || $invocant;
	my $self = bless { @_ }, $class;
	$self->init;
	return $self;
}

sub init {
	my $self = shift;

	$self->{env}                    ||= {};
	$self->{namespace}              ||= ref $self;
	$self->{base_dir}               ||= abs_path(catfile(dirname(filename($self)), '..'));
	$self->{state}                  ||= BEFORE_DISPATCH;
	$self->{stash}                  ||= {};
	$self->{request_handler_prefix} ||= join '::', $self->namespace, 'Controller';
	$self->{request_handler_method} ||= 'any';

	$self->setup;
}

sub setup {}

sub is_production { 1 }

sub is_cli {
	my $self = shift;
	my $server_software = $self->env->{SERVER_SOFTWARE} || '';
	return $server_software eq 'Plack::Handler::CLI';
}

sub param  { shift->request->param(@_) }
sub method { shift->request->method(@_) }
sub req    { shift->request(@_) }
sub res    { shift->response(@_) }
sub status { shift->res->status(@_) }
sub type   { shift->res->content_type(@_) }
sub body   { shift->res->body(@_) }

sub conf {
	my $self = shift;
	return $self->config->get(@_) if @_ == 1;
	return $self->config->set(@_);
}

sub to_psgi {
	my $self = shift;
	$self->call_before_trigger;
	$self->dispatch(@_);
	$self->call_after_trigger;
	return $self->response->finalize;
}

sub finish {
	my ($self, $body) = @_;
	my $message = Dwarf::Message->new(
		name => FINISH_DISPATCHING,
		data => $body,
	);
	die $message;
}

sub not_found {
	my $self = shift;
	$self->response->status(404);
	$self->finish("Not Found");
	return;
}

sub redirect {
	my ($self, $to) = @_;
	$self->response->redirect($to);
	$self->finish;
	return;
}

sub dispatch {
	my $self = shift;

	eval {
		eval {
			my ($class, $ext) = $self->find_class($self->req->path_info);
			return $self->body($self->not_found) unless $class;
			Dwarf::Util::load_class($class);

			$self->{handler} = $self->handler->new(context => $self);

			my $method = $self->find_method;
			return $self->body($self->not_found) unless $method;

			$handler->init($self);
			my $body = $handler->$method($self, @_);

			$self->body($body);
		}
		if ($@) {
			my $error = $@;
			$@ = undef;

			if ($error =~ /Can't locate /) {
				eval {
					return $self->body($self->not_found)
				};
				if ($@) {
					$error = $@;
					$@ = undef;
				}
			}

			if (ref $error eq 'Dwarf::Error') {
				return $self->handle_error($error);
			}

			die $error;
		}
	};
	if ($@) {
		my $error = $@;
		$@ = undef;

		if (ref $error eq 'Dwarf::Message') {
			if ($error->name eq FINISH_DISPATCHING) {
				return $self->body($error->data);
			}
		}

		return $self->handle_server_error($error);
	}
}

sub handle_error {
	my ($self, $error) = @_;

	my @code = $self->get_trigger_code('ERROR');
	for my $code (@code) {
		my $body = $code->($self->_make_args($error));
		next unless $body;
		return $self->body($body);
	}

	$self->recive_error($error);
}

sub handle_server_error {
	my ($self, $error) = @_;

	my @code = $self->get_trigger_code('SERVER_ERROR');
	for my $code (@code) {
		my $body = $code->($self->_make_args($error));
		next unless $body;
		return $self->body($body);
	}

	$self->recive_server_error($error);
}

sub recive_error { die $_[1] }
sub recive_server_error { die $_[1] }

sub find_class {
	my ($self, $path, $prefix) = @_;
	return if not defined $path or $path eq '';

	$path =~ s|^/||;
	$path =~ s/\.(.*)$//;
	my $ext = $1;

	my $class = join '::', map { capitalize($_) } grep { $_ ne '' } split '\/', $path;

	$prefix ||= $self->request_handler_prefix;

	if (defined $prefix and $prefix ne '') {
		if ($class !~ /^$prefix/) {
			$class = join '::', $prefix, $class;
		}
	}

	return ($class, $ext);
}

sub find_method {
	my ($self) = @_;
	my $request_method = $self->param('method') || $self->method;
	$request_method = lc $request_method if defined $request_method;
	return unless $request_method =~ /^(get|post|put|delete)$/;
	return $handler->can($request_method)
		|| $handler->can($self->request_handler_method);
}

sub call_before_trigger {
	my $self = shift;
	if ($self->state eq BEFORE_DISPATCH) {
		$self->call_trigger(BEFORE_DISPATCH => $self, $self->request);
		$self->{state} = DISPATCHING;
	}
}

sub call_after_trigger {
	my $self = shift;
	if ($self->state eq DISPATCHING) {
		$self->call_trigger(AFTER_DISPATCH => $self, $self->response);
		$self->{state} = AFTER_DISPATCH;
	}
}

sub load_plugins {
	my ($class, %args) = @_;
	while (my ($module, $conf) = each %args) {
		$class->load_plugin($module, $conf);
	}
}

sub load_plugin {
	my ($class, $module, $conf) = @_;
	$module = load_class($module, 'Dwarf::Plugin');
	$module->init($class, $conf);
}

sub _make_args {
	my $self = shift;
	my @args;
	push @args, $self->handler if defined $self->handler;
	push @args, $self;
	push @args, @_;
	return @args;
}

1;
