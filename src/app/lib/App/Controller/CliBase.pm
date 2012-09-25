package App::Controller::CliBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module::CLIBase';

sub before_dispatch {
	my ($self, $c) = @_;
}

1;

