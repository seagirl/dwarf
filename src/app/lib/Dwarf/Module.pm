package Dwarf::Module;
use Dwarf::Pragma;
use Dwarf::Module::DSL;
use Dwarf::Util 'load_class';

use Dwarf::Accessor {
	ro => [qw/context dsl/],
	rw => [qw/prefix/]
};

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	$self->dsl->export_symbols($class, $self);
	return $self;
}

sub init {}

sub _build_prefix { shift->context->namespace . '::Model' }
sub _build_dsl { Dwarf::Module::DSL->new(context => shift->context) }

sub on_error {}

1;
