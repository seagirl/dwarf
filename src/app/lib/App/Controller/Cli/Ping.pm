package App::Controller::Cli::Ping;
use Dwarf::Pragma;
use parent 'App::Controller::CliBase';

sub any {
	my ($self, $c) = @_;
	return 'It works on ' . $c->hostname . ':' . $c->base_dir . ' (' . $c->config_name. ')';
}

1;

