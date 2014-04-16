package Dwarf::Validator;
use Dwarf::Pragma;
use base 'FormValidator::Lite';

sub check {
    my ($self, @rule_ary) = @_;
	Carp::croak("this is instance method") unless ref $self;

	my $q = $self->{query};
	while (my ($key, $rules) = splice(@rule_ary, 0, 2)) {
		local $_;

		# { date => [qw/y m d/] } => ['DATE']
		if (ref $key) {
			$key = [%$key];
			$_ = [ map { $q->param($_) } @{ $key->[1] } ];
			$key = $key->[0];
			$self->_check($key, $rules);
		}
		# hoge => [qw/INT/]
		else {
			my @p = $q->param($key);
			push @p, undef if @p == 0;

			# Dwarf::Validator 独自機能の ARRAY を実装
			# ARRAY を指定しないと先頭の値以外は破棄する
			if (my @a = grep { $self->_rule_name($_) ne 'ARRAY' } @$rules) {
				$self->_set_param($key, $p[0]);
				@p = ($p[0]);
				@$rules = @a;
			}

			for my $v (@p) {
				$_ = $v;
				$self->_check($key, $rules);
			}
		}
	}

	return $self;
}

sub _rule_name {
	my ($self, $rule) = @_;
	return ref($rule) ? $rule->[0]	: $rule;
}

sub _rule_args {
	my ($self, $rule) = @_;
	return ref($rule) ? [ @$rule[ 1 .. scalar(@$rule)-1 ] ] : +[];
}

sub _set_param {
	my ($self, $key, $val) = @_;
	my $q = $self->{query};
	if (ref $q eq 'Plack::Request') {
		$q->parameters->set($key, $val);
	} else {
		$q->param($key => $val);
	}
}

sub _check {
	my ($self, $key, $rules) = @_;

	my $q = $self->{query};

	for my $rule (@$rules) {
		my $rule_name = $self->_rule_name($rule);
		my $args      = $self->_rule_args($rule);

		if ($FormValidator::Lite::FileRules->{$rule_name}) {
			$_ = FormValidator::Lite::Upload->new($q, $key);
		}

		my $is_ok = do {
			# FILTER
			if ($rule_name =~ /^(FILTER|DEFAULT|DECODE_UTF8|TRIM|NLE|)$/) {
				my $code = $FormValidator::Lite::Rules->{$rule_name} or Carp::croak("unknown rule $rule_name");
				my $value = $code->(@$args);
				# FILTER が何か値を返す場合は元の値を上書きする
				if (defined $value) {
					$self->_set_param($key, $value);
				}
				1;
			} elsif ((not (defined $_ && length $_)) && $rule_name !~ /^(NOT_NULL|NOT_BLANK|REQUIRED|FILE_NOT_NULL)$/) {
				1;
			} else {
				if (my $file_rule = $FormValidator::Lite::FileRules->{$rule_name}) {
					$file_rule->(@$args) ? 1 : 0;
				} elsif (ref $rule_name eq 'CODE') {
					$rule_name->(@$args) ? 1 : 0;
				} else {
					my $code = $FormValidator::Lite::Rules->{$rule_name} or Carp::croak("unknown rule $rule_name");
					$code->(@$args) ? 1 : 0;
				}
			}
		};

		if ($is_ok == 0) {
			$self->set_error($key => $rule_name);
		}
	}
}

1;
