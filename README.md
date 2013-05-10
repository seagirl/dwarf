Dwarf
=====

Web Application Framework (Perl5)

## SYNOPSIS

	package App::Controller::Web;
	use Dwarf::Pragma;
	use parent 'App::Controller::WebBase';
	use Dwarf::DSL;

	sub get {
		render 'index.html';
	}

	1;

Dwarf は小規模グループ（1〜5人）向け Plack ベースのウェブアプリケーションフレームワークです。<br />

- ある程度の作業単位 (モジュール単位) で分業がし易い
- 設計の美しさより、簡潔性と利便性を重視

といった特徴があります。<br />
<br />
Catalyst に比べるとかなり軽量。多くの Sinatraish な WAF と発想や規模は近いがスタイルが異なります。

## プロジェクト初期化

	% ./dwarf.pl hello_world

## 起動

デフォルトでは plackup で起動します。<br />
オプション -m に production と指定することで starman で起動します。<br />
この起動スクリプトは自由に編集して使われることを想定しています。

	% cd hello_world/app
	% ./script/start_searver.sh

## プロジェクト構造

Dwarf は「プロジェクト毎に使い捨てる」という思想で作られています。<br />
よってフレームワーク本体もローカルに置かれるのが特徴です。

	app/
		app.psgi               ... PSGI ファイル
		cli.psgi               ... コマンドラインツール用 PSGI ファイル
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

## 設定ファイル

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

## ルーティング

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

## コントローラ

Dwarf のコントローラはディスパッチされてきたリクエストに呼応するためのロジックを実装するクラスです。<br />
一般的な MVC フレームワークのようにモデルやビューを操作することに終止するクラスとは少し違います。<br />
<br />
例えば、WEB ページを表示するコントローラの場合、DB から情報を取ってきて加工する操作やビューに渡すデータの加工などのロジックは全てコントローラに実装します。<br />

### 作成

/login でアクセスされる WEB ページ用のコントローラを作成する

	% ./script/generate.pl Controller::Web::Login

### 実装

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

## モデル

Dwarf のモデルは複数のコントローラで共用されるようなロジックを汎用化して実装するためのクラスです。

### 作成

m('Auth') で呼ばれるモデルを作成する

	% ./script/generate.pl Model::Auth

### 実装

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
		session->refresh;
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

## アプリケーションクラス

App (based on Dwarf) = アプリケーションクラス + コンテキストクラス + ディスパッチャクラス<br />
<br />
コントローラやモデルに渡される $c はコンテキストオブジェクトであるが、Dwarf の場合はアプリケーションクラスでもある。設計的にはあまり美しくないが、フレームワークの実装をシンプルにするためにこのようになっている。<br />

### 設定ファイルの読み込み

手元の開発環境で動かす場合など複数の環境で動かすことを想定して、環境毎に違う設定ファイルを読み込むことが出来ます。<br />

- production というキーに本番用の設定ファイル名を渡します。
- development というキーに開発用の設定ついての配列リファレンスを渡します。
- 配列リファレンスには、設定ファイル名をキーに、環境の定義を値にしたハッシュを渡します。
- 上から順に操作していき、最初にマッチした環境の設定ファイルが適用されます。

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

### プロパティ

	ro => [qw/namespace base_dir env config error request response router handler handler_class state is_production is_cli/],
	rw => [qw/stash request_handler_prefix request_handler_method/],

### シンタックスシュガー

	param  (= $self->request->param)
	conf   (= $self->config->get / $self->config->set)
	method (= $self->request->method)
	req    (= $self->request)
	res    (= $self->response)
	status (= $self->response->status)
	type   (= $self->response->content_type)
	body   (= $self->response->body)

### メソッド

#### to_psgi

PSGI アプリケーションを返します。

#### finish ($self, $body)

直ちにレスポンスを返します。

#### redirect

直ちにリダイレクトします。

#### not_found

直ちに 404 Not Found を返します。

#### load_plugins ($self, %args)

プラグインを読み込みます。

## モジュール

Dwarf::Module はコントローラやモデルの根底クラス。<br />
<br />
Dwarf ではモジュール単位で作業を切り分けるという方針で設計されている。またモジュールを実装することが即ちアプリケーションを実装することになるので、コントローラであろうがモデルであろうがモジュールからは全て同じやり方でフレームワークの情報を参照出来るようになっている。

### プロパティ

#### context

App.pm のインスタンス

#### models

作成したモデルのインスタンスを保持する配列リファレンス

### シンタックスシュガー

	self          (= $self)
	app           (= $self->context)
	c             (= $self->context)
	m             (= $self->model)
	conf          (= $self->context->config->get / $self->context->config->set)
	db            (= $self->context->db)
	error         (= $self->context->error)
	e             (= $self->context->error)
	session       (= $self->context->session)
	param         (= $self->context->param)
	parameters    (= $self->context->request->parameters)
	request       (= $self->context->request)
	req           (= $self->context->request)
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

### メソッド

#### model ($self, $package, @_)

$self->models にインスタンスが存在しなければ create_model を呼んでモデルインスタンスを作成します。

#### create_model ($self, $package, @_)

モデルのインスタンスを作成し、モデルクラスの init メソッドを呼びます。
残りの引数はモデルクラスの new に渡されます。
返り値には作成したインスタンスが返ります。



