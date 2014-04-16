package Dwarf::Validator::Filter;
use Dwarf::Pragma;
use Encode;
use FormValidator::Lite::Constraint;
use FormValidator::Lite::Constraint::Default;

our $Filters = {};

my $F = sub {
	my ($filter, $opts) = @_;
	Carp::croak("missing \$filter") unless $filter;

	$opts //= {
		override_param => 0,
	};
	
	if (not ref $filter) {
		$filter = $Filters->{$filter}
			or Carp::croak("$filter is not defined.");
	}
	
	Carp::croak("\$filter must be coderef.") if ref $filter ne 'CODE';
	
	$_ = $filter->($_, $opts);

	# パラメータを上書きしない場合は undef を返す
	unless ($opts->{override_param}) {
		return;
	}

	$_;
};

$Filters->{'trim'} = sub {
	my ($value, $opts) = @_;
	return $value unless $value;
	$value =~ s/^\s+|\s+$//g;
	$value;
};

$Filters->{'default'} = sub {
	my ($value, $opts) = @_;
	$opts->{override_param} = 1;
	unless ($value) {
		$value = $opts->{value};
	}
};

$Filters->{'decode_utf8'} = sub {
	my ($value, $opts) = @_;
	return $value unless $value;
	$value = decode_utf8($value);
	$value;
};

$Filters->{'normalize_line_endings'} = sub {
	my ($value, $opts) = @_;
	return $value unless $value;
	$value =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	$value;
};

rule 'FILTER' => $F;

rule 'TRIM' => sub {
	my ($opts) = @_;
	return $F->('trim', $opts);
};

rule 'DEFAULT' => sub {
	my ($v, $opts) = @_;
	$opts->{value} = $v;
	return $F->('default', $opts);
};

rule 'DECODE_UTF8' => sub {
	my ($opts) = @_;
	return $F->('decode_utf8', $opts);
};

rule 'NLE' => sub {
	my ($opts) = @_;
	return $F->('normalize_line_endings', $opts);
};
