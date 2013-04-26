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

Dwarf は小規模グループ（1〜5人）向けのウェブアプリケーションフレームワークです。<br />
ある程度の作業単位で分業がし易いように設計してあります。

## プロジェクト初期化

	% ./dwarf.pl hello_world

## 起動

	% cd hello_world/app
	% plackup -I lib -r app.psgi
	% open -a Safari http://0:5000/

## プロジェクト構造

	app/
	    lib/      ... プログラム本体
	    script/   ... コマンドラインツール
	    t/        ... テスト
	    tmpl/     ... HTML のテンプレート
	htdocs/       ... ドキュメントルート
	sql/          ... SQL

## ルーティング

デフォルトは下記のルーティング。

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

## コントローラ作成

	% ./script/generate.pl Controller::Web::Login

## モデル作成

	% ./script/generate.pl Model::Auth

## アプリケーションクラス

App.pm (Dwarf.pm) = アプリケーションクラス + コンテキストクラス + ディスパッチャクラス

### プロパティ

	ro => [qw/namespace base_dir env config error request response router handler handler_class state/],
	rw => [qw/stash request_handler_prefix request_handler_method/],

### シンタックスシュガー

	param
	conf
	method
	req
	res
	status
	type
	body

### メソッド

	is_production
	is_cli
	to_psgi
	finish
	redirect
	not_found
	add_routes
	load_plugins

## モジュール

Dwarf::Module はコントローラやモデルの根底クラス。<br />
Dwarf ではコントローラとモデルは基本的な機能は同じもの。

### プロパティ

	context

### シンタックスシュガー

	self
	app
	c
	m
	conf
	db
	error
	e
	session
	param
	parameters
	request
	req
	response
	res
	status
	type
	body
	not_found
	finish
	redirect
	is_cli
	is_production
	load_plugin
	load_plugins
	render

use Dwarf::DSL することで上記のシンタックスシュガーを DSL として呼ぶことができます。

### メソッド

	model
	create_model


