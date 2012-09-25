package App::Controller::Api::ShowSession;
use Dwarf::Pragma;
use parent 'App::Controller::ApiBase';
use Dwarf::Util qw/decode_utf8_recursively/;
use Class::Method::Modifiers;
use Encode ();

after will_dispatch => sub {
	my ($self, $c) = @_;
};

sub get {
	my ($self, $c) = @_;

	# 本番では動かないように
	if ($c->is_production) {
		return $c->not_found;
	}

	my $session = $self->session->dataref;
	my $cookie  = $self->c->req->cookies;

	return {
		id       => $self->session->id,
		session  => decode_utf8_recursively($session),
		cookie   => decode_utf8_recursively($cookie)
	};
}

1;
