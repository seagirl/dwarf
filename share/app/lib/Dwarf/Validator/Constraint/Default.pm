package Dwarf::Validator::Constraint::Default;
use Dwarf::Validator::Constraint;
use Email::Valid;
use Email::Valid::Loose;
use JSON;
use Scalar::Util qw/looks_like_number/;

rule NOT_NULL => sub {
	return 0 if not defined($_);
	return 0 if ref $_ eq 'ARRAY' && @$_ == 0;
	return 1;
};
alias NOT_NULL => 'REQUIRED';

rule NOT_BLANK => sub {
	return 0 if not defined($_);
	return 0 if ref $_ eq 'ARRAY' && @$_ == 0;
	$_ ne "";
};

rule INT  => sub { $_ =~ /\A[+\-]?[0-9]+\z/ };
rule UINT => sub { $_ =~ /\A[0-9]+\z/       };

rule NUMBER => sub {
	my $value = $_;
	return 1 unless defined $value;
	return looks_like_number $value;
};

rule EQUAL => sub {
	Carp::croak("missing \$argument") if @_ == 0;
	$_ eq $_[0]
};

rule BETWEEN => sub {
	$_[0] <= $_ && $_ <= $_[1];
};

rule LESS_THAN => sub {
	$_ < $_[0];
};

rule LESS_EQUAL => sub {
	$_ <= $_[0];
};

rule MORE_THAN => sub {
	$_[0] < $_;
};

rule MORE_EQUAL => sub {
	$_[0] <= $_;
};

rule ASCII => sub {
	$_ =~ /^[\x21-\x7E]+$/
};

# 'name' => [qw/LENGTH 5 20/],
rule LENGTH => sub {
	my $length = length($_);
	my $min    = shift;
	my $max    = shift || $min;
	Carp::croak("missing \$min") unless defined($min);

	( $min <= $length and $length <= $max )
};

rule DATE => sub {
	if (ref $_) {
		# query: y=2009&m=09&d=02
		# rule:  {date => [qw/y m d/]} => ['DATE']
		return 0 unless scalar(@{$_}) == 3;
		_date(@{$_});
	} else {
		# query: date=2009-09-02
		# rule:  date => ['DATE']
		_date(split /-/, $_);
	}
};

sub _date {
	my ($y, $m, $d) = @_;

	return 0 if ( !$y or !$m or !$d );

	if ($d > 31 or $d < 1 or $m > 12 or $m < 1 or $y == 0) {
		return 0;
	}
	if ($d > 30 and ($m == 4 or $m == 6 or $m == 9 or $m == 11)) {
		return 0;
	}
	if ($d > 29 and $m == 2) {
		return 0;
	}
	if ($m == 2 and $d > 28 and !($y % 4 == 0 and ($y % 100 != 0 or $y % 400 == 0))){
		return 0;
	}
	return 1;
}

rule TIME => sub {
	if ( ref $_) {
		# query: h=12&m=00&d=60
		# rule:  {time => [qw/h m s/]} => ['TIME']
		_time(@{$_});
	} else {
		# query: time=12:00:30
		# rule:  time => ['time']
		_time(split /:/, $_);
	}
};

sub _time {
	my ($h, $m, $s) = @_;

	return 0 if (!defined($h) or !defined($m));
	return 0 if ("$h" eq "" or "$m" eq "");
	$s ||= 0; # optional

	if ( $h > 23 or $h < 0 or $m > 59 or $m < 0 or $s > 59 or $s < 0 ) {
		return 0;
	}

	return 1;
}

# this regexp is taken from http://www.din.or.jp/~ohzaki/perl.htm#httpURL
# thanks to ohzaki++
rule HTTP_URL => sub {
	$_ =~ /^s?https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+$/
};

rule EMAIL       => sub { Email::Valid->address($_) };
rule EMAIL_LOOSE => sub { Email::Valid::Loose->address($_) };

rule HIRAGANA => sub { delsp($_) =~ /^\p{InHiragana}+$/  };
rule KATAKANA => sub { delsp($_) =~ /^\p{InKatakana}+$/  };
rule JTEL     => sub { $_ =~ /^0\d+\-?\d+\-?\d+$/        };
rule JZIP     => sub { $_ =~ /^\d{3}\-\d{4}$/            };

# {mails => [qw/mail1 mail2/]} => ['DUPLICATION']
rule DUPLICATION => sub {
	defined($_->[0]) && defined($_->[1]) && $_->[0] eq $_->[1]
};
alias DUPLICATION => 'DUP';

rule REGEX => sub {
	my $regex = shift;
	Carp::croak("missing args at REGEX rule") unless defined $regex;
	$_ =~ /$regex/
};
alias REGEX => 'REGEXP';

rule CHOICE => sub {
	Carp::croak("missing \$choices") if @_ == 0;

	my @choices = @_==1 && ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;

	for my $c (@choices) {
		if ($c eq $_) {
			return 1;
		}
	}
	return 0;
};
alias CHOICE => 'IN';

rule NOT_IN => sub {
	my @choices = @_==1 && ref$_[0]eq'ARRAY' ? @{$_[0]} : @_;

	for my $c (@choices) {
		if ($c eq $_) {
			return 0;
		}
	}
	return 1;
};

rule MATCH => sub {
	my $callback = shift;
	Carp::croak("missing \$callback") if ref $callback ne 'CODE';

	$callback->($_);
};

rule JSON => sub {
	my $value = $_;
	return 1 unless defined $value;
	my $data = eval { decode_json $value };
	if ($@) {
		warn $@;
		warn $value;
		return 0;
	}
	return 1;
};

file_rule FILE_NOT_NULL => sub {
	return 0 if not defined($_);
	return 0 if $_ eq "";
	return 0 if ref($_) eq 'ARRAY' && @$_ == 0;
	return 1;
};

file_rule FILE_MIME => sub {
	Carp::croak('missing args. usage: ["FILE_MIME", "text/plain"]') unless @_;
	my $expected = $_[0];
	return $_->type =~ /^$expected$/;
};

file_rule FILE_EXT => sub {
	Carp::croak('missing args. usage: ["FILE_MIME", "text/plain"]') unless @_;
	my $expected = $_[0];
	my $ext = '';
	if ($_->filename =~ /\.(.+)$/) {
		$ext = lc $1;
	}
	return $ext =~ /^$expected$/;
};

# 予約
rule ARRAY => sub { 1 };

rule FILTER => sub {
	my ($filter, $opts) = @_;
	Carp::croak("missing \$filter") unless $filter;

	$opts //= {
		override_param => 0,
	};
	
	if (not ref $filter) {
		$filter = $Dwarf::Validator::Filters->{$filter}
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

filter TRIM => sub {
	my ($value, $opts) = @_;
	return $value unless $value;
	$value =~ s/^\s+|\s+$//g;
	$value;
};

filter DEFAULT => sub {
	my ($value, $opts) = @_;
	$opts->{override_param} = 1;
	unless ($value) {
		$value = $opts->{value};
	}
};

filter DECODE_UTF8 => sub {
	my ($value, $opts) = @_;
	return $value unless $value;
	$value = decode_utf8($value);
	$value;
};

# normalize_line_endings
filter NLE => sub {
	my ($value, $opts) = @_;
	return $value unless $value;
	$value =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	$value;
};

1;