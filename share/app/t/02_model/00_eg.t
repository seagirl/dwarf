use App::Test;

my $t = App::Test->new;

# モデルの生成は下記で行える
# my $m = $t->context->create_module('Model::Something');

subtest "test something" => sub {
	ok 1;
};

done_testing;