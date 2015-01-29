use App::Test;

my $t = App::Test->new;
my $c = $t->context;
my $m = $t->context->model('Hash');

my $id = 12345678;
my $expected = '9cb1e651f330a3ddcffdb796415c84ce01b8eae05d6f61a3b69a924d2451ded9';

subtest "create" => sub {
	is $m->create($id), $expected, 'work create method';
};

done_testing;
