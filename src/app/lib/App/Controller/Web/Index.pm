package App::Controller::Web::Index;
use Dwarf::Pragma;
use parent 'App::Controller::WebBase';

sub before {
	my ($self, $c) = @_;
}

sub get {
	my ($self, $c) = @_;
	return $c->render('index.html');
}

1;
