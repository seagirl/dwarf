package App::Controller::Api::ShowSession;
use Dwarf::Pragma;
use Dwarf::DSL;
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
	if (is_production) {
		return not_found;
	}

	return {
		id       => session->id,
		session  => decode_utf8_recursively(session->dataref),
		cookie   => decode_utf8_recursively(req->cookies)
	};
}

1;
