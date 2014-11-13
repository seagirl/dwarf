package Dwarf;
use Dwarf::Pragma;
use Dwarf::Error;
use Dwarf::Message;
use Dwarf::Trigger;
use Dwarf::Util qw/capitalize read_file filename load_class dwarf_log/;
use Cwd 'abs_path';
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';
use Module::Find;
use Plack::Request;
use Plack::Response;
use Router::Simple;
use Scalar::Util qw/weaken/;

our $VERSION = '1.15';

use constant {
	BEFORE_DISPATCH    => 'before_dispatch',
	DISPATCHING        => 'dispatching',
	AFTER_DISPATCH     => 'after_dispatch',
	FINISH_DISPATCHING => 'Dwarf Finish Dispatching Message',
	ERROR              => 'error',
	NOT_FOUND          => 'not_found',
	SERVER_ERROR       => 'server_error',
};

use Dwarf::Accessor {
	ro => [qw/namespace base_dir env config error request response router handler handler_class ext models state/],
	rw => [qw/stash request_handler_prefix request_handler_method/],
};

sub _build_config {
	my $self = shift;
	$self->{config} ||= do {
		my $class = join '::', $self->namespace, 'Config';
		$class .= '::' . ucfirst $self->config_name if $self->can('config_name');
		load_class($class);
		my $config = $class->new(context => $self);
		weaken($config->{context});
		$config;
	};
}

sub _build_error {
	my $self = shift;
	$self->{error} ||= Dwarf::Error->new;
}

sub _build_request {
	my $self = shift;
	$self->{request} ||= do {
		my $req = Plack::Request->new($self->env);

		if (defined $req->param('debug')) {
			require CGI::Carp;
			CGI::Carp->import('fatalsToBrowser');
		}

		$req;
	};
}

sub _build_response {
	my $self = shift;
	$self->{response} ||= do {
		my $res = Plack::Response->new(200);
		$res->content_type('text/plain');
		$res;
	};
}

sub _build_router { Router::Simple->new }

sub new {
	my $invocant = shift;
	my $class = ref $invocant || $invocant;
	my $self = bless { @_ }, $class;
	dwarf_log 'new Dwarf';
	$self->init;
	return $self;
}

sub DESTROY {
	my $self = shift;
	dwarf_log 'DESTROY Dwarf';
}

sub init {
	my $self = shift;

	$self->{env}                    ||= {};
	$self->{namespace}              ||= ref $self;
	$self->{base_dir}               ||= abs_path(catfile(dirname(filename($self)), '..'));
	$self->{models}                 ||= {};
	$self->{state}                  ||= BEFORE_DISPATCH;
	$self->{stash}                  ||= {};
	$self->{request_handler_prefix} ||= join '::', $self->namespace, 'Controller';
	$self->{request_handler_method} ||= 'any';

	$self->setup;
	$self->add_routes;
}

sub add_routes {
	my $self = shift;
	$self->router->connect("/api/*", { controller => "Api" });
	$self->router->connect("/cli/*", { controller => "Cli" });
	$self->router->connect("*", { controller => "Web" });
}

sub setup {}

sub is_production { 1 }

sub is_cli {
	my $self = shift;
	my $server_software = $self->env->{SERVER_SOFTWARE} || '';
	return $server_software eq 'Plack::Handler::CLI';
}

sub param  { shift->request->param(@_) }
sub method { shift->request->method(@_) }
sub req    { shift->request(@_) }
sub res    { shift->response(@_) }
sub status { shift->res->status(@_) }
sub type   { shift->res->content_type(@_) }
sub header { shift->res->header(@_) }
sub body   { shift->res->body(@_) }

sub conf {
	my $self = shift;
	return $self->config->get(@_) if @_ == 1;
	return $self->config->set(@_);
}

sub dump {
	my $self = shift;
	Data::Dumper->Dump([@_]);
}

sub to_psgi {
	my $self = shift;
	$self->call_before_trigger;
	$self->dispatch(@_);
	$self->call_after_trigger;
	return $self->finalize;
}

sub finish {
	my ($self, $body) = @_;
	$body //= '';
	my $message = Dwarf::Message->new(
		name => FINISH_DISPATCHING,
		data => $body,
	);
	die $message;
}

sub redirect {
	my ($self, $to) = @_;
	$self->response->redirect($to);
	$self->finish;
	return;
}

sub dispatch {
	my $self = shift;

	dwarf_log 'dispatch Dwarf';

	eval {
		eval {
			my $p = $self->router->match($self->env);
			#warn Dumper $p;
			return $self->handle_not_found unless $p;

			my $controller = delete $p->{controller};
			my $action = delete $p->{action};
			my $splat = delete $p->{splat};

			# 余ったパラメータを追加
			for my $k (keys %{ $p }) {
				$self->request->parameters->add($k, $p->{$k});
			}

			# prefix がなかったら補完する
			if ($controller) {
				($controller) = $self->find_class($controller);
			}

			# splat があったら、splat から controller を組み立てる
			if ($splat) {
				my @a = grep { $_ ne "/" } @{ $splat };
				unshift @a, $controller if $controller;
				my ($class, $ext) = $self->find_class(join "/", @a);
				$controller = $class if $class;
			}

			return $self->handle_not_found unless $controller;
			Dwarf::Util::load_class($controller);

			$self->{handler_class} = $controller;
			$self->{handler} = $controller->new(context => $self);
			weaken($self->{handler}->{context});

			my $method = $self->find_method;
			return $self->not_found unless $method;

			$self->handler->init($self);
			my $body = $self->handler->$method($self, @_);

			$self->body($body);
		};
		if ($@) {
			my $error = $@;
			$@ = undef;

			if ($error =~ /Can't locate .+\.pm in/) {
				print STDERR $error . "\n";
				return $self->not_found;
			}

			if (ref $error eq 'Dwarf::Error') {
				return $self->handle_error($error);
			}

			die $error;
		}
	};
	if ($@) {
		my $error = $@;
		$@ = undef;

		if (ref $error eq 'Dwarf::Message') {
			if ($error->name eq FINISH_DISPATCHING) {
				return $self->body($error->data);
			}
		}

		return $self->handle_server_error($error);
	}
}

sub finalize {
	my $self = shift;

	if ($self->can('disconnect_db')) {
		$self->disconnect_db;
	}

	my $res = $self->response->finalize;
	return $res;
}

sub not_found {
	my $self = shift;
	$self->handle_not_found(@_);
	$self->finish;
}

sub handle_not_found {
	my ($self) = @_;
	$self->status(404);

	my @code = $self->get_trigger_code('NOT_FOUND');
	for my $code (@code) {
		my $body = $code->($self->_make_args);
		next unless $body;
		return $self->body($body);
	}

	my $body = "NOT FOUND";
	my $type = "text/plain";

	my $tmpl = $self->base_dir . '/tmpl/404.html';
	if (-f $tmpl) {
		$type = 'text/html';
		$body = read_file($tmpl);
	}

	$self->type($type);
	$self->body($body);
}

sub unauthorized {
	my $self = shift;
	$self->handle_unauthorized(@_);
	$self->finish;
}

sub handle_unauthorized {
	my ($self) = @_;
	$self->status(401);

	my @code = $self->get_trigger_code('UNAUTHORIZED');
	for my $code (@code) {
		my $body = $code->($self->_make_args);
		next unless $body;
		return $self->body($body);
	}

	my $body = "UNAUTHORIZED";
	my $type = "text/plain";

	my $tmpl = $self->base_dir . '/tmpl/401.html';
	if (-f $tmpl) {
		$type = 'text/html';
		$body = read_file($tmpl);
	}

	$self->type($type);
	$self->body($body);
}

sub handle_error {
	my ($self, $error) = @_;
	$self->status(400);

	my @code = $self->get_trigger_code('ERROR');
	for my $code (@code) {
		my $body = $code->($self->_make_args($error));
		next unless $body;
		return $self->body($body);
	}

	$self->receive_error($error);
}

sub handle_server_error {
	my ($self, $error) = @_;
	$self->status(500);

	my @code = $self->get_trigger_code('SERVER_ERROR');
	for my $code (@code) {
		my $body = $code->($self->_make_args($error));
		next unless $body;
		return $self->body($body);
	}

	$self->receive_server_error($error);
}

sub receive_error { die $_[1] }
sub receive_server_error { die $_[1] }

sub find_class {
	my ($self, $path, $prefix) = @_;
	return if not defined $path or $path eq '';

	$path =~ s|^/||;
	$path =~ s/\.(.*)$//;
	my $ext = $1;
	$self->{ext} = $1;

	my $class = join '::', map { capitalize($_) } grep { $_ ne '' } split '\/', $path;

	$prefix ||= $self->request_handler_prefix;

	if (defined $prefix and $prefix ne '') {
		if ($class !~ /^$prefix/) {
			$class = join '::', $prefix, $class;
		}
	}

	return ($class, $ext);
}

sub find_method {
	my ($self) = @_;
	my $request_method = $self->param('_method') || $self->method;
	$request_method = lc $request_method if defined $request_method;
	return unless $request_method =~ /^(get|post|put|delete)$/;
	return $self->handler->can($request_method)
		|| $self->handler->can($self->request_handler_method);
}

sub create_module {
	my $self = shift;
	my $package = shift;

	die "package name must be specified to create module."
		unless defined $package;

	my $prefix = $self->namespace;
	unless ($package =~ m/^$prefix/) {
		$package = $prefix . '::' . $package;
	}

	load_class($package);
	my $module = $package->new(context => $self, @_);
	weaken $module->{context};
	$module->init($self);
	return $module;
}

sub call_before_trigger {
	my $self = shift;
	if ($self->state eq BEFORE_DISPATCH) {
		$self->call_trigger(BEFORE_DISPATCH => $self, $self->request);
		$self->{state} = DISPATCHING;
	}
}

sub call_after_trigger {
	my $self = shift;
	if ($self->state eq DISPATCHING) {
		$self->call_trigger(AFTER_DISPATCH => $self, $self->response);
		$self->{state} = AFTER_DISPATCH;
	}
}

sub load_plugins {
	my ($class, %args) = @_;
	while (my ($module, $conf) = each %args) {
		$class->load_plugin($module, $conf);
	}
}

sub load_plugin {
	my ($class, $module, $conf) = @_;
	$module = load_class($module, 'Dwarf::Plugin');
	$module->init($class, $conf);
}

sub _make_args {
	my $self = shift;
	my @args;
	push @args, $self->handler if defined $self->handler;
	push @args, $self;
	push @args, @_;
	return @args;
}

1;
__END__

=encoding utf-8

=head1 NAME

Dwarf - Web Application Framework (Perl5)

=head1 SYNOPSIS

	package App::Controller::Web;
	use Dwarf::Pragma;
	use parent 'App::Controller::WebBase';
	use Dwarf::DSL;

	sub get {
		render 'index.html';
	}

	1;

=head1 DESCRIPTION

Dwarf は小規模グループ（1〜5人）向け Plack ベースのウェブアプリケーションフレームワークです。<br />

=over 2

=item *

ある程度の作業単位 (モジュール単位) で分業がし易い

=item *

設計の美しさより、簡潔性と利便性を重視

=back

といった特徴があります。<br />
<br />
Catalyst に比べるとかなり軽量。多くの Sinatraish な WAF と発想や規模は近いがスタイルが異なります。

=head2 プロジェクト初期化

	% dwarf hello_world

=head2 起動

デフォルトでは plackup で起動します。<br />
オプション -m に production と指定することで starman で起動します。<br />
この起動スクリプトは自由に編集して使われることを想定しています。

	% cd hello_world/app
	% ./script/start_searver.sh

=head2 プロジェクト構造

Dwarf は「プロジェクト毎に使い捨てる」という思想で作られています。<br />
よってフレームワーク本体もローカルに置かれるのが特徴です。

	app/
		app.psgi               ... PSGI ファイル
		cli.psgi               ... コマンドラインツール用 PSGI ファイル
		cpanfile               ... cpanfile
		Makefile               ... Make ファイル
	    lib/                   ... プログラム本体
	    	App.pm             ... アプリケーションクラス
	    	App/
	    		Config/        ... 設定ファイル
	    		Constant.pm    ... 定数定義
	    		DB.pm          ... Teng のサブクラス
	    		DB/
    				Schema.pm  ... スキーマクラス
	    		Controller/    ... コントローラ
	    			Api/       ... JSON や XML を返す API 用コントローラ
	    			ApiBase.pm ... API 用コントローラのベースクラス
	    			Cli/       ... コマンドラインツール用コントローラ
	    			CliBase.pm ... コマンドラインツール用コントローラのベースクラス
	    			Web/       ... HTML を返す Web ページ用コントローラ
	    			WebBase.pm ... Web ページ用コントローラのベースクラス
	    		Model/         ... モデル
	    		Test.pm        ... テストクラス
	    		Util/          ... ユーティリティクラス
	    	Dwarf.pm           ... Dwarf 本体
	    	Dwarf/
	    script/                ... コマンドラインツール
	    t/                     ... テスト
	    tmpl/                  ... HTML のテンプレート
	htdocs/                    ... ドキュメントルート
	sql/                       ... SQL

=head2 設定ファイル

設定ファイルは Perl オブジェクトで記述します。<br />
デフォルトで記述されている項目以外については自由に編集することが出来ます。<br />

	package App::Config::Production;
	use Dwarf::Pragma;
	use parent 'Dwarf::Config';

	sub setup {
		my $self = shift;
		return (
			db => {
				master => {
					dsn      => 'dbi:Pg:dbname=hello_world',
					username => 'www',
					password => '',
					opts     => { pg_enable_utf8 => 1 },
				},
			},
			ssl => 1,
			url => {
				base     => 'http://hello_world.com',
				ssl_base => 'https://hello_world.com',
			},
			dir => {
			},
			filestore => {
				private_dir => $self->c->base_dir . "/../data",
				public_dir  => $self->c->base_dir . "/../htdocs/data",
				public_uri  => "/data",
			},
			app => {
				facebook => {
					id     => '',
					secret => '',
				},
				twitter  => {
					id     => '',
					secret => '',
				}
			},
		);
	}

	1;

=head2 ルーティング

デフォルトのルーティングは Dwarf.pm に実装されています。

	sub add_routes {
		my $self = shift;
		$self->router->connect("/api/*", { controller => "Api" });
		$self->router->connect("/cli/*", { controller => "Cli" });
		$self->router->connect("*", { controller => "Web" });
	}

変更や追加も出来ます。App.pm に実装します。

	before add_routes => sub {
		my $self = shift;
		$self->router->connect("/images/detail/:user_id", { controller => "Web::Images::Detail" });
	};

=head2 コントローラ

Dwarf のコントローラはディスパッチされてきたリクエストに呼応するためのロジックを実装するクラスです。<br />
一般的な MVC フレームワークのようにモデルやビューを操作することに終止するクラスとは少し違います。<br />
<br />
例えば、WEB ページを表示するコントローラの場合、DB から情報を取ってきて加工する操作やビューに渡すデータの加工などのロジックは全てコントローラに実装します。<br />

=head3 作成

/login でアクセスされる WEB ページ用のコントローラを作成する

	% ./script/generate.pl Controller::Web::Login

=head3 実装

GET でログインフォームを表示し、POST で認証ロジックを実装する

	package App::Controller::Web::Login;
	use Dwarf::Pragma;
	use parent 'App::Controller::WebBase';
	use Dwarf::DSL;

	sub get {
	    render 'login.html';
	}

	sub post {
		redirect '/';
	}

=head2 モデル

Dwarf のモデルは複数のコントローラで共用されるようなロジックを汎用化して実装するためのクラスです。

=head3 作成

model('Auth') で呼ばれるモデルを作成する

	% ./script/generate.pl Model::Auth

=head3 実装

	package App::Model::Auth;
	use Dwarf::Pragma;
	use parent 'Dwarf::Module';
	use Dwarf::DSL;
	use App::Constant;

	use Dwarf::Accessor qw/member/;

	sub is_login {
		session->param('member') or return FALSE;
		return TRUE;
	}

	sub authenticate {
		my ($self, $username, $password) = @_;
		if (my $member = db->single('members', { username => $username, password => $password }) {
			self->member($member);
			self->login;
			return TRUE;
		}
	    return FALSE;
	}

	sub login {
		c->refresh_session;
		session->param(member => {
			id           => self->member->id,
			email        => self->member->email,
			nickname     => self->member->nickname,
		});
		session->flush;
	}

	sub logout {
		session->param(member => {});
		session->flush;
		return TRUE;
	}

	1;

=head2 アプリケーションクラス

App (based on Dwarf) = アプリケーションクラス + コンテキストクラス + ディスパッチャクラス<br />
<br />
コントローラやモデルに渡される $c はコンテキストオブジェクトであるが、Dwarf の場合はアプリケーションクラスでもある。設計的にはあまり美しくないが、フレームワークの実装をシンプルにするためにこのようになっている。<br />

=head3 設定ファイルの読み込み

手元の開発環境で動かす場合など複数の環境で動かすことを想定して、環境毎に違う設定ファイルを読み込むことが出来ます。<br />

=over 4

=item *

production というキーに本番用の設定ファイル名を渡します。

=item *

development というキーに開発用の設定ついての配列リファレンスを渡します。

=item *

配列リファレンスには、設定ファイル名をキーに、環境の定義を値にしたハッシュを渡します。

=item *

上から順に操作していき、最初にマッチした環境の設定ファイルが適用されます。

=back

環境の定義にはホスト名にマッチさせたい文字列か、環境を定義したハッシュリファレンスを指定します。<br />

	$self->load_plugins(
		'MultiConfig' => {
			production  => 'Production',
			development => [
				'Staging'     => {
					host => 'hello_world.s2factory.co.jp', # ホスト名
					dir  => '/proj/www/hello_world_stg'    # アプリケーションディレクトリの位置
				},
				'Development' => 'hello_world.s2factory.co.jp',
				'Seagirl'     => 'seagirl.local',
			],
		},
 	);

=head3 処理の流れ

=over 6

=item 1. BEFORE_DISPATCH トリガーの実行 (Dwarf はなにもしない)

=item 2. Router::Simple を使ってコントローラとメソッドを探索

=item 3. コントローラの生成

=item 4. メソッドを実行

=item 5. AFTER_DISPATCH トリガーの実行 (decode_json などが行われる)

=item 6. ファイナライズ処理 ($self->response->finalize)

=back

=head3 プロパティ

	ro => [qw/namespace base_dir env config error request response router handler handler_class models state is_production is_cli/],
	rw => [qw/stash request_handler_prefix request_handler_method/],

=head3 ショートカット

	param  (= $self->request->param)
	conf   (= $self->config->get / $self->config->set)
	req    (= $self->request)
	method (= $self->request->method)
	res    (= $self->response)
	status (= $self->response->status)
	type   (= $self->response->content_type)
	body   (= $self->response->body)

=head3 メソッド

=head4 to_psgi

PSGI アプリケーションを返します。

=head4 finish ($self, $body)

直ちにレスポンスを返します。

=head4 redirect

直ちにリダイレクトします。

=head4 not_found

直ちに 404 Not Found を返します。

=head4 load_plugins ($self, %args)

プラグインを読み込みます。

=head2 モジュール

Dwarf::Module はコントローラやモデルの根底クラス。<br />
<br />
Dwarf ではモジュール単位で作業を切り分けるという方針で設計されている。またモジュールを実装することが即ちアプリケーションを実装することになるので、コントローラであろうがモデルであろうがモジュールからは全て同じやり方でフレームワークの情報を参照出来るようになっている。

=head3 プロパティ

=head4 context

App.pm のインスタンス

=head3 ショートカット

	self          (= $self)
	app           (= $self->context)
	c             (= $self->context)
	m             (= $self->model)
	conf          (= $self->context->config->get / $self->context->config->set)
	db            (= $self->context->db)
	error         (= $self->context->error)
	e             (= $self->context->error)
	log           (= $self->context->log)
	debug         (= $self->context->log->debug)
	session       (= $self->context->session)
	param         (= $self->context->param)
	parameters    (= $self->context->request->parameters)
	request       (= $self->context->request)
	req           (= $self->context->request)
	method        (= $self->context->request->method)
	response      (= $self->context->response)
	res           (= $self->context->response)
	status        (= $self->context->response->status)
	type          (= $self->context->response->content_type)
	body          (= $self->context->response->body)
	not_found     (= $self->context->not_found)
	finish        (= $self->context->finish)
	redirect      (= $self->context->redirect)
	is_cli        (= $self->context->is_cli)
	is_production (= $self->context->is_production)
	load_plugin   (= $self->context->load_plugin)
	load_plugins  (= $self->context->load_plugins)
	render        (= $self->context->render)

use Dwarf::DSL することで上記のシンタックスシュガーを DSL として呼ぶことができます。

=head3 メソッド

=head4 init ($self, $c)

モジュール作成時に呼び出される初期処理用のテンプレートメソッド

=head4 model ($self, $package, @_)

$self->c->models にインスタンスが存在しなければ create_model を呼んでモデルインスタンスを作成します。

=head4 create_model ($self, $package, @_)

モデルのインスタンスを作成し、モデルクラスの init メソッドを呼びます。
残りの引数はモデルクラスの new に渡されます。
返り値には作成したインスタンスが返ります。

=head2 Dwarf モジュール

=head3 Dwarf::Module::APIBase

API 用のコントローラを実装するためのベースクラス

=over 6

=item validate

=item will_dispatch

=item will_render

=item did_render

=item receive_error

=item receive_server_error

=back

=head3 Dwarf::Module::HTMLBase

Web ページ用のコントローラを実装するためのベースクラス

=over 6

=item *

validate

=item *

will_dispatch

=item *

will_render

=item *

did_render

=item *

receive_error

=item *

receive_server_error

=back

=head3 Dwarf::Module::CLIBase

CLI 用のコントローラを実装するためのベースクラス

=over 2

=item *

receive_error

=item *

receive_server_error

=back

=head3 Dwarf::Module::SocialMedia::Twitter

=head3 Dwarf::Module::SocialMedia::Faceboo

=head3 Dwarf::Module::SocialMedia::Mixi

=head3 Dwarf::Module::SocialMedia::Weibo

Twitter/Facebook/Mixi/Weibo 各種 API を扱うためのクラス

=head2 エラー

Dwarf では 2 種類のエラーを扱うことが出来ます。

=over 2

=item *

Dwarf のエラー (ERROR)

=item *

Perl のエラー (SERVER_ERROR)

=back

=head2 Dwarf::Error

Dwarf::Error は Dwarf のエラーを取り扱うためのクラスです。
Dwarf::Error は複数の Dwarf::Message::Error を保持することが出来ます。

=head3 プロパティ

=head4 autoflush

このフラグを true にすると throw が呼ばれた時に自動的に flush が呼ばれます。
デフォルトは false。

=head4 messages

Dwarf::Message::Error オブジェクトの配列です。

=head3 メソッド

=head4 throw

エラーメッセージを作成し、エラーを送出します。
autoflush が true な場合は、flush を呼び出します。

=head4 flush

送出されたエラーメッセージを実際にフレームワークに出力します。

=head2 Dwarf::Message::Error

Dwarf のエラー個々の内容を示すクラスです。

=head3 プロパティ

=head4 data

エラーデータを格納する配列リファレンスです。
Dwarf::Error の flush メソッドに渡された引数がそのまま data に渡されます。

	my $m = Dwarf::Message::Error->new;
	$m->data([@_]);

=head2 エラーの送出

Dwarf のエラーを出力するには、Error クラスの throw メソッドを使用します。

	$c->error->throw(400,  "Something wrong.");

Dwarf::Plubin::Error を読み込むことでエラークラスにショートカットを作成することが出来ます。

	$c->load_plugins(
		'Error' => {
			LACK_OF_PARAM   => sub { shift->throw(1001, sprintf("missing mandatory parameters: %s", $_[0] || "")) },
			INVALID_PARAM   => sub { shift->throw(1002, sprintf("illegal parameter: %s", $_[0] || "")) },
			NEED_TO_LOGIN   => sub { shift->throw(1003, sprintf("You must login.")) },
			SNS_LIMIT_ERROR => sub { shift->throw(2001, sprintf("SNS Limit Error: reset at %s", $_[0] || "")) },
			SNS_ERROR       => sub { shift->throw(2002, sprintf("SNS Error: %s", $_[0] || "SNS Error.")) },
			ERROR           => sub { shift->throw(400,  sprintf("%s", $_[0] || "Unknown Error.")) },
		}
	);

モジュールの中で実際に呼び出す場合には、書きのようになります。

	e->LACK_OF_PARAM('user_id'); # $c->error->LACK_OF_PARAM('user_id');


=head2 エラーハンドリング

二つのエラーに対応するトリガーを登録することでをエラーをハンドリングすることが出来ます。

	$c->add_trigger(ERROR => sub { warn @_ });
	$c->add_trigger(SERVER_ERROR => sub { warn @_ };

トリガーが一つも登録されていない場合は、Dwarf.pm の receive_error メソッドおよび receive_server_error メソッドが呼び出されます。

	sub receive_error { die $_[1] }
	sub receive_server_error { die $_[1] }

=head2 APIBase.pm のバリデーションとエラーハンドリング

APIBase の validate メソッドは FormValidator::Lite の check メソッドのラッパーになっており、バリデーションエラーを検知した場合に Dwarf のエラーを送出します。また、APIBase では Dwarf::Error の autoflush を true にセットするため、エラーが送出されるとただちに receive_error メソッドに処理が移ります。

	sub validate {
		my ($self, @rules) = @_;
		return unless @rules;

		my $validator = S2Factory::Validator->new($self->c->req)->check(@rules);
		if ($validator->has_error) {
			while (my ($param, $detail) = each %{ $validator->errors }) {
				$self->c->error->LACK_OF_PARAM($param) if $detail->{NOT_NULL};
				$self->c->error->INVALID_PARAM($param);
			}
		}
	}

APIBase ではエラーハンドリング用のトリガーがあらかじめ登録されています。サブクラスで下記のメソッドをオーバライドすることで振る舞いを変えることが出来ます。


	# 400 系のエラー
	sub receive_error {
		my ($self, $c, $error) = @_;
		my (@codes, @messages);

		for my $m (@{ $error->messages }) {
			warn sprintf "API Error: code = %s, message = %s", $m->data->[0], $m->data->[1];
			push @codes, $m->data->[0];
			push @messages, $m->data->[1];
		}

		my $data = {
			error_code    => @codes == 1 ? $codes[0] : \@codes,
			error_message => @messages == 1 ? $messages[0] : \@messages,
		};

		return $data;
	}

	# 500 系のエラー
	sub receive_server_error {
		my ($self, $c, $error) = @_;

		$error ||= 'Internal Server Error';

		my $data = {
			error_code    => 500,
			error_message => $error,
		};

		return $data;
	}

=head2 HTMLBase.pm のバリデーションとエラーハンドリング

HTMLBase の validate メソッドは FormValidator::Lite の check メソッドのラッパーになっており、バリデーションエラーを検知した場合に Dwarf のエラーを送出します。また、HTMLBase では Dwarf::Error の autoflush を false にセットするため、エラーが送出されても flush メソッドが呼ばれるまで receive_error メソッドに処理が移りません。HTMLBase では will_dispatch メソッドの実行後に flush メソッドを呼び出します。そのため、コントローラの実装時には will_dispatch メソッドの中でバリデーションを行います。

	sub validate {
		my ($self, @rules) = @_;
		return unless @rules;
		my $validator = S2Factory::Validator->new($self->req)->check(@rules);
		if ($validator->has_error) {
			while (my ($param, $detail) = each %{ $validator->errors }) {
				$self->error->LACK_OF_PARAM($param, $detail) if $detail->{NOT_NULL};
				$self->error->INVALID_PARAM($param, $detail);
			}
		}
	}

HTMLBase ではエラーハンドリング用のトリガーがあらかじめ登録されています。サブクラスで下記のメソッドをオーバライドすることで振る舞いを変えることが出来ます。

	# 400 系のエラー
	sub receive_error {
		my ($self, $c, $error) = @_;

		$self->{error_template} ||= '400.html';
		$self->{error_vars}     ||= $self->req->parameters->as_hashref;

		for my $message (@{ $error->messages }) {
			my $code   = $message->data->[0];
			my $param  = $message->data->[1];
			my $detail = $message->data->[2];

			$self->{error_vars}->{error}->{$param} = merge_hash(
				$self->{error_vars}->{error}->{$param},
				$detail
			);
		}

		return $c->render($self->error_template, $self->error_vars);
	}

	# 500 系のエラー
	sub receive_server_error {
		my ($self, $c, $error) = @_;
		$self->{server_error_template}    ||= '500.html';
		$self->{server_error_vars} ||= { error => $error };
		return $c->render($self->server_error_template, $self->server_error_vars);
	}

WEB ページ実装時のバリデーションとエラーハンドリングの例

	package App::Controller::Web::Login;
	use Dwarf::Pragma;
	use parent 'App::Controller::WebBase';
	use Dwarf::DSL;
	use Class::Method::Modifiers;

	# バリデーションの実装例。validate は何度でも呼べる。
	# will_dispatch 終了時にエラーがあれば receive_error が呼び出される。
	sub will_dispatch  {
		if (method eq 'POST') {
			self->validate(
				user_id  => [qw/NOT_NULL UINT/, [qw/RANGE 1 8/]],
				password => [qw/NOT_NULL UINT/, [qw/RANGE 1 8/]],
			);
		}
	};

	# バリデーションがエラーになった時に呼び出される（定義元: Dwarf::Module::HTMLBase）
	# エラー表示に使うテンプレートと値を変更したい時はこのメソッドで実装する
	# バリデーションのエラー理由は、self->error_vars->{error}->{PARAM_NAME} にハッシュリファレンスで格納される
	before receive_error => sub {
		self->{error_template} = 'login.html';
		self->{error_vars} = parameters->as_hashref;
	};

	sub get {
		render('login.html');
	}

	sub post {
		my $user_id = param('user_id');
		my $password = param('password')

		if (model('Auth')->authenticate($user_id, $password)) {
			model('Auth')->login;
			redirect '/';
		}

		e->INVALID_PARAM(user_id => "INVALID");
		e->INVALID_PARAM(password => "INVALID");
		e->flush;
	}

	1;

=head2 Dwarf::Pragma

use すると基本的なプラグマをまとめてセットするショートカットの役割をするクラスです。

	use strict;
	use warnings;
	use utf8;
	use feature '5.10';
	use boolean;

オプションで utf8 と feature の挙動は変更することが出来ます。

	sub import {
		my ($class, %args) = @_;

		$utf8 = 1 unless defined $args{utf8};
		$feature = "5.10" unless defined $args{feature};

		warnings->import;
		strict->import;
		boolean->import;
		boolean->export_to_level(1);

		if ($utf8) {
			utf8->import;
		}

		if ($feature ne 'legacy') {
			require 'feature.pm';
			feature->import(":" . $feature);
		}
	}

=head2 Dwarf::Accessor

アクセサを作成するためのクラスです。

=head3 Lazy Initialization

「_build_ + プロパティ名」というメソッドを実装することで、初期値を遅延生成することが出来ます。

	use Dwarf::Accessor qw/json/;

	sub _build_json {
		my $json = JSON->new();
		$json->pretty(1);
		$json->utf8;
		return $json;
	}

=head2 Dwarf::Message

ディスパッチ処理の中で送出可能なメッセージクラス。主にフレームワークがエラーハンドリングなどに利用している。not_found メソッドや redirect メソッドが利用している finish メソッドの実装にもディスパッチパッチを直ちに終了する目的で使われている。

=head2 Dwarf::Trigger

トリガークラス。Dwarf が提供しているトリガーは BEFORE_DISPATCH / AFTER_DISPATCH / ERROR / SERVER_ERROR の四種類。また、Dwarf::Plugin::Text::Xslate などのプラグインは読み込まれると BEFORE_RENDER / AFTER_RENDER の二種類のトリガーを提供する。APIBase.pm や HTMLBase.pm はこれらのトリガーを実装するためのメソッドをあらかじめ用意してあり、サブクラスで実際にメソッドが実装されるとコールされる仕組みになっている。

	$c->add_trigger(BEFORE_RENDER => $self->can('will_render'));
	$c->add_trigger(AFTER_RENDER => $self->can('did_render'));
	$c->add_trigger(ERROR => $self->can('receive_error'));
	$c->add_trigger(SERVER_ERROR => $self->can('receive_server_error'));

=head2 Dwarf::Util

ユーティリティクラス。以下のメソッドが @EXPORT_OK である。

=head3 メソッド

=head4 add_method

=head4 load_class

=head4 installed

=head4 capitalize

=head4 shuffle_array

=head4 filename

=head4 read_file

=head4 write_file

=head4 get_suffix

=head4 safe_join

=head4 merge_hash

=head4 encode_utf8

=head4 decode_utf8

=head4 encode_utf8_recursively

=head4 decode_utf8_recursively

=head2 Dwarf::Test

テストクラス

=head1 LICENSE

Copyright (C) Takuho Yoshizu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takuho Yoshizu E<lt>yoshizu@s2factory.co.jpE<gt>

=cut