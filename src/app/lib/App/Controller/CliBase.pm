package App::Controller::CliBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module::CLIBase';

sub will_dispatch {
	my ($self, $c) = @_;
}

1;

