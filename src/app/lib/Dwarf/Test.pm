package Dwarf::Test;
use Dwarf::Pragma;
use parent 'Exporter';
use HTTP::Request::Common ();
use Plack::Test;
use Test::More;
use UNIVERSAL::require;

our @EXPORT = qw/GET POST is_success get_ok post_ok post_redirect/;

sub GET  { HTTP::Request::Common::GET(@_) }
sub POST { HTTP::Request::Common::POST(@_) }

sub is_success {
	my ($res, $path) = @_;
	my $desc = $res->status_line;
	$desc .= ', redirected to ' . ($res->header("Location") || "") if ($res->is_redirect);
	ok $res->is_success, "$path: $desc";
}

sub get_ok {
	my ($cb, $path) = @_;
	my $res = $cb->(GET $path);
	is_success($res, $path);
	$res;
}

sub post_ok {
	my ($cb, $path, @args) = @_;
	my $res = $cb->(POST $path, @args);
	is_success($res, $path);
	$res;
}

sub post_redirect {
	my ($cb, $path, $param) = @_;
	my $res = $cb->(POST $path, $param);
	ok !$res->is_success, "$path: " . $res->status_line;
	ok $res->is_redirect, "$path: redirected to " . ($res->header("Location") || '');
	$res;
}


1;
