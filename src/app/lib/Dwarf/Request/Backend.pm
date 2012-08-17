package Dwarf::Request::Backend;
use strict;
use warnings;

use Carp ();
use HTTP::Headers;
use HTTP::Body;
use URI;
use URI::Escape ();

use Dwarf::MultiValue;
use Dwarf::Request::Upload;
use Dwarf::TempBuffer;


sub new {
	my ($class, $env) = @_;

	Carp::croak(q{$env is required})
		unless defined $env && ref($env) eq 'HASH';

	bless { env => $env }, $class;
}

sub env { $_[0]->{env} }

sub data {
	my $self = shift;
	if (@_ > 0) {
		Carp::croak('Dwarf::Request.data must be HASH reference.')
			unless ref $_[0] eq 'HASH';

		$self->{data} = $_[0];
	}
	$self->{data} ||= {};	
}

sub address     { $_[0]->env->{REMOTE_ADDR} }
sub remote_host { $_[0]->env->{REMOTE_HOST} }
sub protocol    { $_[0]->env->{SERVER_PROTOCOL} }
sub method      { $_[0]->env->{REQUEST_METHOD} }
sub port        { $_[0]->env->{SERVER_PORT} }
sub user        { $_[0]->env->{REMOTE_USER} }
sub request_uri { $_[0]->env->{REQUEST_URI} }
sub path_info   { $_[0]->env->{PATH_INFO} }
sub path        { $_[0]->env->{PATH_INFO} || '/' }
sub script_name { $_[0]->env->{SCRIPT_NAME} }
sub scheme      { $_[0]->env->{'psgi.url_scheme'} }
sub secure      { $_[0]->scheme eq 'https' }
sub body        { $_[0]->env->{'psgi.input'} }
sub input       { $_[0]->env->{'psgi.input'} }

sub content_length   { $_[0]->env->{CONTENT_LENGTH} }
sub content_type     { $_[0]->env->{CONTENT_TYPE} }

sub session         { $_[0]->env->{'psgix.session'} }
sub session_options { $_[0]->env->{'psgix.session.options'} }
sub logger          { $_[0]->env->{'psgix.logger'} }

sub cookies {
	my $self = shift;

	return {} unless $self->env->{HTTP_COOKIE};

	# HTTP_COOKIE hasn't changed: reuse the parsed cookie
	if (   $self->env->{'dwarf.cookie.parsed'}
		&& $self->env->{'dwarf.cookie.string'} eq $self->env->{HTTP_COOKIE}) {
		return $self->env->{'dwarf.cookie.parsed'};
	}

	$self->env->{'dwarf.cookie.string'} = $self->env->{HTTP_COOKIE};

	my %results;
	my @pairs = split "[;,] ?", $self->env->{'dwarf.cookie.string'};
	for my $pair ( @pairs ) {
		# trim leading trailing whitespace
		$pair =~ s/^\s+//; $pair =~ s/\s+$//;

		my ($key, $value) = map URI::Escape::uri_unescape($_), split( "=", $pair, 2 );

		# Take the first one like CGI.pm or rack do
		$results{$key} = $value unless exists $results{$key};
	}

	$self->env->{'dwarf.cookie.parsed'} = \%results;
}

sub query_parameters {
	my $self = shift;
	$self->env->{'dwarf.request.query'} ||= Dwarf::MultiValue->new($self->uri->query_form);
}

sub content {
	my $self = shift;

	unless ($self->env->{'psgix.input.buffered'}) {
		$self->_parse_request_body;
	}

	my $fh = $self->input                 or return '';
	my $cl = $self->env->{CONTENT_LENGTH} or return'';
	$fh->read(my($content), $cl, 0);
	$fh->seek(0, 0);

	return $content;
}

sub raw_body { $_[0]->content }

# XXX you can mutate headers with ->headers but it's not written through to the env

sub headers {
	my $self = shift;
	if (!defined $self->{headers}) {
		my $env = $self->env;
		$self->{headers} = HTTP::Headers->new(
			map {
				(my $field = $_) =~ s/^HTTPS?_//;
				( $field => $env->{$_} );
			}
			grep { /^(?:HTTP|CONTENT|COOKIE)/i } keys %$env
		);
	}
	$self->{headers};
}

sub content_encoding { shift->headers->content_encoding(@_) }
sub header           { shift->headers->header(@_) }
sub referer          { shift->headers->referer(@_) }
sub user_agent       { shift->headers->user_agent(@_) }

sub body_parameters {
	my $self = shift;

	unless ($self->env->{'dwarf.request.body'}) {
		$self->_parse_request_body;
	}

	return $self->env->{'dwarf.request.body'};
}

# contains body + query
sub parameters {
	my $self = shift;

	$self->env->{'dwarf.request.merged'} ||= do {
		my $query = $self->query_parameters;
		my $body  = $self->body_parameters;
		Dwarf::MultiValue->new($query->flatten, $body->flatten);
	};
}

sub uploads {
	my $self = shift;

	if ($self->env->{'dwarf.request.upload'}) {
		return $self->env->{'dwarf.request.upload'};
	}

	$self->_parse_request_body;
	return $self->env->{'dwarf.request.upload'};
}

sub param {
	my $self = shift;

	return keys %{ $self->parameters } if @_ == 0;

	my $key = shift;
	return $self->parameters->{$key} unless wantarray;
	return $self->parameters->get_all($key);
}

sub upload {
	my $self = shift;

	return keys %{ $self->uploads } if @_ == 0;

	my $key = shift;
	return $self->uploads->{$key} unless wantarray;
	return $self->uploads->get_all($key);
}

sub uri {
	my $self = shift;

	my $base = $self->_uri_base;

	# We have to escape back PATH_INFO in case they include stuff like
	# ? or # so that the URI parser won't be tricked. However we should
	# preserve '/' since encoding them into %2f doesn't make sense.
	# This means when a request like /foo%2fbar comes in, we recognize
	# it as /foo/bar which is not ideal, but that's how the PSGI PATH_INFO
	# spec goes and we can't do anything about it. See PSGI::FAQ for details.
	# http://github.com/miyagawa/Plack/issues#issue/118
	my $path_escape_class = '^A-Za-z0-9\-\._~/';

	my $path = URI::Escape::uri_escape($self->env->{PATH_INFO} || '', $path_escape_class);
	$path .= '?' . $self->env->{QUERY_STRING}
		if defined $self->env->{QUERY_STRING} && $self->env->{QUERY_STRING} ne '';

	$base =~ s!/$!! if $path =~ m!^/!;

	return URI->new($base . $path)->canonical;
}

sub base {
	my $self = shift;
	URI->new($self->_uri_base)->canonical;
}

sub _uri_base {
	my $self = shift;

	my $env = $self->env;

	my $uri = ($env->{'psgi.url_scheme'} || "http") .
		"://" .
		($env->{HTTP_HOST} || (($env->{SERVER_NAME} || "") . ":" . ($env->{SERVER_PORT} || 80))) .
		($env->{SCRIPT_NAME} || '/');

	return $uri;
}

sub new_response {
	my $self = shift;
	require Dwarf::Response;
	Dwarf::Response->new(@_);
}

sub _parse_request_body {
	my $self = shift;

	my $ct = $self->env->{CONTENT_TYPE};
	my $cl = $self->env->{CONTENT_LENGTH};
	if (!$ct && !$cl) {
		# No Content-Type nor Content-Length -> GET/HEAD
		$self->env->{'dwarf.request.body'}   = Dwarf::MultiValue->new;
		$self->env->{'dwarf.request.upload'} = Dwarf::MultiValue->new;
		return;
	}

	my $body = HTTP::Body->new($ct, $cl);

	# HTTP::Body will create temporary files in case there was an
	# upload.  Those temporary files can be cleaned up by telling
	# HTTP::Body to do so. It will run the cleanup when the request
	# env is destroyed. That the object will not go out of scope by
	# the end of this sub we will store a reference here.
	$self->env->{'dwarf.request.http.body'} = $body;
	$body->cleanup(1);

	my $input = $self->input;

	my $buffer;
	if ($self->env->{'psgix.input.buffered'}) {
		# Just in case if input is read by middleware/apps beforehand
		$input->seek(0, 0);
	} else {
		$buffer = Dwarf::TempBuffer->new($cl);
	}

	my $spin = 0;
	while ($cl) {
		$input->read(my $chunk, $cl < 8192 ? $cl : 8192);
		my $read = length $chunk;
		$cl -= $read;
		$body->add($chunk);
		$buffer->print($chunk) if $buffer;

		if ($read == 0 && $spin++ > 2000) {
			Carp::croak "Bad Content-Length: maybe client disconnect? ($cl bytes remaining)";
		}
	}

	if ($buffer) {
		$self->env->{'psgix.input.buffered'} = 1;
		$self->env->{'psgi.input'} = $buffer->rewind;
	} else {
		$input->seek(0, 0);
	}

	$self->env->{'dwarf.request.body'}   = Dwarf::MultiValue->from_mixed($body->param);

	my @uploads = Dwarf::MultiValue->from_mixed($body->upload)->flatten;
	my @obj;
	while (my($k, $v) = splice @uploads, 0, 2) {
		push @obj, $k, $self->_make_upload($v);
	}

	$self->env->{'dwarf.request.upload'} = Dwarf::MultiValue->new(@obj);

	1;
}

sub _make_upload {
	my($self, $upload) = @_;
	Dwarf::Request::Upload->new(
		headers => HTTP::Headers->new( %{delete $upload->{headers}} ),
		%$upload,
	);
}

1;
