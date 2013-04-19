package App::Controller::Web::Index;
use Dwarf::Pragma;
use Dwarf::DSL;
use parent 'App::Controller::WebBase';
use Class::Method::Modifiers;

# バリデーションの実装例。validate は何度でも呼べる。
# will_dispatch 終了時にエラーがあれば receive_error が呼び出される。
# after will_dispatch => sub {
#	my ($self, $c) = @_;
#
#	$self->validate(
#		user_id  => [qw/NOT_NULL UINT/, [qw/RANGE 1 8/]],
#		password => [qw/NOT_NULL UINT/, [qw/RANGE 1 8/]],
#	);
# };

# バリデーションがエラーになった時に呼び出される（定義元: Dwarf::Module::HTMLBase）
# エラー表示に使うテンプレートと値を変更したい時はこのメソッドで実装する
# バリデーションのエラー理由は、$self->error_vars->{error}->{PARAM_NAME} にハッシュリファレンスで格納される
# before receive_error => sub {
#	my ($self, $c, $error) = @_;
#	$self->{error_template} = 'index.html';
#	$self->{error_vars} = parameters->as_hashref;
# };

sub get {
	my ($self, $c) = @_;
	return render('index.html');
}

1;
