package Dwarf::Validator;
use Dwarf::Pragma;
use base 'FormValidator::Lite';

sub check {
    my ($self, @rule_ary) = @_;
	Carp::croak("this is instance method") unless ref $self;
	while (my ($key, $rules) = splice(@rule_ary, 0, 2)) {
		$self->_check($key, $rules);

		# 配列型のキーの処理
		if ($key =~ /^(.+)\[\]$/) {
			my $prefix = $1;
			my @keys = $self->get_keys;

			@keys = grep { $_ =~ /^$prefix/ and $_ !~ /^$prefix\[\]$/ } @keys;
			for my $k (@keys) {
				$self->_check($k, $rules);
			}
		}
	}
	return $self;
}

sub _check {
	my ($self, $key, $rules) = @_;

	my $q = $self->{query};

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
		# Dwarf::Validator 独自機能の ARRAY を実装
		# ARRAY を指定しないと先頭の値以外は破棄する
		my $is_array = 0;
		if (grep { $self->_rule_name($_) eq 'ARRAY' } @$rules) {
			$is_array = 1;
			@$rules = grep { $self->_rule_name($_) ne 'ARRAY' } @$rules;
		}

		# パラメータ
		my @param_rules = grep { !$FormValidator::Lite::FileRules->{ $self->_rule_name($_) } } @$rules;
		if (@param_rules) {
			my @params = $q->param($key);
			if (!$is_array and @params > 0) {
				@params = ($params[0]);
				$self->_set_param($key, $params[0]);
			}
			push @params, undef if @params == 0;
			for my $v (@params) {
				$_ = $v;
				$self->_check_param($key, $rules);
			}
		}

		# ファイル
		my @file_rules = grep { $FormValidator::Lite::FileRules->{ $self->_rule_name($_) } } @$rules;
		if (@file_rules) {
			my @uploads = map {{ upload => $_ }} $q->uploads->get_all($key);
			if (!$is_array and @uploads > 0) {
				@uploads = ($uploads[0]);
				$self->_set_upload($key, $uploads[0]->{upload});
			}
			push @uploads, undef if @uploads == 0;
			for my $v (@uploads) {
				$_ = $v;
				$self->_check_upload($key, $rules);
			}
		}
	}
}

sub _rule_name {
	my ($self, $rule) = @_;
	return ref($rule) ? $rule->[0]	: $rule;
}

sub _rule_args {
	my ($self, $rule) = @_;
	return ref($rule) ? [ @$rule[ 1 .. scalar(@$rule)-1 ] ] : +[];
}

sub get_keys {
	my ($self) = @_;
	my $q = $self->{query};
	my @keys;
	if (ref $q eq 'Dwarf::Request') {
		push @keys, $q->parameters->keys;
		push @keys, $q->uploads->keys;
	} else {
		push @keys, keys %{ $q->Vars };
	}
	wantarray ? @keys : \@keys;
}

sub _set_param {
	my ($self, $key, $val) = @_;
	my $q = $self->{query};
	if (ref $q eq 'Dwarf::Request') {
		$q->parameters->set($key, $val);
	} else {
		$q->param($key => $val);
	}
}

sub _set_upload {
	my ($self, $key, $val) = @_;
	my $q = $self->{query};
	if (ref $q eq 'Dwarf::Request') {
		$q->uploads->set($key, $val);
	} else {
		$q->upload($key => $val);
	}
}

sub _check_param {
	my ($self, $key, $rules) = @_;

	my $q = $self->{query};

	for my $rule (@$rules) {
		my $rule_name = $self->_rule_name($rule);
		my $args      = $self->_rule_args($rule);

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
			} elsif ((not (defined $_ && length $_)) && $rule_name !~ /^(NOT_NULL|NOT_BLANK|REQUIRED)$/) {
				1;
			} else {
				if (ref $rule_name eq 'CODE') {
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

sub _check_upload {
	my ($self, $key, $rules) = @_;

	my $q = $self->{query};

	for my $rule (@$rules) {
		my $rule_name = $self->_rule_name($rule);
		my $args      = $self->_rule_args($rule);

		my $is_ok = do {
			if ((not (defined $_ && length $_)) && $rule_name !~ /^(FILE_NOT_NULL)$/) {
				1;
			} else {
				if (ref $rule_name eq 'CODE') {
					$rule_name->(@$args) ? 1 : 0;
				} else {
					my $file_rule = $FormValidator::Lite::FileRules->{$rule_name} or Carp::croak("unknown rule $rule_name");
					$file_rule->(@$args) ? 1 : 0;
				}
			}
		};

		if ($is_ok == 0) {
			$self->set_error($key => $rule_name);
		}
	}
}

1;
