package Dwarf::Response::Backend;
use strict;
use warnings;

use Carp ();
use HTTP::Headers;
use Scalar::Util ();
use URI::Escape ();

use Dwarf::Accessor qw/body status/;

sub code    { shift->status(@_) }
sub content { shift->body(@_)   }

sub new {
    my($class, $rc, $headers, $content) = @_;

    my $self = bless {}, $class;
    $self->status($rc)       if defined $rc;
    $self->headers($headers) if defined $headers;
    $self->body($content)    if defined $content;

    $self;
}

sub headers {
    my $self = shift;

    if (@_) {
        my $headers = shift;
        if (ref $headers eq 'ARRAY') {
            Carp::carp("Odd number of headers") if @$headers % 2 != 0;
            $headers = HTTP::Headers->new(@$headers);
        } elsif (ref $headers eq 'HASH') {
            $headers = HTTP::Headers->new(%$headers);
        }
        return $self->{headers} = $headers;
    } else {
        return $self->{headers} ||= HTTP::Headers->new();
    }
}

sub cookies {
    my $self = shift;
    if (@_) {
        $self->{cookies} = shift;
    } else {
        return $self->{cookies} ||= +{ };
    }
}

sub header { shift->headers->header(@_) } # shortcut

sub content_length {
    shift->headers->content_length(@_);
}

sub content_type {
    shift->headers->content_type(@_);
}

sub content_encoding {
    shift->headers->content_encoding(@_);
}

sub location {
    shift->headers->header('Location' => @_);
}

sub redirect {
    my $self = shift;

    if (@_) {
        my $url = shift;
        my $status = shift || 302;
        $self->location($url);
        $self->status($status);
    }

    return $self->location;
}

sub finalize {
    my $self = shift;
    Carp::croak "missing status" unless $self->status();

    $self->_finalize_cookies();

    return [
        $self->status,
        +[
            map {
                my $k = $_;
                map { ( $k => $_ ) } $self->headers->header($_);
            } $self->headers->header_field_names
        ],
        $self->_body,
    ];
}

sub _body {
    my $self = shift;
    my $body = $self->body;
       $body = [] unless defined $body;
    if (!ref $body or Scalar::Util::blessed($body) && overload::Method($body, q(""))) {
        return [ $body ];
    } else {
        return $body;
    }
}

sub _finalize_cookies {
    my $self = shift;

    while (my($name, $val) = each %{$self->cookies}) {
        my $cookie = $self->_bake_cookie($name, $val);
        $self->headers->push_header( 'Set-Cookie' => $cookie );
    }
}

sub _bake_cookie {
    my($self, $name, $val) = @_;

    return '' unless defined $val;
    $val = { value => $val } unless ref $val eq 'HASH';

    my @cookie = ( URI::Escape::uri_escape($name) . "=" . URI::Escape::uri_escape($val->{value}) );
    push @cookie, "domain=" . $val->{domain}   if $val->{domain};
    push @cookie, "path=" . $val->{path}       if $val->{path};
    push @cookie, "expires=" . $self->_date($val->{expires}) if $val->{expires};
    push @cookie, "secure"                     if $val->{secure};
    push @cookie, "HttpOnly"                   if $val->{httponly};

    return join "; ", @cookie;
}

my @MON  = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my @WDAY = qw( Sun Mon Tue Wed Thu Fri Sat );

sub _date {
    my($self, $expires) = @_;

    if ($expires =~ /^\d+$/) {
        # all numbers -> epoch date
        # (cookies use '-' as date separator, HTTP uses ' ')
        my($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($expires);
        $year += 1900;

        return sprintf("%s, %02d-%s-%04d %02d:%02d:%02d GMT",
                       $WDAY[$wday], $mday, $MON[$mon], $year, $hour, $min, $sec);

    }

    return $expires;
}

1;
