package Dwarf::Plugin::DBIx::Skinny;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method load_class/;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	my $db_class = $conf->{db_class} || $c->namespace . '::DB';
	my $default_db = $conf->{default_db} || 'master';

	add_method($c, db => sub {
		my ($self, $key) = @_;
		$key ||= $default_db;

		$self->{__db} ||= do {
			my $self = shift;

			load_class($db_class);

			my $connect_info = $self->config->get('db');
			my $repo;

			for my $key (keys %{ $connect_info }) {	
				$repo->{$key} = $db_class->new({
					dsn             => $connect_info->{$key}->{dsn},
					username        => $connect_info->{$key}->{username},
					password        => $connect_info->{$key}->{password},
					connect_options => $connect_info->{$key}->{opts},
				});
				$repo->{$key}->{context} = $c;
			}

			$repo;
		};

		my $db = $self->{__db};
		return $db->{$key} if exists $db->{$key};
		return $db->{$default_db} if exists $db->{$default_db};
		return;
	});

	add_method($c, dbh => sub {
		my $self = shift;
		$self->db->dbh;
	});

	add_method($c, disconnect_db => sub {
		my $self = shift;
		my $db = $self->{__db};
		ref $db eq 'HASH' or return;
		for my $d (values %$db) {
			$d->disconnect if defined $d;
		}
		$self->{__db} = undef;
	});

	$c->add_trigger('AFTER_DISPATCH' => sub {
		my ($self, $res) = @_;
		$self->disconnect_db;
	});
}

1;

# Local Variables:                    #
# tab-width: 4                        #
# cperl-indent-level: 4               #
# cperl-label-offset: -4              #
# cperl-continued-statement-offset: 4 #
# End:                                #
