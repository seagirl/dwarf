package App::Controller::Cli::LoadSchema;
use Dwarf::Pragma;
use parent 'App::Controller::CliBase';
use Dwarf::DSL;
use DBI;
use App::DB::Schema::Dumper;

sub any {
	my $connect_info = conf('db');
	my $dbh = DBI->connect(
		$connect_info->{master}->{dsn},
		$connect_info->{master}->{username},
		$connect_info->{master}->{password},
		$connect_info->{master}->{opts},
	) or die;

	print App::DB::Schema::Dumper->dump(
		dbh       => $dbh,
		namespace => c->namespace . '::DB',
#		dt_rules  => qr/_at$/,
	);

	return;
}

1;

