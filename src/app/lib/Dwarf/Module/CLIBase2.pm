package Dwarf::Module::CLIBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module';

sub init {
	my ($self, $c) = @_;
	$c->not_found if $c->is_production and not $c->is_cli;

	$c->load_plugins(
		'Error' => {
			SNS_LIMIT_ERROR => sub { shift->throw(2001, sprintf("SNS Limit Error: reset at %s", $_[0] || "")) },
			SNS_ERROR       => sub { shift->throw(2002, sprintf("SNS Error: %s", $_[0] || "SNS Error.")) },
			ERROR           => sub { shift->throw(400, sprintf("%s", $_[0] || "Unknown Error.")) },
		},
	);

	$c->add_trigger(ERROR => $self->can('receive_render'));
	$c->add_trigger(SERVER_ERROR => $self->can('receive_server_error'));

	$c->error->autoflush(1);

	$self->type('text/plain; charset=UTF-8');
}

sub receive_error {
	my ($self, $c, $error) = @_;
	return $error;
}

sub receive_server_error {
	my ($self, $c, $error) = @_;
	return $error;
}

1;

