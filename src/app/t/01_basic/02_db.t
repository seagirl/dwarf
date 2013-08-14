use Dwarf::Pragma;
use Data::Dumper;
use Test::More 0.88;
use App;

my $c = App->new;

do {
	my $txn = $c->db->txn_scope;
	my $itr = $c->db->search_by_sql('select count(*) from sessions');
	ok $itr->next->count >= 0, '(select count(*) from sessions) >= 0';
	$txn->commit;
};

done_testing();

