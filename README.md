dwarf
=====

Web Application Framework (Perl5)

## プロジェクト作成

<pre>
% ./dwarf.pl hello_world
</pre>

## 起動

<pre>
% cd hello_world/app
% plackup -I lib -r app.psgi
% open -a Safari http://0:5000/
</pre>

## プロジェクト構造

<pre>
app/
    lib/      ... プログラム本体
    script/   ... コマンドラインツール
    t/        ... テスト
    tmpl/     ... HTML のテンプレート
htdocs/       ... ドキュメントルート
sql/          ... SQL
</pre>


## コントローラ作成

<pre>
% ./script/generate.pl Controller::Web::Login
</pre>

## モデル作成

<pre>
% ./script/generate.pl Model::Auth
</pre>

## アプリケーションクラス (Dwarf)

App (Dwarf) = アプリケーションクラス + コンテキストクラス + ディスパッチャクラス

## モジュール (Dwarf::Module)

コントローラやモデルの根底クラス。<br />
Dwarf ではコントローラとモデルは基本的な機能は同じもの。