package App::Controller::CliBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module::CliBase';
use Class::Method::Modifiers;

before init => sub {
	my ($self, $c) = @_;
};

1;

