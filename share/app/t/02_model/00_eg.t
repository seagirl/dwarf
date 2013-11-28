use App::Test;

App::Test->new(sub {
	my ($c, $cb) = @_;

	# モデルの生成は下記で行える
	#my $m = $c->create_module('Model::Hoge');

	subtest "test something" => sub {
		ok 1;
	};
})->run;

