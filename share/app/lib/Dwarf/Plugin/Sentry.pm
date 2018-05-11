package Dwarf::Plugin::Sentry;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;
use Carp;
use Devel::StackTrace;
use Sentry::Raven;

# load_plugins(Sentry => { dsn => XXXX });
# $c->call_sentry($error);

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	add_method($c, call_sentry => sub {
		my ($self, $message) = @_;
		die "dsn must be specified." unless $conf->{dsn};
		
		chomp($message);

		my $stacktrace = Devel::StackTrace->new(skip_frames => 1);
		my $sentry = Sentry::Raven->new(sentry_dsn => $conf->{dsn});

		my %stacktrace_context = $sentry->stacktrace_context($sentry->_get_frames_from_devel_stacktrace($stacktrace));

		my $req = $self->request;
		my $hdr = [ map { my $k = $_; map { { $k => $_ } } $req->headers->header($_) } $req->headers->header_field_names ];
		my %env = %{ $req->env };
		foreach (keys %env) {
			delete $env{$_} if (not /^HTTP_/);
		}

		my %rc = $sentry->request_context(
			$req->request_uri,
			method  => $req->method,
			data    => substr($req->content, 0, 2048),
			cookies => $env{HTTP_COOKIE},
			headers => $hdr,
			env     => \%env
		);
		
		my %context = (
			culprit => $0,
			$sentry->exception_context($message),
			%stacktrace_context,
			%rc,
		);

		my $event_id = $sentry->capture_message($message, %context);

		if (!defined($event_id)) {
			die "failed to submit event to sentry service:\n" . $c->dump($sentry->_construct_message_event($message, %context));
		}
	});
}

1;
