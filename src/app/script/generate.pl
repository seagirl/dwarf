#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw/abs_path/;
use Data::Section::Simple;
use File::Path 'mkpath';
use FindBin;
use Getopt::Long;
use Pod::Usage 'pod2usage';
use Text::Xslate;
use lib "${FindBin::RealBin}/../lib";
use Dwarf::Util qw(write_file);

my $opts = { output => $FindBin::RealBin . '/../lib' };
GetOptions($opts, 'name=s', 'output=s', 'help');

if (@ARGV) {
	$opts->{name} = $ARGV[0];
	$opts->{output} = $ARGV[1] if $ARGV[1];
}

if (not $opts->{name} or $opts->{help}) {
	pod2usage;
}

# App が付いてなければ補完
unless ($opts->{name} =~ /^App::/) {
	$opts->{name} = "App::" . $opts->{name};
}

my $type = 'Model.pm';
$type = 'Api.pm'   if $opts->{name} =~ /::Api/;
$type = 'Cli.pm'   if $opts->{name} =~ /::Cli/;
$type = 'Web.pm'   if $opts->{name} =~ /::Web/;

my $reader = Data::Section::Simple->new('View');
my $tmpl = $reader->get_data_section($type);

my $tx = Text::Xslate->new;
my $content = $tx->render_string($tmpl, $opts);

my $dst = abs_path($opts->{output} . "/" . name2path($opts->{name}));
write_file($dst, $content);

print "created $dst\n";

sub name2path {
	my $name = shift;
	$name =~ s/::/\//g;
	$name .= ".pm";
}

=head1 SYNOPSIS

./generate.pl CLASS_NAME [-o OUTPUT_DIR]

=cut

package View;

1;

__DATA__

@@ Api.pm

package <: $name :>;
use Dwarf::Pragma;
use parent 'App::Controller::ApiBase';
use Dwarf::DSL;
use Class::Method::Modifiers;

after will_dispatch => sub {
};

sub get {
}

1;

@@ Cli.pm

package <: $name :>;
use Dwarf::Pragma;
use parent 'App::Controller::CliBase';
use Dwarf::DSL;

sub any {
}

1;

@@ Web.pm

package <: $name :>;
use Dwarf::Pragma;
use parent 'App::Controller::WebBase';
use Dwarf::DSL;
use Class::Method::Modifiers;

# バリデーションの実装例。validate は何度でも呼べる。
# will_dispatch 終了時にエラーがあれば receive_error が呼び出される。
# after will_dispatch => sub {
#	self->validate(
#		user_id  => [qw/NOT_NULL UINT/, [qw/RANGE 1 8/]],
#		password => [qw/NOT_NULL UINT/, [qw/RANGE 1 8/]],
#	);
# };

# バリデーションがエラーになった時に呼び出される（定義元: Dwarf::Module::HTMLBase）
# エラー表示に使うテンプレートと値を変更したい時はこのメソッドで実装する
# バリデーションのエラー理由は、self->error_vars->{error}->{PARAM_NAME} にハッシュリファレンスで格納される
# before receive_error => sub {
#	self->{error_template} = 'index.html';
#	self->{error_vars} = parameters->as_hashref;
# };

sub get {
	return render('index.html');
}

1;

@@ Model.pm

package <: $name :>;
use Dwarf::Pragma;
use parent 'Dwarf::Module';

1;
