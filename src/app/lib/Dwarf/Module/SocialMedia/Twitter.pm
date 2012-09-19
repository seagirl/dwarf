package Dwarf::Module::SocialMedia::Twitter;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use AnyEvent;
use DateTime;
use DateTime::Format::HTTP;
use Digest::SHA qw//;
use Encode qw/encode_utf8/;
use HTTP::Request::Common;
use HTTP::Response;
use JSON;
use LWP::UserAgent;
use Net::OAuth;
use S2Factory::HTTPClient;

use Dwarf::Accessor qw/
	ua ua_async urls
	key secret
	request_token request_token_secret
	access_token access_token_secret
	user_id screen_name name profile_image
	on_error
/;

$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

sub init {
	my $self = shift;
	my $c = $self->c;

	$self->{ua}       ||= LWP::UserAgent->new;
	$self->{ua_async} ||= S2Factory::HTTPClient->new;

	$self->{urls} ||= {
		api            => 'http://api.twitter.com/1',
		upload_api     => 'https://upload.twitter.com/1',
		request_token  => 'https://twitter.com/oauth/request_token',
		authentication => 'https://twitter.com/oauth/authenticate',
 		authorization  => 'https://twitter.com/oauth/authorize',
		access_token   => 'https://twitter.com/oauth/access_token',
	};

	$self->{on_error} ||= sub { die @_ };
}

sub _build_screen_name {
	my $self = shift;
	$self->init_user unless defined $self->{screen_name};
	return $self->{screen_name};
}

sub _build_name {
	my $self = shift;
	$self->init_user unless defined $self->{name};
	return $self->{name};
}

sub _build_profile_image {
	my $self = shift;
	$self->init_user unless defined $self->{profile_image};
	return $self->{profile_image};
}

sub init_user {
	my $self = shift;
	my $user = $self->show_user;
	$self->{screen_name}   = $user->{screen_name};
	$self->{name}          = encode_utf8($user->{name});
	$self->{profile_image} = encode_utf8($user->{profile_image_url});
}

sub authorized {
	my ($self, $will_die) = @_;
	$will_die ||= 1;
	my $authorized = defined $self->access_token && defined $self->access_token_secret;
	if ($will_die && !$authorized) {
		$self->on_error("Unauthorized");
	}
	return $authorized;
}

sub is_login {
	my ($self, $check_connection) = @_;

	return 0 unless $self->authorized(0);
	return 1 unless $check_connection;

	my $data = eval {
		$self->request(
			'account/verify_credentials',
			'GET'
		)
	};
	if ($@) {
		warn $@;
	}

	my $is_login = 0;

	if (ref $data eq 'HASH') {
		$is_login = 1;
		$self->{user_id}       = $data->{id};
		$self->{screen_name}   = $data->{screen_name};
		$self->{name}          = encode_utf8($data->{name});
		$self->{profile_image} = encode_utf8($data->{profile_image_url});
	}

	return $is_login;
}

sub publish {
	my ($self, $message) = @_;
	$self->request('statuses/update', 'POST', { status => $message });
}

sub reply {
	my ($self, $in_reply_to_status_id, $message, $screen_name) = @_;
	$message = "@" . $screen_name . " " . $message if defined $screen_name;
	$self->request('statuses/update', 'POST', {
		status                => $message,
		in_reply_to_status_id => $in_reply_to_status_id,
	});
}

sub upload {
	my ($self, $src, $message) = @_;

	my $url = $self->urls->{upload_api} . '/statuses/update_with_media.json';

	my $oauth = Net::OAuth->request('protected resource')->new(
		version          => '1.0',
		request_url      => $url,
		request_method   => 'POST',
		token            => $self->access_token,
		token_secret     => $self->access_token_secret,
		consumer_key     => $self->key,
		consumer_secret  => $self->secret,
		signature_method => 'HMAC-SHA1',
		timestamp        => time,
		nonce            => Digest::SHA::sha1_base64(time . $$ . rand),
	);
	$oauth->sign;

	my $req = POST($url,
		Content_type  => 'multipart/form-data',
		Authorization => $oauth->to_authorization_header,
		Content       => [
			status    => $message,
			'media[]' => [ $src ]
		],
	);
	my $res = $self->ua->request($req);

	return $self->validate($res);
}

sub send_dm {
	my ($self, $id, $text) = @_;
	$self->request('direct_messages/new', 'POST', {
		user_id => $id,
		text    => $text,
	});
}

sub follow {
	my ($self, $target_screen_name) = @_;
	return $self->request('friendships/create', 'POST', {
		screen_name => $target_screen_name
	});
}

sub is_following {
	my ($self, $target_screen_name) = @_;
	my $data = $self->request('friendships/show', 'GET', {
		source_id          => $self->user_id,
		target_screen_name => $target_screen_name,
	});
	return $data->{relationship}->{source}->{following} ? 1 : 0;
}

sub get_rate_limit_status {
	my ($self) = @_;
	return $self->request('account/rate_limit_status', 'GET');
}

sub show_user {
	my ($self, $id) = @_;
	$id ||= $self->user_id;
	my $data = $self->request('users/lookup', 'POST', { user_id => $id });
	if (ref $data eq 'ARRAY') {
		return $data->[0];
	}
}

sub get_timeline {
	my ($self, $id, $data) = @_;
	$id ||= $self->user_id;
	$data ||= {};
	$data->{uid} = $id;
	return $self->request('statuses/user_timeline', 'GET', $data);
}

sub get_mentions {
	my ($self, $id, $data) = @_;
	$id ||= $self->user_id;
	$data ||= {};
	$data->{uid} = $id;
	my $res = $self->request('statuses/mentions', 'GET', $data);
	return $res;
}

sub get_sent_messages {
	my ($self) = @_;
	return $self->request('direct_messages/sent', 'GET');
}

sub get_friends_ids {
	my ($self, $id) = @_;
	$id ||= $self->user_id;

	my $cursor = -1;
	my @ids = ();

	while ($cursor != 0) {
		my $result = $self->request('friends/ids', 'GET', {
			user_id => $id,
			cursor  => $cursor,
		});

		$cursor = $result->{next_cursor_str};
		push @ids, @{ $result->{ids} };
	}

	return \@ids;
}

sub get_followers_ids {
	my ($self, $id) = @_;
	$id ||= $self->user_id;

	my $cursor = -1;
	my @ids;

	while ($cursor != 0) {
		my $result = $self->request('followers/ids', 'GET', {
			user_id => $id,
			cursor  => $cursor,
		});

		$cursor = $result->{next_cursor_str};
		push @ids, @{ $result->{ids} };
	}

	return @ids;
}

sub lookup_users {
	my ($self, $ids, $rows, $offset) = @_;
	$offset ||= 0;

	my @ids = @$ids;
	@ids = grep { defined $_ } @ids[$offset .. $offset + $rows - 1];
	return () if @ids == 0;

	my $rpp = 100;
	my $len = int(@ids / $rpp);

	my $users;
	my @requests;

	for my $i (0 .. $len) {
		my @a = @ids;
		@a = grep { defined $_ } @a[$i * $rpp .. ($i + 1) * $rpp - 1];
		next if @a == 0;

		push @requests, [
			'users/lookup',
			'POST',
			{ user_id => join ',', @a },
			sub {
				my $result = shift;
				for my $user (@$result) {
					$users->{ $user->{id} } = $user;
				}
			}
		];
	}

	$self->request_async(@requests);

	return map { $users->{$_} } grep { exists $users->{$_} } @ids;
}

sub make_oauth_request {
	my ($self, $type, %params) = @_;

	die 'key must be specified.' unless defined $self->key;
	die 'secret must be specified.' unless defined $self->secret;

	local $Net::OAuth::SKIP_UTF8_DOUBLE_ENCODE_CHECK = 1;

	my $req = Net::OAuth->request($type)->new(
		version          => '1.0',
		consumer_key     => $self->key,
		consumer_secret  => $self->secret,
		signature_method => 'HMAC-SHA1',
		timestamp        => time,
		nonce            => Digest::SHA::sha1_base64(time . $$ . rand),
		%params,
	);
	$req->sign;

	if ($req->request_method eq 'POST') {
		return POST $req->normalized_request_url, $req->to_hash;
	}

	return GET $req->to_url;
}

sub get_authorization_url {
	my ($self, %params) = @_;

	die "callback must be specified." unless defined $params{callback};

	$params{request_url}    ||= $self->urls->{request_token};
	$params{request_method} ||= 'GET';

	my $req = $self->make_oauth_request('request token', %params);
	my $res = $self->ua->request($req);

	$self->validate($res);

	my $uri = URI->new;
	$uri->query($res->content);
	my %res_param = $uri->query_form;

	$self->request_token($res_param{oauth_token});
	$self->request_token_secret($res_param{oauth_token_secret});

	$uri = URI->new($self->urls->{authorization});
	$uri->query_form(oauth_token => $self->request_token);

	return $uri;
}

sub request_access_token {
	my ($self, %params) = @_;

	die "verifier must be specified." unless defined $params{verifier};

	$params{request_url}    ||= $self->urls->{access_token};
	$params{request_method} ||= 'GET';
	$params{token}          ||= $self->request_token;
	$params{token_secret}   ||= $self->request_token_secret;

	my $req = $self->make_oauth_request('access token', %params);
	my $res = $self->ua->request($req);

	delete $self->{request_token};
	delete $self->{request_token_secret};

	my $uri = URI->new;
	$uri->query($res->content);
	my %res_param = $uri->query_form;

	$self->user_id($res_param{user_id});
	$self->screen_name($res_param{screen_name});
	$self->access_token($res_param{oauth_token});
	$self->access_token_secret($res_param{oauth_token_secret});
}

sub request {
	my ($self, $command, $method, $params) = @_;
	$self->authorized;

	my $req = $self->make_oauth_request(
		'protected resource',
		request_url    => $self->urls->{api} . '/' . $command . '.json',
		request_method => $method,
		extra_params   => $params,
		token          => $self->access_token,
		token_secret   => $self->access_token_secret
	);
	my $res = $self->ua->request($req);

	return $self->validate($res);
}

sub request_async {
	my $self = shift;
	return if @_ == 0;

	$self->authorized;

	my $cv = AnyEvent->condvar;

	for my $row (@_) {
		my @r = @{ $row };

		my $cb      = pop @r;
		my $command = shift @r;
		my $method  = shift @r;
		my $params  = shift @r;

		my $req = $self->make_oauth_request(
			'protected resource',
			request_url    => $self->urls->{api} . '/' . $command . '.json',
			request_method => $method,
			extra_params   => $params,
			token          => $self->access_token,
			token_secret   => $self->access_token_secret
		);

		$cv->begin;
		$self->ua_async->request($req, sub {
			my $res = shift;
			my $content = $self->validate($res);
			$cb->($content);
			$cv->end;
		});
	}

	$cv->recv;
}

sub validate {
	my ($self, $res) = @_;
	my $c = $self->c;

	my $content = eval { decode_json($res->content) };
	if ($@) {
		warn "Couldn't decode JSON: $@";
		warn $res->content;
		$content = $res->content;
	}

	my $hdr = $res->headers;
	my $code = $res->code;

	if ($c->config_name ne 'production' and defined $hdr->{"x-ratelimit-remaining"}) {
		warn "Ratelimit: " . $hdr->{"x-ratelimit-remaining"} . "/" . $hdr->{"x-ratelimit-limit"};
	}

	unless ($code =~ /^2/) {
		if ($code eq '400' and $hdr->{'x-ratelimit-remaining'} eq '0') {
			$self->on_error->('No Ratelimit Remaining');
		}

		$self->on_error->('Unknown Error: ' . $res->content);
	}

	return $content;
}

sub parse_date {
	my ($self, $value) = @_;
	$value =~ s/\+\d{4} //;
	return DateTime::Format::HTTP
		->parse_datetime($value)
		->add(hours => 9)
		->set_time_zone('Asia/Tokyo');
}

1;
