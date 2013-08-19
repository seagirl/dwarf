package Dwarf::Module::DSL;
use Dwarf::Pragma;
use Dwarf::Util 'load_class';

use Dwarf::Accessor {
	ro => [qw/context/],
	rw => [qw/prefix/]
};

our @FUNC = qw/
	self app c model
	conf db error e
	session param parameters
	request req method
	response res status type body
	not_found finish redirect
	is_cli is_production
	load_plugin load_plugins
	render
/;

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	return $self;
}

sub init {}

sub _build_prefix  {
	my $self = shift;
	$self->{prefix} ||= $self->c->namespace . '::Model';
}

sub app           { shift->context }
sub c             { shift->context }
sub m             { shift->model(@_) }
sub conf          { shift->c->conf(@_) }
sub db            { shift->c->db(@_) }
sub error         { shift->c->error(@_) }
sub e             { shift->c->error(@_) }

sub session       { shift->c->session(@_) }
sub param         { shift->c->request->param(@_) }
sub parameters    { shift->c->request->parameters(@_) }
sub request       { shift->c->request(@_) }
sub req           { shift->c->request(@_) }
sub method        { shift->c->method(@_) }
sub response      { shift->c->response(@_) }
sub res           { shift->c->response(@_) }
sub status        { shift->c->status(@_) }
sub type          { shift->c->type(@_) }
sub header        { shift->c->header(@_) }
sub body          { shift->c->body(@_) }

sub not_found     { shift->c->not_found(@_) }
sub finish        { shift->c->finish(@_) }
sub redirect      { shift->c->redirect(@_) }
sub is_cli        { shift->c->is_cli(@_) }
sub is_production { shift->c->is_production(@_) }
sub load_plugin   { shift->c->load_plugin(@_) }
sub load_plugins  { shift->c->load_plugins(@_) }
sub render        { shift->c->render(@_) }

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

sub export_symbols {
	my ($self, $to, $module) = @_;

	no strict 'refs';
	no warnings 'redefine';
	my $super = *{"${to}::ISA"}{ARRAY};
	if ($super && $super->[0]) {
		$self->export_symbols($super->[0], $module);
	}

	for my $f (@FUNC) {
		*{"${to}::${f}"} = sub {
			# OO インターフェース　で呼ばれた時対策
			shift if defined $_[0] and $_[0] eq $module;
			return $module if $f eq 'self';
			$self->$f(@_)
		};
	}
}

1;
