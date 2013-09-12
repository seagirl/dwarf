use Dwarf::Pragma;
use App;
use Test::More 0.88;

subtest "config" => sub {
	my $c = App->new;
	ok $c->can('config'), 'got config';
	like $c->base_dir, qr|^/.*/app$|, 'have base_dir';
	ok $c->conf('/db/master/dsn'), 'get as Data::Path style';
};

done_testing();
