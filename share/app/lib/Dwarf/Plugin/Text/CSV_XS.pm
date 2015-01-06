package Dwarf::Plugin::Text::CSV_XS;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method encode_utf8/;
use Text::CSV_XS;
use Unicode::Normalize;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	add_method($c, read_csv => sub {
		my ($self, $filepath) = @_;
		my $csv = Text::CSV_XS->new ({ binary => 1 });

		open my $fh, "<:encoding(utf8)", $filepath or die "Couldn't open $filepath: $!";

		my @rows;
		while (my $row = $csv->getline($fh)) {
			$row->[2] =~ m/pattern/ or next; # 3rd field should match
			push @rows, $row;
		}
		$csv->eof or $csv->error_diag();
		close $fh;

		$csv->eol ("\r\n");

		return wantarray ? @rows : \@rows;
	});

	add_method($c, decode_csv => sub {
		my ($self, $str) = @_;
		my $csv = Text::CSV_XS->new ({ binary => 1 });

		my @rows = split(/(?:\r\n|\r|\n)/, $str);
		for my $row (@rows) {
			if ($csv->parse($row)) {
				$row = [ $csv->fields ];
			}
		}

		return wantarray ? @rows : \@rows;
	});

	add_method($c, encode_csv => sub {
		my ($self, @rows) = @_;
		my $csv = Text::CSV_XS->new ({ binary => 1, eol => "\r\n", always_quote => 1 });

		my $content = '';
		for my $row (@rows) {
			if ($csv->combine(@$row)) {
				$content .= $csv->string;
			}
		}

		$content = NFKC($content);
		$content = encode_utf8($content);
		return $content;
	});

	$c->add_trigger(AFTER_DISPATCH => sub {
		my ($self, $res) = @_;
		return unless ref $res->body eq 'ARRAY';

		if ($res->content_type =~ /text\/csv/) {
			$self->call_trigger(BEFORE_RENDER => $self->handler, $self, $res->body);
			my $encoded = $self->encode_csv($res->body);
			$self->call_trigger(AFTER_RENDER => $self->handler, $self, \$encoded);
			$res->body(encode_utf8($encoded));
		}
	});
}

1;
