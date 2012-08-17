package Dwarf::Module;
use Dwarf::Pragma;
use Dwarf::Util 'load_class';

use Dwarf::Accessor {
	ro => [qw/context/],
	rw => [qw/prefix/]
};

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	return $self;
}

sub init {}

sub c        { shift->context }
sub m        { shift->model(@_) }
sub param    { shift->c->param(@_) }
sub request  { shift->c->request(@_) }
sub req      { shift->c->request(@_) }
sub response { shift->c->response(@_) }
sub res      { shift->c->response(@_) }
sub conf     { shift->c->conf(@_) }
sub db       { shift->c->db(@_) }
sub session  { shift->c->session(@_) }
sub error    { shift->c->error(@_) }
sub status   { shift->c->res->status(@_) }
sub type     { shift->c->res->content_type(@_) }
sub body     { shift->res->body(@_) }

sub _build_prefix  {
	my $self = shift;
	$self->{prefix} ||= $self->c->namespace . '::Model';
}

sub models { shift->{models} ||= {} }

sub model {
	my $self = shift;
	my $package = shift;
	$self->models->{$package} ||= $self->create_model($package, @_);
}

sub create_model {
	my $self = shift;
	my $package = shift;

	die "package name must be specified to create model."
		unless defined $package;

	my $prefix = $self->prefix;
	unless ($package =~ m/^$prefix/) {
		$package = $prefix . '::' . $package;
	}

	load_class($package);
	my $model = $package->new(context => $self->context, @_);
	$model->init($self->context);
	return $model;
}

sub on_error {}

1;
