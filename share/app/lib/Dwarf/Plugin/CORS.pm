package Dwarf::Plugin::CORS;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};
	die "conf must be HASH" unless ref $conf eq 'HASH';

	$conf->{origin}      ||= '*';
	$conf->{headers}     ||= [qw/X-Requested-With/];
	$conf->{credentials} ||= 0;
	$conf->{maxage}      ||= 7200;

	$c->add_trigger(AFTER_DISPATCH => sub {
		my ($self, $res) = @_;
		
		$c->header('Access-Control-Allow-Origin' => $conf->{origin});
		$c->header('Access-Control-Allow-Headers' => join ',', @{ $conf->{headers} });

		if ($conf->{credentials}) {
			$c->header('Access-Control-Allow-Credentials' => 'true');
		}

		if ($c->method eq 'OPTIONS' and $conf->{maxage}) {
			$c->header('Access-Control-Max-Age' => $conf->{maxage});
		}
	});
}

1;
