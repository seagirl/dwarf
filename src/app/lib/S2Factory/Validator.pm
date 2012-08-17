#
# Copyright (c) 2011  S2 Factory, Inc.  All rights reserved.
#
# $Id: Validator.pm 4050 2012-02-24 20:07:29Z yoshizu $
#
package S2Factory::Validator;
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

			for $v (@p) {
				$_ = $v;
				$self->_check($key, $rules);
			}
		}
	}

	return $self;
}

sub _check {
	my ($self, $key, $rules) = @_;

	my $q = $self->{query};
	for my $rule (@$rules) {
		my $rule_name = ref($rule) ? $rule->[0]	: $rule;
		my $args      = ref($rule) ? [ @$rule[ 1 .. scalar(@$rule)-1 ] ] : +[];

		if ($FormValidator::Lite::FileRules->{$rule_name}) {
			$_ = FormValidator::Lite::Upload->new($q, $key);
		}

		my $is_ok = do {
			if ((not (defined $_ && length $_)) && $rule_name !~ /^(NOT_NULL|NOT_BLANK|REQUIRED)$/) {
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

# Local Variables:                    #
# tab-width: 4                        #
# cperl-indent-level: 4               #
# cperl-label-offset: -4              #
# cperl-continued-statement-offset: 4 #
# End:                                #
